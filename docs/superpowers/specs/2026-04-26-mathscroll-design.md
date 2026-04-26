# MathScroll — design spec

**Date:** 2026-04-26
**Status:** Approved (brainstorm)
**Source app:** Forked from `GoalScroll1` (iOS, Swift, SwiftData, Supabase, Family Controls).
**Target platforms:** iOS 26+ (Liquid Glass design language).

## 1. Product summary

MathScroll repurposes GoalScroll's "complete a habit → earn unlocked minutes" loop for GCSE / AS / A-Level Maths revision. The student is shown a real past-paper exam question, writes their working on paper, photographs it, and gets it marked by Gemini Vision against the official mark scheme. Marks earned convert 1:1 into minutes that unlock a user-chosen set of apps via Apple's Family Controls / Screen Time API, capped daily. The app simultaneously builds a per-skill weakness profile and recommends the next question to target the student's gaps.

The product is paywalled: one free question per device, then a subscription.

## 2. Core loop

1. Student opens the app — Home shows the next recommended question (image of a real past-paper question).
2. Student writes working on paper, taps **Submit**, takes a photo of the working including the final answer.
3. Photo + question + official mark scheme go to `MarkingService` (single Gemini Vision call).
4. Gemini returns strict JSON: marks awarded (per-criterion breakdown), per-criterion rationale, list of skill tags right/wrong, and one short improvement tip.
5. Result screen shows the breakdown. Earned minutes animate into the balance pill (capped daily).
6. Attempt + tag deltas persist locally (SwiftData) and mirror to Supabase. The weakness model recomputes.

## 3. Question source & question bank

The iOS app reads from a Supabase `questions` table populated by a **separate ingestion pipeline** (PDFs from Edexcel / AQA / OCR → OCR → split → tag → upload). That pipeline is its own spec; this v1 app spec assumes:
- The bank exists.
- A development seed of ~50 questions covers all three levels and all three boards.

Each `questions` row stores:
- `id`, `board` (edexcel|aqa|ocr), `level` (gcse|as|alevel), `tier` (foundation|higher; gcse only)
- `paper_year`, `paper_code`, `question_number`
- `question_image_url`, `mark_scheme_image_url`, `total_marks`
- `subtopic_tags[]`, `skill_tags[]`, `difficulty` (1–5)

Question content is **not** persisted in SwiftData. It's fetched from Supabase and cached as files on disk to keep device storage small.

## 4. Data model (on-device, SwiftData)

Replaces `Goal` / `CompletionRecord` / `ProofItem`.

**`QuestionAttempt`** (`@Model`)
- `id: UUID`
- `questionId: String` (Supabase ref)
- `submittedAt: Date`
- `imageData: Data` (working photo, JPEG)
- `marksAwarded: Int`, `totalMarks: Int`
- `criterionResults: Data` (JSON: `[{criterionId, awarded, max, rationale}]`)
- `skillsCorrect: [String]`, `skillsIncorrect: [String]`
- `improvementTip: String`
- `secondsSpent: Int`
- `markingMode: MarkingMode` (ai|selfMark)

**`SkillStat`** (`@Model`)
- `tag: String` (unique per kind)
- `kind: SkillStatKind` (subtopic|skill)
- `attemptsCount: Int`
- `marksScored: Int`, `marksPossible: Int`
- `recencyWeightedPct: Double`
- `lastAttemptedAt: Date`
- Recomputed after each attempt.

**`MinutesLedger`** (`@Model`, append-only)
- `entryId: UUID`, `date: Date`, `deltaMinutes: Int`, `source: LedgerSource` (earned|spent|dailyCapAdjustment|manualAdjustment)
- Balance is `sum(deltaMinutes)`. Daily-cap adjustments are written when a day's earnings are clamped.

**`UserProfile`** (`@Model`, single row)
- `level: ExamLevel` (gcse|as|alevel)
- `board: ExamBoard` (edexcel|aqa|ocr) — single, not multi
- `tier: Tier?` (foundation|higher; nil for AS/A-Level)
- `dailyCapMinutes: Int` (default 120)
- `blockedAppTokens: Data` (Family Controls `FamilyActivitySelection` encoded)
- `entitlement: Entitlement?` (productId, expiresAt, isActive)
- `onboardingDone: Bool`
- `paywallSeen: Bool`
- `freeQuestionUsed: Bool`

## 5. Stores

Mirrors GoalScroll1's `@Observable` pattern (selectively port the cleaner GoalScroll2 patterns called out in `IMPLEMENTATION_COMPARISON.md`).

- **`QuestionBankStore`** — fetches/caches questions from Supabase, applies the recommendation algorithm, exposes `nextQuestion()`.
- **`SessionStore`** — manages the currently-active question lifecycle (loaded → photographed → submitted → marked → completed).
- **`MarkingStore`** (renames `VerificationStore`) — orchestrates the Gemini marking call, surfaces loading/error/result states.
- **`StatsStore`** — recomputes `SkillStat` from attempts; exposes weakness rankings for the Stats screen.
- **`MinutesStore`** — ledger-backed balance, daily-cap enforcement, integration with `ScreenTimeManager`.
- **`PaywallStore`** + **`EntitlementsService`** — wraps StoreKit 2; gating check on every `nextQuestion()` call beyond the first.
- **`AppState`** — onboarding flag, paywall flag, active sheet routing.

## 6. Marking pipeline (`MarkingService`)

Single Gemini Vision call. Inputs:
- Question image (URL or local cache file).
- Mark scheme image (URL or local cache file).
- Student's working photo.
- Structured prompt requesting strict JSON output.

Output schema (validated client-side):
```json
{
  "totalAwarded": 4,
  "totalPossible": 6,
  "criteria": [
    {"criterionId":"M1","awarded":1,"max":1,"rationale":"Correct substitution shown."},
    {"criterionId":"A1","awarded":0,"max":1,"rationale":"Final answer not simplified."}
  ],
  "skillsCorrect": ["substitute_into_quadratic"],
  "skillsIncorrect": ["simplify_surd"],
  "improvementTip": "Always rationalise the denominator in the last step."
}
```

On schema validation failure: retry once with a stricter "respond ONLY with JSON matching this schema" reminder. On second failure, surface a fallback UI offering **self-mark** (student awards full or zero per criterion). Self-marked attempts are flagged `markingMode = .selfMark` so analytics can separate AI-marked from self-marked data.

## 7. Recommendation algorithm

`QuestionBankStore.nextQuestion()` picks one question id with these weights:
- **60%** from skills where `recencyWeightedPct < 60%` and `attemptsCount >= 2` (currently weak).
- **30%** from skills the student has been improving on (spaced review).
- **10%** from skills not yet attempted (coverage).

Constraints applied as filters before weighting:
- Match user's `board`, `level`, and `tier`.
- Exclude any `questionId` attempted in the last 30 days.
- After 5 questions in a row that draw from the same subtopic, force the next pick from a different subtopic to prevent burnout.

The first post-paywall question (and the single free pre-paywall question) is drawn from the "coverage" bucket so the student gets a representative taste.

## 8. Improvement advice

Two layers, both Gemini-driven:

1. **Per-question tip** — one sentence returned by the marker (already in the JSON schema above). Surfaced on the Result screen. Hidden when the student scored full marks (Gemini is asked to return an empty string in that case).
2. **Weekly digest** — Sunday evening local push notification + an in-app screen: "Top 3 weakest skills this week + one suggested practice question for each." A second Gemini call summarises the week's attempts.

## 9. Onboarding (paywall funnel)

Pre-paywall (free, anonymous):

1. **Pick level** — GCSE / AS Level / A-Level (single).
2. **Pick board** — Edexcel / AQA / OCR (single).
3. **Tier** — Foundation / Higher (GCSE only).
4. **Answer 1 free question** — full flow: photo capture → Gemini marking → marks breakdown → minutes balance animates from 0 → N.
5. **Paywall** — "Keep your streak. Unlock unlimited questions and app blocking."

Post-paywall (after a successful purchase callback) first-run setup. These screens are mandatory before the user can request a second question; they cannot be dismissed without completion (the diagnostic itself is skippable inside the flow):

6. Set **daily cap** (slider, default 120 min).
7. Pick **apps to block** (Family Controls picker).
8. **Diagnostic** — 5 quick questions across mixed topics to seed the weakness model (skippable with a "Skip diagnostic" link).
9. **Done** — drops into Home.

Free-tier daily cap and blocked-apps state are unset; the free question's earned minutes are simply displayed without unlocking anything (it's a demo of the loop).

## 10. UI surfaces & visual language (iOS 26 Liquid Glass)

Drop the existing `GradientBackgroundView`. Use the system Liquid Glass material (`.glassEffect()`, `GlassEffectContainer`) on cards, sheets, the question card, the result panel, and the bottom tab bar.

- **Home** — current question card (rendered in glass), big "Submit answer" CTA, minutes balance as a pinned glass capsule top-trailing with a smooth count-up animation.
- **Submit** — camera capture (existing `CameraView`), preview, confirm.
- **Result** — layered glass: question thumbnail behind, marks/total big number, per-criterion breakdown list, improvement tip, "Next question" CTA.
- **Stats** — weakness ranking at subtopic level, accuracy over time chart, attempts streak.
- **Unlock** — current balance, blocked apps list, "Unlock for X minutes" button (existing `UnlockTimerView`, mostly unchanged but reskinned).
- **Settings** — daily cap, board / level switching, blocked apps picker, manage subscription, restore purchases.
- **Floating, translucent tab bar** — Home / Stats / Unlock / Settings.
- **Typography:** SF Pro / SF Rounded for numerics; ample whitespace; no heavy shadows or gradients.
- **Iconography:** SF Symbols 6 with `.hierarchical` rendering.
- **Deployment target:** bumped from iOS 17+ to iOS 26+ (Liquid Glass requirement).

## 11. Supabase backend

- **New tables:** `questions`, `attempts` (server mirror for cross-device sync), `skill_stats` (server mirror).
- **Reuse existing:** auth, sync framework, edge functions infrastructure.
- **New function (later, not v1):** `recommend-question` if recommendation logic ever needs server-side ranking. v1 keeps recommendation client-side.
- Mirror behaviour matches GoalScroll1's `SyncManager`.

## 12. Monetization & paywall

- One free question per app install. Tracked locally via `UserProfile.freeQuestionUsed` (single SwiftData row). Reinstalling resets the flag — acceptable for v1; tighter gating (e.g. server-side device fingerprint) is deferred.
- Paywall triggers when `freeQuestionUsed = true` and `entitlement` is nil/inactive.
- Subscriptions via **StoreKit 2**:
  - Weekly: **£4.99**
  - Monthly: **£19.99** (with 7-day free trial)
  - Annual: **£79.99**
- Prices are placeholders; tunable via App Store Connect without code changes.
- `EntitlementsService` exposes `currentEntitlement` and a `refresh()` call after purchase / restore.
- **Restore Purchases** in Settings.
- Family Sharing is **not supported in v1**.

## 13. Out of scope for v1

- The PDF ingestion pipeline (separate spec / sub-project).
- Subjects beyond Maths.
- Multi-user features, leaderboards, social.
- Web companion.
- Offline marking (requires connectivity to Gemini).
- Family-shared subscriptions.
- Free-tier history beyond the single free question.

## 14. Testing

- **Unit:**
  - `MarkingService` parses & validates Gemini JSON; handles malformed responses with retry + self-mark fallback.
  - `QuestionBankStore.nextQuestion()` weight distribution on synthetic stat sets.
  - `MinutesStore` daily-cap enforcement.
  - `StatsStore` recency-weighted percentage calculation.
- **Integration:**
  - Full attempt → mark → stats update → next-question selection.
  - Paywall gate: free question consumes the slot, second `nextQuestion()` returns paywall state.
- **Manual fixture set:** 10 questions + photos covering all-correct, partial-credit, all-wrong, and illegible-handwriting cases.

## 15. Migration / fork strategy

This is a fresh fork, not an in-place rewrite of GoalScroll1. Steps (high level — detail in the implementation plan):

1. Copy `GoalScroll1/` to `MathScroll/`.
2. Rename Xcode project, bundle identifier, app name, scheme, asset catalog entries.
3. Bump deployment target to iOS 26.
4. Delete: `Goal.swift`, `CompletionRecord.swift`, `ProofItem.swift`, `OnboardingGoalDraft.swift`, `GoalsStore.swift`, the goal-creation onboarding screens, `ProofCaptureView`.
5. Add new models, stores, services per §4–§6.
6. Reskin all retained views to Liquid Glass.
7. Wire StoreKit 2 + paywall.
8. Set up Supabase schema for `questions`, `attempts`, `skill_stats`.

## 16. Open dependencies

- Question bank ingestion pipeline (separate spec — must produce the seed bank before MathScroll v1 can ship to TestFlight).
- Apple Family Controls entitlement. **The entitlement is bound to the bundle id**, so the renamed MathScroll bundle id will need a fresh entitlement application to Apple. This can take weeks — file the application as soon as the new bundle id is decided. Until granted, the app must fall back to soft-blocking (timer-only, no real Screen Time enforcement) so TestFlight builds still work.
- Gemini API key + plan with sufficient quota for vision marking calls.
- Apple Developer account paywall config (StoreKit products in App Store Connect).
