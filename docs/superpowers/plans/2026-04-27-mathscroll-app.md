# MathScroll App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork GoalScroll1 into MathScroll — a GCSE/AS/A-Level Maths revision iOS app that marks photographed working with Gemini Vision and converts marks into Family-Controls-blocked app minutes, paywalled after one free question.

**Architecture:** SwiftUI + SwiftData + Supabase backend (auth, edge functions, sync) + Gemini Vision via a `mark-question` edge function (keeps API key server-side). New `@Observable` stores replace the goal-domain stores. iOS 26 Liquid Glass throughout. StoreKit 2 for subscriptions.

**Tech Stack:** Swift 5.10, SwiftUI (iOS 26+), SwiftData, Supabase Swift SDK, StoreKit 2, FamilyControls / DeviceActivity / ManagedSettings, Gemini 2.x Vision via Supabase Edge Functions, XCTest.

**Reference spec:** `MathScroll/docs/superpowers/specs/2026-04-26-mathscroll-design.md`

---

## File structure

```
MathScroll/
├── MathScroll.xcodeproj/                 # renamed from GoalScroll.xcodeproj
├── MathScroll/
│   ├── MathScrollApp.swift               # entry point (renamed)
│   ├── ContentView.swift                 # root router (kept; behaviour rewritten)
│   ├── Models/
│   │   ├── Enums.swift                   # NEW — ExamLevel, ExamBoard, Tier, MarkingMode, LedgerSource, SkillStatKind
│   │   ├── UserProfile.swift             # NEW
│   │   ├── QuestionAttempt.swift         # NEW
│   │   ├── SkillStat.swift               # NEW
│   │   ├── MinutesLedger.swift           # NEW
│   │   ├── Question.swift                # NEW — non-persisted DTO from Supabase
│   │   ├── MarkingResult.swift           # NEW — Gemini response DTO
│   │   ├── Entitlement.swift             # NEW
│   │   └── ActiveSheet.swift             # KEEP, rename cases
│   ├── Stores/
│   │   ├── AppState.swift                # MODIFY — onboarding/paywall flags, sheet routing
│   │   ├── QuestionBankStore.swift       # NEW
│   │   ├── SessionStore.swift            # NEW
│   │   ├── MarkingStore.swift            # NEW (replaces VerificationStore.swift)
│   │   ├── StatsStore.swift              # MODIFY heavily (replaces UserStats logic)
│   │   ├── MinutesStore.swift            # NEW
│   │   ├── PaywallStore.swift            # NEW
│   │   └── EntitlementsService.swift     # NEW
│   ├── Services/
│   │   ├── MarkingService.swift          # NEW (Gemini Vision via edge function)
│   │   ├── QuestionBankService.swift     # NEW (Supabase fetch)
│   │   ├── WeeklyDigestService.swift     # NEW
│   │   ├── ScreenTimeManager.swift       # KEEP (works as-is)
│   │   ├── NotificationManager.swift     # MODIFY (add weekly digest schedule)
│   │   ├── SupabaseManager.swift         # KEEP
│   │   ├── SyncManager.swift             # MODIFY (sync attempts + skill_stats)
│   │   └── AnalyticsService.swift        # KEEP
│   ├── Views/
│   │   ├── RootView.swift                # MODIFY (route to onboarding / paywall / main)
│   │   ├── Components/
│   │   │   ├── GlassCard.swift           # NEW
│   │   │   ├── GlassCapsule.swift        # NEW
│   │   │   ├── PrimaryButton.swift       # MODIFY (Liquid Glass)
│   │   │   ├── InputField.swift          # MODIFY (Liquid Glass)
│   │   │   ├── MinutesBalancePill.swift  # NEW
│   │   │   └── (delete) GradientBackgroundView.swift
│   │   ├── Onboarding/
│   │   │   ├── OnboardingContainerView.swift  # MODIFY — new step list
│   │   │   ├── PickLevelView.swift       # NEW
│   │   │   ├── PickBoardView.swift       # NEW
│   │   │   ├── PickTierView.swift        # NEW
│   │   │   ├── DailyCapView.swift        # NEW
│   │   │   ├── PickAppsView.swift        # NEW
│   │   │   ├── DiagnosticView.swift      # NEW
│   │   │   └── (delete) old goal-domain onboarding views
│   │   ├── Home/
│   │   │   ├── HomeView.swift            # REWRITE
│   │   │   ├── SubmitAnswerView.swift    # NEW (camera + confirm)
│   │   │   ├── ResultView.swift          # NEW
│   │   │   ├── UnlockTimerView.swift     # MODIFY (reskin)
│   │   │   └── MainTabView.swift         # NEW (floating glass tab bar)
│   │   ├── Stats/
│   │   │   └── StatsView.swift           # NEW
│   │   ├── Paywall/
│   │   │   └── PaywallView.swift         # NEW
│   │   ├── Settings/
│   │   │   └── SettingsView.swift        # MODIFY heavily
│   │   ├── Capture/
│   │   │   └── CameraView.swift          # KEEP (renamed from Proof/CameraView.swift)
│   │   └── (delete) Views/Proof, Views/Review (goal-domain)
│   └── Utilities/
│       ├── Theme.swift                   # MODIFY (Liquid Glass tokens)
│       ├── Extensions.swift              # KEEP
│       └── Constants.swift               # MODIFY (new validation rules)
├── supabase/
│   ├── migrations/
│   │   └── 20260427000000_mathscroll_schema.sql   # NEW
│   └── functions/
│       └── mark-question/                # NEW edge function
│           └── index.ts
├── docs/
│   └── superpowers/
│       ├── specs/2026-04-26-mathscroll-design.md  # already committed
│       └── plans/2026-04-27-mathscroll-app.md     # this file
└── MathScrollTests/                      # renamed from GoalScrollTests
```

---

## Phase 1 — Foundation

### Task 1: Create the MathScroll directory as a fresh fork of GoalScroll1

**Files:**
- Create: `MathScroll/` (full copy of `GoalScroll1/` excluding build artefacts)

- [ ] **Step 1: Copy GoalScroll1 → MathScroll, excluding build outputs and IDE state**

```bash
cd "C:/Users/quham.adefila"
# Copy everything except build/Xcode user state and node modules.
robocopy GoalScroll1 MathScroll /MIR /XD .build DerivedData xcuserdata node_modules
```

- [ ] **Step 2: Verify the copy**

```bash
ls MathScroll/GoalScroll/
# Expect: GoalScrollApp.swift, ContentView.swift, Models/, Views/, etc.
```

- [ ] **Step 3: Commit the raw fork as a baseline before any rename work**

```bash
cd MathScroll
git init
git add .
git commit -m "fork: initial copy of GoalScroll1"
```

---

### Task 2: Rename Xcode project, scheme, bundle id, and app name to MathScroll

**Files:**
- Rename: `MathScroll/GoalScroll.xcodeproj` → `MathScroll/MathScroll.xcodeproj`
- Rename: `MathScroll/GoalScroll/` → `MathScroll/MathScroll/`
- Rename: `MathScroll/GoalScroll/GoalScrollApp.swift` → `MathScroll/MathScroll/MathScrollApp.swift`
- Rename: `MathScroll/GoalScrollMonitor/` and `MathScroll/GoalScrollShield/` → `MathScrollMonitor/`, `MathScrollShield/`
- Modify: `project.pbxproj` (bundle ids, target names, scheme)
- Modify: `Info.plist` `CFBundleDisplayName` → "MathScroll"

- [ ] **Step 1: Rename the project, source group, and extensions on disk**

```bash
cd MathScroll
mv GoalScroll.xcodeproj MathScroll.xcodeproj
mv GoalScroll MathScroll
mv MathScroll/GoalScrollApp.swift MathScroll/MathScrollApp.swift
mv GoalScrollMonitor MathScrollMonitor
mv GoalScrollShield MathScrollShield
```

- [ ] **Step 2: Replace identifier strings inside project files**

```bash
# pbxproj and entitlements live as plain text — safe to sed.
grep -rl "GoalScroll" MathScroll.xcodeproj MathScroll MathScrollMonitor MathScrollShield | \
  xargs sed -i 's/GoalScroll/MathScroll/g'

# Bundle id: choose com.<yourteam>.mathscroll for the main app, .monitor / .shield for extensions.
sed -i 's/com\.[a-z0-9.]*\.goalscroll/com.<team>.mathscroll/g' \
  MathScroll.xcodeproj/project.pbxproj
```

Replace `<team>` with your Apple Developer team's reverse-DNS prefix.

- [ ] **Step 3: Open the project in Xcode and verify all targets build (Cmd+B)**

Expected: builds clean. If file references show red, drag the renamed `MathScroll/` group back into the project navigator.

- [ ] **Step 4: Bump the iOS deployment target to 26 across all targets**

In `MathScroll.xcodeproj/project.pbxproj` (or via Xcode → Project → Build Settings):
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0` for `MathScroll`, `MathScrollMonitor`, `MathScrollShield`.

- [ ] **Step 5: Update display name in `Info.plist`**

```xml
<key>CFBundleDisplayName</key>
<string>MathScroll</string>
```

- [ ] **Step 6: Apply for Family Controls entitlement against the new bundle id**

This is a manual step in App Store Connect / Apple Developer portal. Note in the project README that the entitlement is *pending* until granted, and that until then the app falls back to soft-blocking (Task 17).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: rename project to MathScroll, bump deployment target to iOS 26"
```

---

### Task 3: Delete legacy goal-domain code paths

**Files:**
- Delete: `MathScroll/Models/Goal.swift`
- Delete: `MathScroll/Models/CompletionRecord.swift`
- Delete: `MathScroll/Models/ProofItem.swift`
- Delete: `MathScroll/Models/OnboardingGoalDraft.swift`
- Delete: `MathScroll/Stores/GoalsStore.swift`
- Delete: `MathScroll/Stores/VerificationStore.swift` (will be reborn as `MarkingStore.swift`)
- Delete: `MathScroll/Views/Onboarding/EnterGoalView.swift`, `DefineMicrohabitView.swift`, `ChooseTriggerView.swift`, `ProofSelectionView.swift`, `WhyImportanceView.swift`, `SummaryView.swift`
- Delete: `MathScroll/Views/Proof/`, `MathScroll/Views/Review/`, `MathScroll/Views/Home/AddGoalView.swift`
- Modify: `MathScroll/Views/Components/GradientBackgroundView.swift` — delete the file
- Modify: `MathScroll/MathScrollApp.swift` and `ContentView.swift` to drop references to deleted types (will compile-fail temporarily; subsequent tasks restore correctness)

- [ ] **Step 1: Delete the files**

```bash
cd MathScroll
rm MathScroll/Models/Goal.swift \
   MathScroll/Models/CompletionRecord.swift \
   MathScroll/Models/ProofItem.swift \
   MathScroll/Models/OnboardingGoalDraft.swift \
   MathScroll/Stores/GoalsStore.swift \
   MathScroll/Stores/VerificationStore.swift \
   MathScroll/Views/Components/GradientBackgroundView.swift
rm -r MathScroll/Views/Proof MathScroll/Views/Review
rm MathScroll/Views/Onboarding/EnterGoalView.swift \
   MathScroll/Views/Onboarding/DefineMicrohabitView.swift \
   MathScroll/Views/Onboarding/ChooseTriggerView.swift \
   MathScroll/Views/Onboarding/ProofSelectionView.swift \
   MathScroll/Views/Onboarding/WhyImportanceView.swift \
   MathScroll/Views/Onboarding/SummaryView.swift
rm MathScroll/Views/Home/AddGoalView.swift
```

- [ ] **Step 2: Stub `MathScrollApp.swift` to compile against an empty SwiftData schema temporarily**

Replace contents of `MathScroll/MathScrollApp.swift` with:

```swift
import SwiftUI
import SwiftData

@main
struct MathScrollApp: App {
    var body: some Scene {
        WindowGroup {
            Text("MathScroll bootstrapping…")
        }
        .modelContainer(for: [], inMemory: true)
    }
}
```

- [ ] **Step 3: Stub `ContentView.swift` and remove imports of deleted types**

Replace `MathScroll/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View { Text("temporary") }
}
```

- [ ] **Step 4: Build and verify it compiles**

```bash
xcodebuild -project MathScroll.xcodeproj -scheme MathScroll -destination 'generic/platform=iOS Simulator' build | tail -20
# Expected: BUILD SUCCEEDED.
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: delete legacy goal-domain models, stores, and views"
```

---

## Phase 2 — Data layer

### Task 4: Add domain enums

**Files:**
- Create: `MathScroll/Models/Enums.swift`
- Test: `MathScrollTests/EnumsTests.swift`

- [ ] **Step 1: Write the failing test**

Create `MathScrollTests/EnumsTests.swift`:

```swift
import XCTest
@testable import MathScroll

final class EnumsTests: XCTestCase {
    func testExamLevelHasGCSEASAndALevel() {
        XCTAssertEqual(ExamLevel.allCases, [.gcse, .asLevel, .aLevel])
    }

    func testExamBoardHasThreeUKBoards() {
        XCTAssertEqual(ExamBoard.allCases, [.edexcel, .aqa, .ocr])
    }

    func testTierAppliesOnlyToGCSE() {
        XCTAssertEqual(Tier.allCases, [.foundation, .higher])
    }

    func testMarkingModeDistinguishesAIFromSelfMark() {
        XCTAssertNotEqual(MarkingMode.ai, MarkingMode.selfMark)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild test -project MathScroll.xcodeproj -scheme MathScroll \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing MathScrollTests/EnumsTests | tail -10
# Expected: build failure ("cannot find 'ExamLevel' in scope").
```

- [ ] **Step 3: Implement the enums**

Create `MathScroll/Models/Enums.swift`:

```swift
import Foundation

enum ExamLevel: String, Codable, CaseIterable, Hashable {
    case gcse, asLevel, aLevel
}

enum ExamBoard: String, Codable, CaseIterable, Hashable {
    case edexcel, aqa, ocr
}

enum Tier: String, Codable, CaseIterable, Hashable {
    case foundation, higher
}

enum MarkingMode: String, Codable, Hashable {
    case ai, selfMark
}

enum LedgerSource: String, Codable, Hashable {
    case earned, spent, dailyCapAdjustment, manualAdjustment
}

enum SkillStatKind: String, Codable, Hashable {
    case subtopic, skill
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
xcodebuild test -project MathScroll.xcodeproj -scheme MathScroll \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing MathScrollTests/EnumsTests | tail -10
# Expected: Test Suite 'EnumsTests' passed.
```

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Models/Enums.swift MathScrollTests/EnumsTests.swift
git commit -m "feat: add domain enums (ExamLevel, ExamBoard, Tier, MarkingMode, LedgerSource, SkillStatKind)"
```

---

### Task 5: Add `UserProfile` SwiftData model

**Files:**
- Create: `MathScroll/Models/UserProfile.swift`
- Create: `MathScroll/Models/Entitlement.swift`
- Test: `MathScrollTests/UserProfileTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

final class UserProfileTests: XCTestCase {
    func testNewProfileHasDefaultDailyCap120() throws {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        XCTAssertEqual(profile.dailyCapMinutes, 120)
        XCTAssertFalse(profile.onboardingDone)
        XCTAssertFalse(profile.freeQuestionUsed)
        XCTAssertNil(profile.entitlement)
    }
}
```

- [ ] **Step 2: Run, verify failure**

```bash
xcodebuild test ... -only-testing MathScrollTests/UserProfileTests | tail -10
# Expected: cannot find 'UserProfile'.
```

- [ ] **Step 3: Implement `Entitlement`**

Create `MathScroll/Models/Entitlement.swift`:

```swift
import Foundation

struct Entitlement: Codable, Hashable {
    var productId: String
    var expiresAt: Date
    var isActive: Bool
}
```

- [ ] **Step 4: Implement `UserProfile`**

Create `MathScroll/Models/UserProfile.swift`:

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var level: ExamLevel = ExamLevel.gcse
    var board: ExamBoard = ExamBoard.edexcel
    var tier: Tier? = Tier.higher
    var dailyCapMinutes: Int = 120
    var blockedAppTokens: Data?
    private var entitlementJSON: Data?
    var onboardingDone: Bool = false
    var paywallSeen: Bool = false
    var freeQuestionUsed: Bool = false

    init() {}

    var entitlement: Entitlement? {
        get {
            guard let data = entitlementJSON else { return nil }
            return try? JSONDecoder().decode(Entitlement.self, from: data)
        }
        set {
            entitlementJSON = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
}
```

- [ ] **Step 5: Run, verify pass**

- [ ] **Step 6: Commit**

```bash
git add MathScroll/Models/UserProfile.swift MathScroll/Models/Entitlement.swift MathScrollTests/UserProfileTests.swift
git commit -m "feat: add UserProfile and Entitlement models"
```

---

### Task 6: Add `QuestionAttempt` SwiftData model

**Files:**
- Create: `MathScroll/Models/QuestionAttempt.swift`
- Test: `MathScrollTests/QuestionAttemptTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

final class QuestionAttemptTests: XCTestCase {
    func testAttemptStoresMarksAndCriteria() throws {
        let container = try ModelContainer(
            for: QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let crit = [
            CriterionResult(criterionId: "M1", awarded: 1, max: 1, rationale: "ok"),
            CriterionResult(criterionId: "A1", awarded: 0, max: 1, rationale: "missed simplification")
        ]
        let a = QuestionAttempt(
            questionId: "q-001",
            imageData: Data([0x01]),
            marksAwarded: 1,
            totalMarks: 2,
            criterionResults: crit,
            skillsCorrect: ["substitute_into_quadratic"],
            skillsIncorrect: ["simplify_surd"],
            improvementTip: "rationalise the denominator",
            secondsSpent: 120,
            markingMode: .ai
        )
        context.insert(a)
        try context.save()
        XCTAssertEqual(a.criterionResults.count, 2)
        XCTAssertEqual(a.criterionResults.first?.criterionId, "M1")
        XCTAssertEqual(a.markingMode, .ai)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the model**

Create `MathScroll/Models/QuestionAttempt.swift`:

```swift
import Foundation
import SwiftData

struct CriterionResult: Codable, Hashable {
    var criterionId: String
    var awarded: Int
    var max: Int
    var rationale: String
}

@Model
final class QuestionAttempt {
    @Attribute(.unique) var id: UUID = UUID()
    var questionId: String = ""
    var submittedAt: Date = Date()
    var imageData: Data = Data()
    var marksAwarded: Int = 0
    var totalMarks: Int = 0
    private var criterionResultsJSON: Data = Data()
    var skillsCorrect: [String] = []
    var skillsIncorrect: [String] = []
    var improvementTip: String = ""
    var secondsSpent: Int = 0
    var markingModeRaw: String = MarkingMode.ai.rawValue

    init(
        questionId: String,
        imageData: Data,
        marksAwarded: Int,
        totalMarks: Int,
        criterionResults: [CriterionResult],
        skillsCorrect: [String],
        skillsIncorrect: [String],
        improvementTip: String,
        secondsSpent: Int,
        markingMode: MarkingMode
    ) {
        self.questionId = questionId
        self.imageData = imageData
        self.marksAwarded = marksAwarded
        self.totalMarks = totalMarks
        self.skillsCorrect = skillsCorrect
        self.skillsIncorrect = skillsIncorrect
        self.improvementTip = improvementTip
        self.secondsSpent = secondsSpent
        self.markingModeRaw = markingMode.rawValue
        self.criterionResultsJSON = (try? JSONEncoder().encode(criterionResults)) ?? Data()
    }

    var criterionResults: [CriterionResult] {
        get { (try? JSONDecoder().decode([CriterionResult].self, from: criterionResultsJSON)) ?? [] }
        set { criterionResultsJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var markingMode: MarkingMode {
        get { MarkingMode(rawValue: markingModeRaw) ?? .ai }
        set { markingModeRaw = newValue.rawValue }
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Models/QuestionAttempt.swift MathScrollTests/QuestionAttemptTests.swift
git commit -m "feat: add QuestionAttempt model with criterion results"
```

---

### Task 7: Add `SkillStat` SwiftData model

**Files:**
- Create: `MathScroll/Models/SkillStat.swift`
- Test: `MathScrollTests/SkillStatTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

final class SkillStatTests: XCTestCase {
    func testNewStatHasZeroPercentages() {
        let s = SkillStat(tag: "differentiate_chain_rule", kind: .skill)
        XCTAssertEqual(s.recencyWeightedPct, 0)
        XCTAssertEqual(s.attemptsCount, 0)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the model**

Create `MathScroll/Models/SkillStat.swift`:

```swift
import Foundation
import SwiftData

@Model
final class SkillStat {
    @Attribute(.unique) var compositeKey: String = ""
    var tag: String = ""
    var kindRaw: String = SkillStatKind.skill.rawValue
    var attemptsCount: Int = 0
    var marksScored: Int = 0
    var marksPossible: Int = 0
    var recencyWeightedPct: Double = 0
    var lastAttemptedAt: Date = .distantPast

    init(tag: String, kind: SkillStatKind) {
        self.tag = tag
        self.kindRaw = kind.rawValue
        self.compositeKey = "\(kind.rawValue):\(tag)"
    }

    var kind: SkillStatKind {
        get { SkillStatKind(rawValue: kindRaw) ?? .skill }
        set { kindRaw = newValue.rawValue }
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Models/SkillStat.swift MathScrollTests/SkillStatTests.swift
git commit -m "feat: add SkillStat model"
```

---

### Task 8: Add `MinutesLedger` SwiftData model

**Files:**
- Create: `MathScroll/Models/MinutesLedger.swift`
- Test: `MathScrollTests/MinutesLedgerTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

final class MinutesLedgerTests: XCTestCase {
    func testEntryStoresDeltaAndSource() {
        let e = MinutesLedger(deltaMinutes: 4, source: .earned)
        XCTAssertEqual(e.deltaMinutes, 4)
        XCTAssertEqual(e.source, .earned)
        XCTAssertNotNil(e.entryId)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the model**

Create `MathScroll/Models/MinutesLedger.swift`:

```swift
import Foundation
import SwiftData

@Model
final class MinutesLedger {
    @Attribute(.unique) var entryId: UUID = UUID()
    var date: Date = Date()
    var deltaMinutes: Int = 0
    var sourceRaw: String = LedgerSource.earned.rawValue

    init(deltaMinutes: Int, source: LedgerSource, date: Date = .now) {
        self.deltaMinutes = deltaMinutes
        self.sourceRaw = source.rawValue
        self.date = date
    }

    var source: LedgerSource {
        get { LedgerSource(rawValue: sourceRaw) ?? .earned }
        set { sourceRaw = newValue.rawValue }
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Models/MinutesLedger.swift MathScrollTests/MinutesLedgerTests.swift
git commit -m "feat: add MinutesLedger append-only model"
```

---

### Task 9: Add `Question` and `MarkingResult` value-type DTOs

**Files:**
- Create: `MathScroll/Models/Question.swift`
- Create: `MathScroll/Models/MarkingResult.swift`
- Test: `MathScrollTests/MarkingResultDecodingTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

final class MarkingResultDecodingTests: XCTestCase {
    func testDecodesValidJSON() throws {
        let json = """
        {
          "totalAwarded": 4,
          "totalPossible": 6,
          "criteria": [
            {"criterionId":"M1","awarded":1,"max":1,"rationale":"ok"}
          ],
          "skillsCorrect": ["a"],
          "skillsIncorrect": ["b"],
          "improvementTip": "tip"
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(MarkingResult.self, from: json)
        XCTAssertEqual(r.totalAwarded, 4)
        XCTAssertEqual(r.criteria.count, 1)
    }

    func testRejectsMissingFields() {
        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(MarkingResult.self, from: json))
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement DTOs**

Create `MathScroll/Models/Question.swift`:

```swift
import Foundation

struct Question: Identifiable, Codable, Hashable {
    let id: String
    let board: ExamBoard
    let level: ExamLevel
    let tier: Tier?
    let paperYear: Int
    let paperCode: String
    let questionNumber: String
    let questionImageURL: URL
    let markSchemeImageURL: URL
    let totalMarks: Int
    let subtopicTags: [String]
    let skillTags: [String]
    let difficulty: Int

    enum CodingKeys: String, CodingKey {
        case id, board, level, tier, difficulty
        case paperYear = "paper_year"
        case paperCode = "paper_code"
        case questionNumber = "question_number"
        case questionImageURL = "question_image_url"
        case markSchemeImageURL = "mark_scheme_image_url"
        case totalMarks = "total_marks"
        case subtopicTags = "subtopic_tags"
        case skillTags = "skill_tags"
    }
}
```

Create `MathScroll/Models/MarkingResult.swift`:

```swift
import Foundation

struct MarkingResult: Codable, Hashable {
    let totalAwarded: Int
    let totalPossible: Int
    let criteria: [CriterionResult]
    let skillsCorrect: [String]
    let skillsIncorrect: [String]
    let improvementTip: String
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Models/Question.swift MathScroll/Models/MarkingResult.swift MathScrollTests/MarkingResultDecodingTests.swift
git commit -m "feat: add Question DTO and MarkingResult schema"
```

---

### Task 10: Add Supabase schema for questions, attempts, skill_stats

**Files:**
- Create: `supabase/migrations/20260427000000_mathscroll_schema.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Questions bank (populated by separate ingestion pipeline; app reads only)
create table if not exists public.questions (
    id text primary key,
    board text not null check (board in ('edexcel','aqa','ocr')),
    level text not null check (level in ('gcse','asLevel','aLevel')),
    tier text check (tier in ('foundation','higher')),
    paper_year int not null,
    paper_code text not null,
    question_number text not null,
    question_image_url text not null,
    mark_scheme_image_url text not null,
    total_marks int not null,
    subtopic_tags text[] not null default '{}',
    skill_tags text[] not null default '{}',
    difficulty int not null check (difficulty between 1 and 5),
    created_at timestamptz not null default now()
);

create index if not exists questions_filter_idx
    on public.questions (level, board, tier);

-- Attempts (per-user, mirrored from device)
create table if not exists public.attempts (
    id uuid primary key,
    user_id uuid references auth.users(id) on delete cascade,
    question_id text not null references public.questions(id),
    submitted_at timestamptz not null,
    marks_awarded int not null,
    total_marks int not null,
    criterion_results jsonb not null,
    skills_correct text[] not null default '{}',
    skills_incorrect text[] not null default '{}',
    improvement_tip text not null default '',
    seconds_spent int not null default 0,
    marking_mode text not null check (marking_mode in ('ai','selfMark')),
    created_at timestamptz not null default now()
);

create index if not exists attempts_user_idx on public.attempts (user_id, submitted_at desc);

-- Skill stats (per-user mirror of device weakness model)
create table if not exists public.skill_stats (
    user_id uuid not null references auth.users(id) on delete cascade,
    tag text not null,
    kind text not null check (kind in ('subtopic','skill')),
    attempts_count int not null default 0,
    marks_scored int not null default 0,
    marks_possible int not null default 0,
    recency_weighted_pct double precision not null default 0,
    last_attempted_at timestamptz,
    primary key (user_id, kind, tag)
);

-- RLS
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.skill_stats enable row level security;

create policy "questions readable by all authenticated"
    on public.questions for select to authenticated using (true);

create policy "attempts owner-only"
    on public.attempts for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "skill_stats owner-only"
    on public.skill_stats for all to authenticated
    using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

- [ ] **Step 2: Apply locally**

```bash
cd supabase
supabase db reset    # local stack only
```

Expected: migration applies cleanly. Verify with `supabase db diff` (no diff).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260427000000_mathscroll_schema.sql
git commit -m "feat: supabase schema for questions, attempts, skill_stats"
```

---

## Phase 3 — Question source & marking

### Task 11: `QuestionBankService` — Supabase fetcher

**Files:**
- Create: `MathScroll/Services/QuestionBankService.swift`
- Test: `MathScrollTests/QuestionBankServiceTests.swift`

- [ ] **Step 1: Write the failing test (uses a fake transport)**

```swift
import XCTest
@testable import MathScroll

final class QuestionBankServiceTests: XCTestCase {
    func testFetchByFiltersReturnsDecodedQuestions() async throws {
        let stub = StubBankTransport(rows: [
            Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        ])
        let svc = QuestionBankService(transport: stub)
        let result = try await svc.fetchAvailable(level: .gcse, board: .edexcel, tier: .higher)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "q-1")
    }
}

private struct StubBankTransport: QuestionBankTransport {
    let rows: [Question]
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] { rows }
}

extension Question {
    static func fixture(id: String, level: ExamLevel, board: ExamBoard) -> Question {
        Question(
            id: id, board: board, level: level, tier: .higher,
            paperYear: 2023, paperCode: "1H", questionNumber: "5",
            questionImageURL: URL(string: "https://example.com/q.png")!,
            markSchemeImageURL: URL(string: "https://example.com/ms.png")!,
            totalMarks: 4, subtopicTags: ["quadratics"], skillTags: ["complete_the_square"],
            difficulty: 3
        )
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the service + transport protocol**

Create `MathScroll/Services/QuestionBankService.swift`:

```swift
import Foundation
import Supabase

protocol QuestionBankTransport {
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question]
}

struct SupabaseBankTransport: QuestionBankTransport {
    let client: SupabaseClient
    func fetch(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] {
        var query = client.from("questions")
            .select()
            .eq("level", value: level.rawValue)
            .eq("board", value: board.rawValue)
        if let tier {
            query = query.eq("tier", value: tier.rawValue)
        }
        return try await query.execute().value
    }
}

final class QuestionBankService {
    private let transport: QuestionBankTransport
    init(transport: QuestionBankTransport) { self.transport = transport }

    func fetchAvailable(level: ExamLevel, board: ExamBoard, tier: Tier?) async throws -> [Question] {
        try await transport.fetch(level: level, board: board, tier: tier)
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Services/QuestionBankService.swift MathScrollTests/QuestionBankServiceTests.swift
git commit -m "feat: QuestionBankService with injectable transport"
```

---

### Task 12: Recommendation algorithm (pure function on stats + question pool)

**Files:**
- Create: `MathScroll/Stores/QuestionRecommender.swift`
- Test: `MathScrollTests/QuestionRecommenderTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

final class QuestionRecommenderTests: XCTestCase {
    func testFiltersOutAttemptedWithin30Days() {
        let pool = [Question.fixture(id: "q-1", level: .gcse, board: .edexcel)]
        let recent = [(questionId: "q-1", at: Date().addingTimeInterval(-3600))]
        let rec = QuestionRecommender(rng: DeterministicRNG(seed: 1))
        let pick = rec.pick(from: pool, stats: [], recentAttempts: recent, lastSubtopics: [])
        XCTAssertNil(pick, "must exclude questions attempted in last 30 days")
    }

    func testForcesSubtopicChangeAfter5StreakOnSameSubtopic() {
        let pool = [
            Question.fixture(id: "q-quad", level: .gcse, board: .edexcel),
            Question.fixture(id: "q-other", level: .gcse, board: .edexcel)
        ]
        // q-quad has subtopic ["quadratics"]; q-other has ["quadratics"] — re-tag for the test:
        let q1 = pool[0]
        let q2 = Question(
            id: "q-other", board: .edexcel, level: .gcse, tier: .higher,
            paperYear: 2023, paperCode: "1H", questionNumber: "6",
            questionImageURL: q1.questionImageURL, markSchemeImageURL: q1.markSchemeImageURL,
            totalMarks: 4, subtopicTags: ["calculus"], skillTags: ["differentiate_polynomial"],
            difficulty: 3
        )
        let rec = QuestionRecommender(rng: DeterministicRNG(seed: 1))
        let pick = rec.pick(
            from: [q1, q2],
            stats: [],
            recentAttempts: [],
            lastSubtopics: Array(repeating: "quadratics", count: 5)
        )
        XCTAssertEqual(pick?.id, "q-other", "after 5 quadratics, must switch subtopic")
    }
}

struct DeterministicRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the recommender**

Create `MathScroll/Stores/QuestionRecommender.swift`:

```swift
import Foundation

struct RecentAttempt {
    let questionId: String
    let at: Date
}

struct QuestionRecommender {
    var rng: any RandomNumberGenerator

    /// Picks the next question from `pool`, applying:
    ///   - filter: questions attempted within 30 days are excluded
    ///   - filter: if the last 5 picks were all the same subtopic, must switch
    ///   - weighting: 60% weak, 30% improving, 10% coverage
    func pick(
        from pool: [Question],
        stats: [SkillStat],
        recentAttempts: [RecentAttempt],
        lastSubtopics: [String]
    ) -> Question? {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentIds = Set(recentAttempts.filter { $0.at >= cutoff }.map(\.questionId))
        var candidates = pool.filter { !recentIds.contains($0.id) }

        if lastSubtopics.count >= 5,
           Set(lastSubtopics.suffix(5)).count == 1,
           let stuckSubtopic = lastSubtopics.last {
            candidates = candidates.filter { !$0.subtopicTags.contains(stuckSubtopic) }
        }

        guard !candidates.isEmpty else { return nil }

        let weakSkills = Set(
            stats
                .filter { $0.kind == .skill && $0.attemptsCount >= 2 && $0.recencyWeightedPct < 60 }
                .map(\.tag)
        )
        let improvingSkills = improvingSkillTags(from: stats)
        let coverageSkills = Set(stats.filter { $0.attemptsCount == 0 }.map(\.tag))

        let weakBucket = candidates.filter { !weakSkills.intersection($0.skillTags).isEmpty }
        let improvingBucket = candidates.filter { !improvingSkills.intersection($0.skillTags).isEmpty }
        let coverageBucket = candidates.filter {
            $0.skillTags.allSatisfy { tag in
                !stats.contains(where: { $0.tag == tag && $0.attemptsCount > 0 })
            }
        }

        var rngLocal = rng
        let r = Double.random(in: 0..<1, using: &rngLocal)
        if r < 0.60, let q = weakBucket.randomElement(using: &rngLocal) { return q }
        if r < 0.90, let q = improvingBucket.randomElement(using: &rngLocal) { return q }
        if let q = coverageBucket.randomElement(using: &rngLocal) { return q }
        return candidates.randomElement(using: &rngLocal)
    }

    private func improvingSkillTags(from stats: [SkillStat]) -> Set<String> {
        // v1: any skill with recencyWeightedPct between 60 and 85 and >=3 attempts
        Set(
            stats
                .filter { $0.kind == .skill && $0.attemptsCount >= 3 && (60..<85).contains($0.recencyWeightedPct) }
                .map(\.tag)
        )
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/QuestionRecommender.swift MathScrollTests/QuestionRecommenderTests.swift
git commit -m "feat: question recommendation algorithm"
```

---

### Task 13: `MarkingService` — Gemini call via Supabase edge function

**Files:**
- Create: `supabase/functions/mark-question/index.ts`
- Create: `MathScroll/Services/MarkingService.swift`
- Test: `MathScrollTests/MarkingServiceTests.swift`

- [ ] **Step 1: Write the edge function**

Create `supabase/functions/mark-question/index.ts`:

```ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY")!;
const MODEL = "gemini-2.5-flash";

interface MarkRequest {
  question_image_url: string;
  mark_scheme_image_url: string;
  student_image_base64: string;
}

const SYSTEM = `You are a strict GCSE/A-Level Maths examiner. Mark the student's working against the official mark scheme. Award marks per criterion. If the student scored full marks, return improvementTip as an empty string. Respond ONLY with JSON matching this exact schema:
{"totalAwarded":int,"totalPossible":int,"criteria":[{"criterionId":string,"awarded":int,"max":int,"rationale":string}],"skillsCorrect":string[],"skillsIncorrect":string[],"improvementTip":string}`;

Deno.serve(async (req) => {
  const body: MarkRequest = await req.json();
  const payload = {
    contents: [{
      parts: [
        { text: SYSTEM },
        { fileData: { fileUri: body.question_image_url, mimeType: "image/png" } },
        { fileData: { fileUri: body.mark_scheme_image_url, mimeType: "image/png" } },
        { inlineData: { data: body.student_image_base64, mimeType: "image/jpeg" } }
      ]
    }],
    generationConfig: { responseMimeType: "application/json" }
  };
  const resp = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_KEY}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }
  );
  const data = await resp.json();
  const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  return new Response(text, { headers: { "Content-Type": "application/json" } });
});
```

- [ ] **Step 2: Deploy the edge function**

```bash
supabase functions deploy mark-question --project-ref <ref>
supabase secrets set GEMINI_API_KEY=<key> --project-ref <ref>
```

- [ ] **Step 3: Write the failing client test**

```swift
import XCTest
@testable import MathScroll

final class MarkingServiceTests: XCTestCase {
    func testParsesValidResponse() async throws {
        let stub = StubMarkingTransport(rawResponses: [Data("""
        {"totalAwarded":3,"totalPossible":4,"criteria":[
          {"criterionId":"M1","awarded":1,"max":1,"rationale":"ok"}
        ],"skillsCorrect":["a"],"skillsIncorrect":["b"],"improvementTip":"x"}
        """.utf8)])
        let svc = MarkingService(transport: stub)
        let result = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                        studentImage: Data([0x01]))
        XCTAssertEqual(result.totalAwarded, 3)
    }

    func testRetriesOnceOnInvalidJSONThenSucceeds() async throws {
        let stub = StubMarkingTransport(rawResponses: [
            Data("not json".utf8),
            Data("""
            {"totalAwarded":2,"totalPossible":2,"criteria":[],"skillsCorrect":[],"skillsIncorrect":[],"improvementTip":""}
            """.utf8)
        ])
        let svc = MarkingService(transport: stub)
        let r = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                   studentImage: Data([0x01]))
        XCTAssertEqual(r.totalAwarded, 2)
        XCTAssertEqual(stub.callCount, 2)
    }

    func testThrowsAfterTwoInvalidResponses() async {
        let stub = StubMarkingTransport(rawResponses: [Data("a".utf8), Data("b".utf8)])
        let svc = MarkingService(transport: stub)
        do {
            _ = try await svc.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                                   studentImage: Data([0x01]))
            XCTFail("should throw")
        } catch is MarkingError {}
        catch { XCTFail("wrong error type") }
    }
}

final class StubMarkingTransport: MarkingTransport {
    var rawResponses: [Data]
    var callCount = 0
    init(rawResponses: [Data]) { self.rawResponses = rawResponses }
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data {
        defer { callCount += 1 }
        return rawResponses[min(callCount, rawResponses.count - 1)]
    }
}
```

- [ ] **Step 4: Run, verify failure**

- [ ] **Step 5: Implement `MarkingService`**

Create `MathScroll/Services/MarkingService.swift`:

```swift
import Foundation
import Supabase

enum MarkingError: Error, Equatable {
    case invalidResponse
    case networkFailed
}

protocol MarkingTransport {
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data
}

struct EdgeFunctionMarkingTransport: MarkingTransport {
    let client: SupabaseClient
    func invoke(question: Question, studentImage: Data, strict: Bool) async throws -> Data {
        struct Body: Encodable {
            let question_image_url: String
            let mark_scheme_image_url: String
            let student_image_base64: String
        }
        let body = Body(
            question_image_url: question.questionImageURL.absoluteString,
            mark_scheme_image_url: question.markSchemeImageURL.absoluteString,
            student_image_base64: studentImage.base64EncodedString()
        )
        let response = try await client.functions
            .invoke("mark-question", options: .init(body: body))
        return response
    }
}

final class MarkingService {
    private let transport: MarkingTransport
    init(transport: MarkingTransport) { self.transport = transport }

    func mark(question: Question, studentImage: Data) async throws -> MarkingResult {
        let attempt: (Bool) async throws -> Data = { strict in
            try await self.transport.invoke(question: question, studentImage: studentImage, strict: strict)
        }
        do {
            let raw = try await attempt(false)
            return try JSONDecoder().decode(MarkingResult.self, from: raw)
        } catch is DecodingError {
            let raw = try await attempt(true)
            do {
                return try JSONDecoder().decode(MarkingResult.self, from: raw)
            } catch is DecodingError {
                throw MarkingError.invalidResponse
            }
        }
    }
}
```

- [ ] **Step 6: Run, verify pass**

- [ ] **Step 7: Commit**

```bash
git add supabase/functions/mark-question MathScroll/Services/MarkingService.swift MathScrollTests/MarkingServiceTests.swift
git commit -m "feat: MarkingService with retry-on-malformed-JSON via Gemini edge function"
```

---

### Task 14: `MarkingStore` — observable wrapper with self-mark fallback state

**Files:**
- Create: `MathScroll/Stores/MarkingStore.swift`
- Test: `MathScrollTests/MarkingStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

@MainActor
final class MarkingStoreTests: XCTestCase {
    func testSuccessTransitionsToResult() async {
        let svc = MarkingService(transport: StubMarkingTransport(rawResponses: [Data("""
            {"totalAwarded":2,"totalPossible":2,"criteria":[],"skillsCorrect":[],"skillsIncorrect":[],"improvementTip":""}
        """.utf8)]))
        let store = MarkingStore(service: svc)
        await store.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                         studentImage: Data([0x01]))
        if case .result(let r) = store.state { XCTAssertEqual(r.totalAwarded, 2) }
        else { XCTFail("expected .result, got \(store.state)") }
    }

    func testFailureTransitionsToSelfMarkPrompt() async {
        let svc = MarkingService(transport: StubMarkingTransport(rawResponses: [Data("a".utf8), Data("b".utf8)]))
        let store = MarkingStore(service: svc)
        await store.mark(question: .fixture(id: "q", level: .gcse, board: .edexcel),
                         studentImage: Data([0x01]))
        if case .selfMarkPrompt = store.state {} else { XCTFail("expected .selfMarkPrompt") }
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the store**

Create `MathScroll/Stores/MarkingStore.swift`:

```swift
import Foundation

@MainActor
@Observable
final class MarkingStore {
    enum State {
        case idle
        case loading
        case result(MarkingResult)
        case selfMarkPrompt(reason: String)
    }

    private let service: MarkingService
    private(set) var state: State = .idle

    init(service: MarkingService) { self.service = service }

    func mark(question: Question, studentImage: Data) async {
        state = .loading
        do {
            let r = try await service.mark(question: question, studentImage: studentImage)
            state = .result(r)
        } catch {
            state = .selfMarkPrompt(reason: "AI marking failed. Self-mark this attempt?")
        }
    }

    /// Build a synthetic MarkingResult from the student's full/zero per-criterion choice.
    func acceptSelfMark(_ awards: [CriterionResult], totalPossible: Int) {
        state = .result(MarkingResult(
            totalAwarded: awards.map(\.awarded).reduce(0, +),
            totalPossible: totalPossible,
            criteria: awards,
            skillsCorrect: [],
            skillsIncorrect: [],
            improvementTip: ""
        ))
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/MarkingStore.swift MathScrollTests/MarkingStoreTests.swift
git commit -m "feat: MarkingStore with self-mark fallback state machine"
```

---

### Task 15: `QuestionBankStore` — fetch + cache + recommend

**Files:**
- Create: `MathScroll/Stores/QuestionBankStore.swift`
- Test: `MathScrollTests/QuestionBankStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

@MainActor
final class QuestionBankStoreTests: XCTestCase {
    func testNextQuestionReturnsRecommendedFromBank() async throws {
        let svc = QuestionBankService(transport: StubBankTransport(rows: [
            Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        ]))
        let store = QuestionBankStore(service: svc, recommender: QuestionRecommender(rng: DeterministicRNG(seed: 1)))
        let q = try await store.nextQuestion(level: .gcse, board: .edexcel, tier: .higher,
                                             stats: [], recentAttempts: [], lastSubtopics: [])
        XCTAssertEqual(q?.id, "q-1")
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the store**

Create `MathScroll/Stores/QuestionBankStore.swift`:

```swift
import Foundation

@MainActor
@Observable
final class QuestionBankStore {
    private let service: QuestionBankService
    private var recommender: QuestionRecommender
    private var cache: [String: [Question]] = [:]

    init(service: QuestionBankService, recommender: QuestionRecommender) {
        self.service = service
        self.recommender = recommender
    }

    func nextQuestion(
        level: ExamLevel,
        board: ExamBoard,
        tier: Tier?,
        stats: [SkillStat],
        recentAttempts: [RecentAttempt],
        lastSubtopics: [String]
    ) async throws -> Question? {
        let key = "\(level.rawValue)-\(board.rawValue)-\(tier?.rawValue ?? "any")"
        let pool: [Question]
        if let cached = cache[key] { pool = cached }
        else {
            pool = try await service.fetchAvailable(level: level, board: board, tier: tier)
            cache[key] = pool
        }
        return recommender.pick(from: pool, stats: stats, recentAttempts: recentAttempts, lastSubtopics: lastSubtopics)
    }

    func clearCache() { cache.removeAll() }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/QuestionBankStore.swift MathScrollTests/QuestionBankStoreTests.swift
git commit -m "feat: QuestionBankStore wires fetcher + recommender"
```

---

### Task 16: `SessionStore` — current question lifecycle

**Files:**
- Create: `MathScroll/Stores/SessionStore.swift`
- Test: `MathScrollTests/SessionStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

@MainActor
final class SessionStoreTests: XCTestCase {
    func testLifecycle() {
        let s = SessionStore()
        XCTAssertEqual(s.phase, .idle)
        s.load(question: .fixture(id: "q", level: .gcse, board: .edexcel))
        XCTAssertEqual(s.phase, .loaded)
        s.attachWorking(image: Data([0x01]))
        XCTAssertEqual(s.phase, .photographed)
        s.markSubmitted()
        XCTAssertEqual(s.phase, .submitted)
        s.markCompleted()
        XCTAssertEqual(s.phase, .completed)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement**

Create `MathScroll/Stores/SessionStore.swift`:

```swift
import Foundation

@MainActor
@Observable
final class SessionStore {
    enum Phase: String { case idle, loaded, photographed, submitted, completed }

    private(set) var question: Question?
    private(set) var workingImage: Data?
    private(set) var phase: Phase = .idle
    private(set) var startedAt: Date?

    func load(question: Question) {
        self.question = question
        self.workingImage = nil
        self.phase = .loaded
        self.startedAt = .now
    }

    func attachWorking(image: Data) {
        self.workingImage = image
        self.phase = .photographed
    }

    func markSubmitted() { phase = .submitted }
    func markCompleted() { phase = .completed }

    var secondsSpent: Int {
        guard let startedAt else { return 0 }
        return Int(Date.now.timeIntervalSince(startedAt))
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/SessionStore.swift MathScrollTests/SessionStoreTests.swift
git commit -m "feat: SessionStore current-question lifecycle"
```

---

## Phase 4 — Stats, minutes, paywall

### Task 17: `StatsStore` — recompute SkillStats and rank weaknesses

**Files:**
- Create: `MathScroll/Stores/StatsStore.swift`
- Test: `MathScrollTests/StatsStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class StatsStoreTests: XCTestCase {
    func testApplyAttemptUpdatesSkillStats() throws {
        let container = try ModelContainer(
            for: SkillStat.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let store = StatsStore(context: context)

        let attempt = QuestionAttempt(
            questionId: "q-1", imageData: Data(), marksAwarded: 1, totalMarks: 2,
            criterionResults: [], skillsCorrect: ["substitute"], skillsIncorrect: ["simplify_surd"],
            improvementTip: "", secondsSpent: 60, markingMode: .ai
        )
        context.insert(attempt)
        try context.save()
        store.apply(attempt: attempt, totalMarks: 2)

        let stats = try context.fetch(FetchDescriptor<SkillStat>())
        XCTAssertEqual(stats.count, 2)
        let simplify = stats.first(where: { $0.tag == "simplify_surd" })!
        XCTAssertEqual(simplify.attemptsCount, 1)
        XCTAssertEqual(simplify.marksScored, 0)
        XCTAssertEqual(simplify.marksPossible, 2)
    }

    func testWeaknessRankingOrdersByLowestPercentageFirst() throws {
        let container = try ModelContainer(
            for: SkillStat.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let s1 = SkillStat(tag: "a", kind: .skill); s1.attemptsCount = 5; s1.recencyWeightedPct = 30
        let s2 = SkillStat(tag: "b", kind: .skill); s2.attemptsCount = 5; s2.recencyWeightedPct = 80
        context.insert(s1); context.insert(s2); try context.save()
        let store = StatsStore(context: context)
        let weakest = store.weaknessRanking(limit: 5)
        XCTAssertEqual(weakest.first?.tag, "a")
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the store**

Create `MathScroll/Stores/StatsStore.swift`:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class StatsStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func apply(attempt: QuestionAttempt, totalMarks: Int) {
        // Each tagged skill receives credit proportional to overall question score.
        let pct = totalMarks == 0 ? 0 : Double(attempt.marksAwarded) / Double(totalMarks)
        for tag in attempt.skillsCorrect {
            updateStat(tag: tag, kind: .skill, scored: totalMarks, possible: totalMarks, sessionPct: pct)
        }
        for tag in attempt.skillsIncorrect {
            updateStat(tag: tag, kind: .skill, scored: 0, possible: totalMarks, sessionPct: pct)
        }
        // (Subtopic-level recompute can be added by mapping skillTag→subtopic via Question metadata.)
        try? context.save()
    }

    private func updateStat(tag: String, kind: SkillStatKind, scored: Int, possible: Int, sessionPct: Double) {
        let key = "\(kind.rawValue):\(tag)"
        let existing = try? context.fetch(FetchDescriptor<SkillStat>(
            predicate: #Predicate<SkillStat> { $0.compositeKey == key }
        )).first
        let stat = existing ?? {
            let s = SkillStat(tag: tag, kind: kind)
            context.insert(s)
            return s
        }()
        stat.attemptsCount += 1
        stat.marksScored += scored
        stat.marksPossible += possible
        // Recency-weighted exponential moving average, alpha = 0.4
        let alpha = 0.4
        stat.recencyWeightedPct = stat.attemptsCount == 1
            ? sessionPct * 100
            : (1 - alpha) * stat.recencyWeightedPct + alpha * sessionPct * 100
        stat.lastAttemptedAt = .now
    }

    func weaknessRanking(limit: Int) -> [SkillStat] {
        let descriptor = FetchDescriptor<SkillStat>(
            predicate: #Predicate<SkillStat> { $0.attemptsCount >= 1 },
            sortBy: [SortDescriptor(\.recencyWeightedPct, order: .forward)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        return Array(all.prefix(limit))
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/StatsStore.swift MathScrollTests/StatsStoreTests.swift
git commit -m "feat: StatsStore — recency-weighted skill stats and weakness ranking"
```

---

### Task 18: `MinutesStore` — ledger, daily cap, ScreenTime hooks

**Files:**
- Create: `MathScroll/Stores/MinutesStore.swift`
- Test: `MathScrollTests/MinutesStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class MinutesStoreTests: XCTestCase {
    func testEarnAddsToBalance() throws {
        let store = try makeStore()
        store.earn(minutes: 5)
        XCTAssertEqual(store.balance, 5)
    }

    func testDailyCapClampsEarnings() throws {
        let store = try makeStore(dailyCap: 10)
        store.earn(minutes: 7)
        store.earn(minutes: 7)
        XCTAssertEqual(store.balance, 10)
    }

    private func makeStore(dailyCap: Int = 120) throws -> MinutesStore {
        let container = try ModelContainer(
            for: MinutesLedger.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return MinutesStore(context: ModelContext(container), dailyCapMinutes: dailyCap)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement**

Create `MathScroll/Stores/MinutesStore.swift`:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class MinutesStore {
    private let context: ModelContext
    var dailyCapMinutes: Int

    init(context: ModelContext, dailyCapMinutes: Int) {
        self.context = context
        self.dailyCapMinutes = dailyCapMinutes
    }

    var balance: Int {
        let entries = (try? context.fetch(FetchDescriptor<MinutesLedger>())) ?? []
        return entries.map(\.deltaMinutes).reduce(0, +)
    }

    func earn(minutes: Int) {
        let allowed = min(minutes, remainingTodayCap())
        guard allowed > 0 else { return }
        context.insert(MinutesLedger(deltaMinutes: allowed, source: .earned))
        if allowed < minutes {
            context.insert(MinutesLedger(deltaMinutes: 0, source: .dailyCapAdjustment))
        }
        try? context.save()
    }

    func spend(minutes: Int) {
        guard balance >= minutes, minutes > 0 else { return }
        context.insert(MinutesLedger(deltaMinutes: -minutes, source: .spent))
        try? context.save()
    }

    private func remainingTodayCap() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let descriptor = FetchDescriptor<MinutesLedger>(
            predicate: #Predicate<MinutesLedger> { $0.date >= startOfDay && $0.sourceRaw == "earned" }
        )
        let earnedToday = ((try? context.fetch(descriptor)) ?? []).map(\.deltaMinutes).reduce(0, +)
        return max(0, dailyCapMinutes - earnedToday)
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/MinutesStore.swift MathScrollTests/MinutesStoreTests.swift
git commit -m "feat: MinutesStore with append-only ledger and daily cap"
```

---

### Task 19: `EntitlementsService` + `PaywallStore` (StoreKit 2)

**Files:**
- Create: `MathScroll/Stores/EntitlementsService.swift`
- Create: `MathScroll/Stores/PaywallStore.swift`
- Test: `MathScrollTests/PaywallStoreTests.swift`

- [ ] **Step 1: Define product ids in App Store Connect (manual)**

- `mathscroll.weekly` £4.99
- `mathscroll.monthly` £19.99 with 7-day free trial
- `mathscroll.annual` £79.99

- [ ] **Step 2: Write the failing test**

```swift
import XCTest
@testable import MathScroll

@MainActor
final class PaywallStoreTests: XCTestCase {
    func testActiveEntitlementGrantsAccess() {
        let svc = EntitlementsService(loader: { Entitlement(productId: "mathscroll.weekly", expiresAt: .distantFuture, isActive: true) })
        let store = PaywallStore(entitlements: svc)
        store.refresh()
        XCTAssertTrue(store.hasAccess)
    }

    func testNoEntitlementBlocks() {
        let svc = EntitlementsService(loader: { nil })
        let store = PaywallStore(entitlements: svc)
        store.refresh()
        XCTAssertFalse(store.hasAccess)
    }
}
```

- [ ] **Step 3: Run, verify failure**

- [ ] **Step 4: Implement `EntitlementsService`**

Create `MathScroll/Stores/EntitlementsService.swift`:

```swift
import Foundation
import StoreKit

@MainActor
final class EntitlementsService {
    private let loader: () async -> Entitlement?
    init(loader: @escaping () async -> Entitlement?) { self.loader = loader }

    convenience init() {
        self.init(loader: {
            for await result in Transaction.currentEntitlements {
                if case .verified(let t) = result, t.expirationDate.map({ $0 > .now }) ?? false {
                    return Entitlement(productId: t.productID,
                                       expiresAt: t.expirationDate ?? .distantFuture,
                                       isActive: true)
                }
            }
            return nil
        })
    }

    func current() async -> Entitlement? { await loader() }
}
```

- [ ] **Step 5: Implement `PaywallStore`**

Create `MathScroll/Stores/PaywallStore.swift`:

```swift
import Foundation
import StoreKit

@MainActor
@Observable
final class PaywallStore {
    private let entitlements: EntitlementsService
    private(set) var entitlement: Entitlement?
    private(set) var products: [Product] = []

    init(entitlements: EntitlementsService) { self.entitlements = entitlements }

    var hasAccess: Bool { entitlement?.isActive == true }

    func refresh() {
        Task { entitlement = await entitlements.current() }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: ["mathscroll.weekly", "mathscroll.monthly", "mathscroll.annual"])
        } catch { products = [] }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        if case .success(.verified(let tx)) = result {
            await tx.finish()
            entitlement = await entitlements.current()
            return true
        }
        return false
    }

    func restore() async {
        try? await AppStore.sync()
        entitlement = await entitlements.current()
    }
}
```

- [ ] **Step 6: Run, verify pass**

- [ ] **Step 7: Commit**

```bash
git add MathScroll/Stores/EntitlementsService.swift MathScroll/Stores/PaywallStore.swift MathScrollTests/PaywallStoreTests.swift
git commit -m "feat: StoreKit 2 paywall with weekly/monthly/annual products"
```

---

### Task 20: `AppState` rewrite — onboarding + paywall flags + sheet routing

**Files:**
- Modify: `MathScroll/Stores/AppState.swift`
- Test: `MathScrollTests/AppStateTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

@MainActor
final class AppStateTests: XCTestCase {
    func testRouteIsOnboardingWhenNotDone() {
        let s = AppState()
        s.profile = UserProfile()
        XCTAssertEqual(s.route, .onboarding)
    }

    func testRouteIsPaywallWhenFreeUsedAndNoEntitlement() {
        let s = AppState()
        let p = UserProfile(); p.onboardingDone = true; p.freeQuestionUsed = true
        s.profile = p
        XCTAssertEqual(s.route, .paywall)
    }

    func testRouteIsHomeWhenEntitled() {
        let s = AppState()
        let p = UserProfile()
        p.onboardingDone = true
        p.freeQuestionUsed = true
        p.entitlement = Entitlement(productId: "x", expiresAt: .distantFuture, isActive: true)
        s.profile = p
        XCTAssertEqual(s.route, .home)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Replace `AppState.swift`**

```swift
import Foundation

enum AppRoute: Equatable {
    case onboarding
    case freeQuestion
    case paywall
    case postPaywallDiagnostic
    case home
}

enum ActiveSheet: Identifiable {
    case settings, unlock, paywall, weeklyDigest
    var id: Int { hashValue }
}

@MainActor
@Observable
final class AppState {
    var profile: UserProfile?
    var activeSheet: ActiveSheet?

    var route: AppRoute {
        guard let profile else { return .onboarding }
        if !profile.onboardingDone { return .onboarding }
        if !profile.freeQuestionUsed { return .freeQuestion }
        if profile.entitlement?.isActive != true { return .paywall }
        return .home
    }
}
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Stores/AppState.swift MathScrollTests/AppStateTests.swift
git commit -m "feat: AppState route derivation from profile flags"
```

---

## Phase 5 — UI (Liquid Glass)

### Task 21: Liquid Glass theme tokens and `GlassCard` / `GlassCapsule` components

**Files:**
- Modify: `MathScroll/Utilities/Theme.swift`
- Create: `MathScroll/Views/Components/GlassCard.swift`
- Create: `MathScroll/Views/Components/GlassCapsule.swift`

- [ ] **Step 1: Replace `Theme.swift`**

```swift
import SwiftUI

enum Theme {
    static let cornerLarge: CGFloat = 28
    static let cornerMedium: CGFloat = 18
    static let cornerSmall: CGFloat = 12
    static let pad: CGFloat = 16
    static let padLarge: CGFloat = 24

    static let accent = Color.accentColor
    static let success = Color.green
    static let warning = Color.orange
    static let onSurface = Color.primary
}

extension Font {
    static let mathDisplay = Font.system(size: 56, weight: .bold, design: .rounded)
    static let mathTitle = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let mathBody = Font.system(.body, design: .rounded)
}
```

- [ ] **Step 2: Create `GlassCard.swift`**

```swift
import SwiftUI

struct GlassCard<Content: View>: View {
    var corner: CGFloat = Theme.cornerLarge
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.pad)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .glassEffect()
    }
}
```

- [ ] **Step 3: Create `GlassCapsule.swift`**

```swift
import SwiftUI

struct GlassCapsule<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 8) { content }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .glassEffect()
    }
}
```

- [ ] **Step 4: Build and verify (no tests for pure view tokens)**

```bash
xcodebuild -project MathScroll.xcodeproj -scheme MathScroll -destination 'generic/platform=iOS Simulator' build | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Utilities/Theme.swift MathScroll/Views/Components/GlassCard.swift MathScroll/Views/Components/GlassCapsule.swift
git commit -m "feat: Liquid Glass theme tokens, GlassCard, GlassCapsule"
```

---

### Task 22: Onboarding — pick level, board, tier

**Files:**
- Modify: `MathScroll/Views/Onboarding/OnboardingContainerView.swift`
- Create: `MathScroll/Views/Onboarding/PickLevelView.swift`
- Create: `MathScroll/Views/Onboarding/PickBoardView.swift`
- Create: `MathScroll/Views/Onboarding/PickTierView.swift`

- [ ] **Step 1: Replace `OnboardingContainerView.swift`**

```swift
import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile
    @State private var step: Int = 0

    var body: some View {
        VStack {
            switch step {
            case 0: PickLevelView(profile: profile, onNext: advance)
            case 1: PickBoardView(profile: profile, onNext: advance)
            case 2:
                if profile.level == .gcse { PickTierView(profile: profile, onNext: advance) }
                else { Color.clear.onAppear { advance() } }
            case 3: DailyCapView(profile: profile, onNext: advance)
            case 4: PickAppsView(profile: profile, onNext: advance)
            default: Color.clear.onAppear {
                profile.onboardingDone = true
                try? context.save()
            }
            }
        }
        .animation(.spring, value: step)
    }

    private func advance() { step += 1 }
}
```

- [ ] **Step 2: Create `PickLevelView.swift`**

```swift
import SwiftUI

struct PickLevelView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("What are you studying?").font(.mathTitle)
            ForEach(ExamLevel.allCases, id: \.self) { level in
                Button {
                    profile.level = level
                    onNext()
                } label: {
                    GlassCard { Text(label(for: level)).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }

    private func label(for level: ExamLevel) -> String {
        switch level { case .gcse: "GCSE"; case .asLevel: "AS Level"; case .aLevel: "A-Level" }
    }
}
```

- [ ] **Step 3: Create `PickBoardView.swift`**

```swift
import SwiftUI

struct PickBoardView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Which exam board?").font(.mathTitle)
            ForEach(ExamBoard.allCases, id: \.self) { board in
                Button {
                    profile.board = board
                    onNext()
                } label: {
                    GlassCard { Text(board.rawValue.uppercased()).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }
}
```

- [ ] **Step 4: Create `PickTierView.swift`**

```swift
import SwiftUI

struct PickTierView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Foundation or Higher?").font(.mathTitle)
            ForEach(Tier.allCases, id: \.self) { tier in
                Button {
                    profile.tier = tier
                    onNext()
                } label: {
                    GlassCard { Text(tier.rawValue.capitalized).font(.mathBody).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.plain)
            }
        }.padding()
    }
}
```

- [ ] **Step 5: Build and run; manually walk through Pick Level → Board → Tier on simulator**

```bash
xcodebuild -project MathScroll.xcodeproj -scheme MathScroll -destination 'platform=iOS Simulator,name=iPhone 16' build | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add MathScroll/Views/Onboarding/
git commit -m "feat: onboarding screens for level, board, tier"
```

---

### Task 23: Onboarding — daily cap and apps picker

**Files:**
- Create: `MathScroll/Views/Onboarding/DailyCapView.swift`
- Create: `MathScroll/Views/Onboarding/PickAppsView.swift`

- [ ] **Step 1: Create `DailyCapView.swift`**

```swift
import SwiftUI

struct DailyCapView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Daily unlock cap").font(.mathTitle)
            GlassCard {
                VStack(spacing: 12) {
                    Text("\(profile.dailyCapMinutes) min").font(.mathDisplay)
                    Slider(value: Binding(
                        get: { Double(profile.dailyCapMinutes) },
                        set: { profile.dailyCapMinutes = Int($0) }
                    ), in: 30...240, step: 15)
                    Text("Max minutes per day you can earn for unlocking apps.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("Continue") { onNext() }
                .buttonStyle(.borderedProminent)
        }.padding()
    }
}
```

- [ ] **Step 2: Create `PickAppsView.swift`**

```swift
import SwiftUI
import FamilyControls

struct PickAppsView: View {
    @Bindable var profile: UserProfile
    var onNext: () -> Void
    @State private var picker: FamilyActivitySelection = .init()
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Apps to block").font(.mathTitle)
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick the apps that stay locked until you earn minutes.")
                        .font(.mathBody)
                    Button("Choose apps") { showingPicker = true }
                }
            }
            Button("Continue") {
                profile.blockedAppTokens = (try? JSONEncoder().encode(picker)) ?? Data()
                onNext()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .familyActivityPicker(isPresented: $showingPicker, selection: $picker)
    }
}
```

- [ ] **Step 3: Build, verify**

- [ ] **Step 4: Commit**

```bash
git add MathScroll/Views/Onboarding/DailyCapView.swift MathScroll/Views/Onboarding/PickAppsView.swift
git commit -m "feat: onboarding daily cap slider and Family Controls apps picker"
```

---

### Task 24: Free question + result flow

**Files:**
- Create: `MathScroll/Views/Home/SubmitAnswerView.swift`
- Create: `MathScroll/Views/Home/ResultView.swift`
- Create: `MathScroll/Views/Components/MinutesBalancePill.swift`
- Modify: `MathScroll/Views/Capture/CameraView.swift` (rename / verify imports — currently at `Views/Proof/CameraView.swift` if not deleted; ensure path matches Phase 1 deletion plan or move it)

- [ ] **Step 1: Move CameraView to its new home**

```bash
mkdir -p MathScroll/Views/Capture
git mv MathScroll/Views/Proof/CameraView.swift MathScroll/Views/Capture/CameraView.swift  # if it still exists; otherwise restore it from git history before Task 3
```

If it was deleted in Task 3, recover it:

```bash
git checkout HEAD~N -- MathScroll/Views/Proof/CameraView.swift
git mv MathScroll/Views/Proof/CameraView.swift MathScroll/Views/Capture/CameraView.swift
```

- [ ] **Step 2: Create `MinutesBalancePill.swift`**

```swift
import SwiftUI

struct MinutesBalancePill: View {
    var minutes: Int
    var body: some View {
        GlassCapsule {
            Image(systemName: "clock.fill").foregroundStyle(.tint)
            Text("\(minutes) min").font(.mathBody.weight(.semibold))
                .contentTransition(.numericText())
        }
    }
}
```

- [ ] **Step 3: Create `SubmitAnswerView.swift`**

```swift
import SwiftUI

struct SubmitAnswerView: View {
    @Environment(SessionStore.self) private var session
    @State private var capturedImage: Data?
    @State private var showingCamera = false
    var onSubmit: (Data) -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            if let img = capturedImage, let ui = UIImage(data: img) {
                GlassCard {
                    Image(uiImage: ui)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 300)
                }
                Button("Submit for marking") { onSubmit(img) }
                    .buttonStyle(.borderedProminent)
                Button("Retake") { showingCamera = true }.buttonStyle(.plain)
            } else {
                Button { showingCamera = true } label: {
                    GlassCard { Label("Take photo of working", systemImage: "camera.fill").frame(maxWidth: .infinity, minHeight: 80) }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraView { data in
                capturedImage = data
                showingCamera = false
            }
        }
    }
}
```

- [ ] **Step 4: Create `ResultView.swift`**

```swift
import SwiftUI

struct ResultView: View {
    let result: MarkingResult
    let earnedMinutes: Int
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.padLarge) {
                GlassCard {
                    VStack(spacing: 4) {
                        Text("\(result.totalAwarded)/\(result.totalPossible)").font(.mathDisplay)
                        Text("marks awarded").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                MinutesBalancePill(minutes: earnedMinutes)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per criterion").font(.mathBody.weight(.semibold))
                        ForEach(result.criteria, id: \.criterionId) { c in
                            HStack(alignment: .top) {
                                Text(c.criterionId).bold().frame(width: 40, alignment: .leading)
                                Text("\(c.awarded)/\(c.max)").frame(width: 50, alignment: .leading)
                                Text(c.rationale).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !result.improvementTip.isEmpty {
                    GlassCard {
                        Label(result.improvementTip, systemImage: "lightbulb.fill")
                            .font(.mathBody)
                    }
                }

                Button("Next question", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
```

- [ ] **Step 5: Build, verify**

- [ ] **Step 6: Commit**

```bash
git add MathScroll/Views/Home/SubmitAnswerView.swift MathScroll/Views/Home/ResultView.swift MathScroll/Views/Components/MinutesBalancePill.swift MathScroll/Views/Capture/
git commit -m "feat: submit answer flow + result view + minutes balance pill"
```

---

### Task 25: Paywall view

**Files:**
- Create: `MathScroll/Views/Paywall/PaywallView.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Keep your streak").font(.mathTitle)
            Text("Unlock unlimited questions and app blocking.")
                .font(.mathBody).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(paywall.products, id: \.id) { product in
                Button {
                    Task { _ = try? await paywall.purchase(product) }
                } label: {
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text(product.displayName).font(.mathBody.weight(.semibold))
                            Text(product.displayPrice).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }

            Button("Restore purchases") { Task { await paywall.restore() } }
                .font(.caption)
        }
        .padding()
        .task { await paywall.loadProducts() }
    }
}
```

- [ ] **Step 2: Build, verify**

- [ ] **Step 3: Commit**

```bash
git add MathScroll/Views/Paywall/PaywallView.swift
git commit -m "feat: paywall view with StoreKit 2 products and restore"
```

---

### Task 26: Diagnostic screen (post-paywall)

**Files:**
- Create: `MathScroll/Views/Onboarding/DiagnosticView.swift`

- [ ] **Step 1: Implement**

The diagnostic runs a 5-question loop that marks each attempt, applies it to `StatsStore`, but does **not** earn minutes (we're seeding the weakness model only). The student can skip at any time.

```swift
import SwiftUI

struct DiagnosticView: View {
    @Environment(QuestionBankStore.self) private var bank
    @Environment(MarkingStore.self) private var marking
    @Environment(StatsStore.self) private var stats
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile
    var onComplete: () -> Void

    @State private var current: Question?
    @State private var capturedImage: Data?
    @State private var showingCamera = false
    @State private var index = 0
    @State private var isMarking = false

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Quick diagnostic").font(.mathTitle)
            Text("Answer 5 quick questions so we can target your weaknesses.")
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ProgressView(value: Double(index), total: 5).tint(Theme.accent)

            if let q = current {
                GlassCard {
                    AsyncImage(url: q.questionImageURL) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFit()
                        case .failure: Image(systemName: "exclamationmark.triangle")
                        default: ProgressView()
                        }
                    }
                    .frame(maxHeight: 280)
                }
                if isMarking {
                    ProgressView("Marking…")
                } else if let img = capturedImage, let ui = UIImage(data: img) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(maxHeight: 160)
                    Button("Submit") { Task { await submit(image: img) } }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button { showingCamera = true } label: {
                        GlassCard { Label("Take photo", systemImage: "camera.fill").frame(maxWidth: .infinity, minHeight: 60) }
                    }.buttonStyle(.plain)
                }
            } else {
                ProgressView().task { await loadNext() }
            }

            Spacer()
            Button("Skip diagnostic", action: onComplete).font(.caption)
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraView { data in capturedImage = data; showingCamera = false }
        }
    }

    private func loadNext() async {
        guard index < 5 else { onComplete(); return }
        capturedImage = nil
        let q = try? await bank.nextQuestion(
            level: profile.level, board: profile.board, tier: profile.tier,
            stats: stats.weaknessRanking(limit: 200), recentAttempts: [], lastSubtopics: []
        )
        current = q
    }

    private func submit(image: Data) async {
        guard let q = current else { return }
        isMarking = true
        defer { isMarking = false }
        await marking.mark(question: q, studentImage: image)
        if case .result(let r) = marking.state {
            let attempt = QuestionAttempt(
                questionId: q.id, imageData: image,
                marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
                criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
                skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
                secondsSpent: 0, markingMode: .ai
            )
            context.insert(attempt); try? context.save()
            stats.apply(attempt: attempt, totalMarks: r.totalPossible)
        }
        index += 1
        await loadNext()
    }
}
```

- [ ] **Step 2: Build, verify**

- [ ] **Step 3: Commit**

```bash
git add MathScroll/Views/Onboarding/DiagnosticView.swift
git commit -m "feat: diagnostic view scaffold (skippable)"
```

---

### Task 27: Home view + main tab bar (Liquid Glass)

**Files:**
- Create: `MathScroll/Views/Home/HomeView.swift`
- Create: `MathScroll/Views/Home/MainTabView.swift`

- [ ] **Step 1: Create `HomeView.swift`**

```swift
import SwiftUI

struct HomeView: View {
    @Environment(QuestionBankStore.self) private var bank
    @Environment(SessionStore.self) private var session
    @Environment(MinutesStore.self) private var minutes
    @Environment(StatsStore.self) private var stats
    @Bindable var profile: UserProfile

    @State private var loadingNext = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.padLarge) {
                HStack {
                    Spacer()
                    MinutesBalancePill(minutes: minutes.balance)
                }

                if let q = session.question {
                    GlassCard {
                        AsyncImage(url: q.questionImageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFit()
                            case .failure: Image(systemName: "exclamationmark.triangle")
                            default: ProgressView()
                            }
                        }
                        .frame(maxHeight: 320)
                    }
                } else {
                    GlassCard { Text("Loading next question…").frame(maxWidth: .infinity) }
                        .task { await loadNext() }
                }

                NavigationLink("Submit answer", destination: {
                    SubmitAnswerView { _ in /* handled in Task 28 wiring */ }
                })
                .buttonStyle(.borderedProminent)
                .disabled(session.question == nil)
            }
            .padding()
        }
    }

    private func loadNext() async {
        loadingNext = true
        defer { loadingNext = false }
        let next = try? await bank.nextQuestion(
            level: profile.level, board: profile.board, tier: profile.tier,
            stats: stats.weaknessRanking(limit: 200), recentAttempts: [], lastSubtopics: []
        )
        if let next { session.load(question: next) }
    }
}
```

- [ ] **Step 2: Create `MainTabView.swift`**

```swift
import SwiftUI

struct MainTabView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        TabView {
            NavigationStack { HomeView(profile: profile) }
                .tabItem { Label("Home", systemImage: "doc.text.fill") }
            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            NavigationStack { UnlockTimerView() }
                .tabItem { Label("Unlock", systemImage: "lock.open.fill") }
            NavigationStack { SettingsView(profile: profile) }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tabViewStyle(.tabBarOnly)
        .toolbarBackground(.regularMaterial, for: .tabBar)
    }
}
```

- [ ] **Step 3: Reskin `UnlockTimerView` to Liquid Glass**

The view is inherited from the GoalScroll1 fork at `MathScroll/Views/Home/UnlockTimerView.swift`. Replace its outermost background container with `GlassCard` and remove any reference to the deleted `GradientBackgroundView`. Concretely, open the file and:

```swift
// Before (GoalScroll1 pattern):
//   GradientBackgroundView { VStack { /* timer ui */ } }
// After:
GlassCard {
    VStack(spacing: Theme.pad) {
        // Keep the existing timer/balance/unlock-button content unchanged.
    }
}
.padding()
```

Verify nothing else in the file imports the deleted `GradientBackgroundView`.

- [ ] **Step 4: Build, verify**

- [ ] **Step 5: Commit**

```bash
git add MathScroll/Views/Home/HomeView.swift MathScroll/Views/Home/MainTabView.swift MathScroll/Views/Home/UnlockTimerView.swift
git commit -m "feat: Home, main tab bar, and reskinned UnlockTimerView in Liquid Glass"
```

---

### Task 28: Wire the full attempt loop in Home

**Files:**
- Modify: `MathScroll/Views/Home/HomeView.swift`

- [ ] **Step 1: Add submission, marking, and result navigation**

Replace the `NavigationLink("Submit answer"...)` block with:

```swift
@State private var submittedImage: Data?
@State private var showingResult = false
@Environment(MarkingStore.self) private var marking

NavigationLink {
    SubmitAnswerView { data in
        submittedImage = data
        Task { await submit(data: data) }
        showingResult = true
    }
} label: { Text("Submit answer") }
.buttonStyle(.borderedProminent)
.navigationDestination(isPresented: $showingResult) {
    if case .result(let r) = marking.state {
        ResultView(result: r, earnedMinutes: r.totalAwarded) {
            Task { await loadNext() }
            showingResult = false
        }
    } else if case .loading = marking.state {
        ProgressView("Marking…")
    } else {
        Text("Marking failed")
    }
}
```

And add the submit helper:

```swift
private func submit(data: Data) async {
    guard let q = session.question else { return }
    session.attachWorking(image: data)
    session.markSubmitted()
    await marking.mark(question: q, studentImage: data)
    if case .result(let r) = marking.state {
        let attempt = QuestionAttempt(
            questionId: q.id, imageData: data,
            marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
            criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
            skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
            secondsSpent: session.secondsSpent, markingMode: .ai
        )
        modelContext.insert(attempt)
        try? modelContext.save()
        stats.apply(attempt: attempt, totalMarks: r.totalPossible)
        minutes.earn(minutes: r.totalAwarded)
        profile.freeQuestionUsed = true
        try? modelContext.save()
        session.markCompleted()
    }
}

@Environment(\.modelContext) private var modelContext
```

- [ ] **Step 2: Build, verify**

- [ ] **Step 3: Manually run through one full attempt loop on simulator with a stubbed marking transport (set `MarkingService` to use a stub that returns a fixed `MarkingResult` for dev builds)**

- [ ] **Step 4: Commit**

```bash
git add MathScroll/Views/Home/HomeView.swift
git commit -m "feat: wire submit→mark→result→next loop in HomeView"
```

---

### Task 29: Stats view

**Files:**
- Create: `MathScroll/Views/Stats/StatsView.swift`

- [ ] **Step 1: Implement**

```swift
import SwiftUI
import Charts

struct StatsView: View {
    @Environment(StatsStore.self) private var stats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.padLarge) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top weaknesses").font(.mathBody.weight(.semibold))
                        ForEach(stats.weaknessRanking(limit: 5), id: \.compositeKey) { s in
                            HStack {
                                Text(s.tag.replacingOccurrences(of: "_", with: " ").capitalized)
                                Spacer()
                                Text("\(Int(s.recencyWeightedPct))%").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle("Stats")
    }
}
```

- [ ] **Step 2: Build, verify**

- [ ] **Step 3: Commit**

```bash
git add MathScroll/Views/Stats/StatsView.swift
git commit -m "feat: Stats view with weakness ranking"
```

---

### Task 30: Settings view (rebuilt)

**Files:**
- Modify: `MathScroll/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Replace the file**

```swift
import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("Exam") {
                Picker("Level", selection: $profile.level) {
                    ForEach(ExamLevel.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                Picker("Board", selection: $profile.board) {
                    ForEach(ExamBoard.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                if profile.level == .gcse {
                    Picker("Tier", selection: Binding(
                        get: { profile.tier ?? .higher },
                        set: { profile.tier = $0 }
                    )) {
                        ForEach(Tier.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }
            }
            Section("Limits") {
                Stepper("Daily cap: \(profile.dailyCapMinutes) min",
                        value: $profile.dailyCapMinutes, in: 30...240, step: 15)
            }
            Section("Subscription") {
                if let e = profile.entitlement, e.isActive {
                    Text("Active: \(e.productId)")
                    Text("Renews \(e.expiresAt.formatted())").foregroundStyle(.secondary)
                } else {
                    Text("No active subscription")
                }
                Button("Restore purchases") { Task { await paywall.restore() } }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .onChange(of: profile.dailyCapMinutes) { try? context.save() }
        .onChange(of: profile.level) { try? context.save() }
        .onChange(of: profile.board) { try? context.save() }
    }
}
```

- [ ] **Step 2: Build, verify**

- [ ] **Step 3: Commit**

```bash
git add MathScroll/Views/Settings/SettingsView.swift
git commit -m "feat: Settings rebuilt — exam config, daily cap, subscription"
```

---

### Task 31: RootView routing

**Files:**
- Modify: `MathScroll/Views/RootView.swift`
- Modify: `MathScroll/MathScrollApp.swift`

- [ ] **Step 1: Replace `RootView.swift`**

```swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            switch appState.route {
            case .onboarding:
                OnboardingContainerView(profile: profileOrCreate())
            case .freeQuestion, .home:
                MainTabView(profile: profileOrCreate())
            case .paywall:
                PaywallView()
            case .postPaywallDiagnostic:
                DiagnosticView(profile: profileOrCreate()) {
                    profileOrCreate().onboardingDone = true
                    try? context.save()
                }
            }
        }
        .onAppear { appState.profile = profileOrCreate() }
    }

    private func profileOrCreate() -> UserProfile {
        if let p = profiles.first { return p }
        let p = UserProfile()
        context.insert(p)
        try? context.save()
        return p
    }
}
```

- [ ] **Step 2: Replace `MathScrollApp.swift` with full container injection**

```swift
import SwiftUI
import SwiftData

@main
struct MathScrollApp: App {
    let container: ModelContainer
    let appState = AppState()
    let bank: QuestionBankStore
    let session = SessionStore()
    let marking: MarkingStore
    let minutes: MinutesStore
    let stats: StatsStore
    let paywall: PaywallStore

    init() {
        do {
            container = try ModelContainer(
                for: UserProfile.self, QuestionAttempt.self, SkillStat.self, MinutesLedger.self
            )
        } catch { fatalError("ModelContainer: \(error)") }

        let supabase = SupabaseManager.shared.client
        let bankSvc = QuestionBankService(transport: SupabaseBankTransport(client: supabase))
        bank = QuestionBankStore(service: bankSvc, recommender: QuestionRecommender(rng: SystemRandomNumberGenerator()))
        marking = MarkingStore(service: MarkingService(transport: EdgeFunctionMarkingTransport(client: supabase)))
        let context = ModelContext(container)
        stats = StatsStore(context: context)
        minutes = MinutesStore(context: context, dailyCapMinutes: 120)
        paywall = PaywallStore(entitlements: EntitlementsService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(bank)
                .environment(session)
                .environment(marking)
                .environment(minutes)
                .environment(stats)
                .environment(paywall)
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 3: Build and run on simulator; verify the route flips correctly when `freeQuestionUsed` toggles**

- [ ] **Step 4: Commit**

```bash
git add MathScroll/Views/RootView.swift MathScroll/MathScrollApp.swift
git commit -m "feat: RootView routing and full app container wiring"
```

---

### Task 32: Sync attempts and skill_stats to Supabase

**Files:**
- Modify: `MathScroll/Services/SyncManager.swift`

- [ ] **Step 1: Add sync hooks**

Append the following methods to `SyncManager`:

```swift
extension SyncManager {
    func push(attempt: QuestionAttempt, userId: UUID) async throws {
        struct Row: Encodable {
            let id: String; let user_id: String; let question_id: String; let submitted_at: String
            let marks_awarded: Int; let total_marks: Int; let criterion_results: [CriterionResult]
            let skills_correct: [String]; let skills_incorrect: [String]
            let improvement_tip: String; let seconds_spent: Int; let marking_mode: String
        }
        let iso = ISO8601DateFormatter().string(from: attempt.submittedAt)
        let row = Row(
            id: attempt.id.uuidString, user_id: userId.uuidString, question_id: attempt.questionId,
            submitted_at: iso, marks_awarded: attempt.marksAwarded, total_marks: attempt.totalMarks,
            criterion_results: attempt.criterionResults, skills_correct: attempt.skillsCorrect,
            skills_incorrect: attempt.skillsIncorrect, improvement_tip: attempt.improvementTip,
            seconds_spent: attempt.secondsSpent, marking_mode: attempt.markingMode.rawValue
        )
        try await SupabaseManager.shared.client.from("attempts").insert(row).execute()
    }

    func push(skillStat: SkillStat, userId: UUID) async throws {
        struct Row: Encodable {
            let user_id: String; let tag: String; let kind: String
            let attempts_count: Int; let marks_scored: Int; let marks_possible: Int
            let recency_weighted_pct: Double; let last_attempted_at: String
        }
        let row = Row(
            user_id: userId.uuidString, tag: skillStat.tag, kind: skillStat.kindRaw,
            attempts_count: skillStat.attemptsCount, marks_scored: skillStat.marksScored,
            marks_possible: skillStat.marksPossible,
            recency_weighted_pct: skillStat.recencyWeightedPct,
            last_attempted_at: ISO8601DateFormatter().string(from: skillStat.lastAttemptedAt)
        )
        try await SupabaseManager.shared.client.from("skill_stats").upsert(row).execute()
    }
}
```

- [ ] **Step 2: Call `push(attempt:)` and `push(skillStat:)` from `HomeView.submit(data:)` after `stats.apply(...)` succeeds**

In `HomeView.swift`'s `submit` method, after `stats.apply(...)`:

```swift
if let userId = SupabaseManager.shared.currentUserId {
    try? await SyncManager.shared.push(attempt: attempt, userId: userId)
    for s in stats.weaknessRanking(limit: 200) {
        try? await SyncManager.shared.push(skillStat: s, userId: userId)
    }
}
```

- [ ] **Step 3: Build, verify**

- [ ] **Step 4: Commit**

```bash
git add MathScroll/Services/SyncManager.swift MathScroll/Views/Home/HomeView.swift
git commit -m "feat: sync attempts and skill_stats to Supabase after marking"
```

---

### Task 33: Weekly digest service + view + Sunday notification

**Files:**
- Create: `MathScroll/Services/WeeklyDigestService.swift`
- Modify: `MathScroll/Services/NotificationManager.swift`
- Create: `MathScroll/Views/Home/WeeklyDigestView.swift`
- Test: `MathScrollTests/WeeklyDigestServiceTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MathScroll

final class WeeklyDigestServiceTests: XCTestCase {
    func testTopThreeWeakSkillsFromAttempts() {
        let s1 = SkillStat(tag: "a", kind: .skill); s1.attemptsCount = 5; s1.recencyWeightedPct = 30
        let s2 = SkillStat(tag: "b", kind: .skill); s2.attemptsCount = 5; s2.recencyWeightedPct = 40
        let s3 = SkillStat(tag: "c", kind: .skill); s3.attemptsCount = 5; s3.recencyWeightedPct = 50
        let s4 = SkillStat(tag: "d", kind: .skill); s4.attemptsCount = 5; s4.recencyWeightedPct = 80
        let svc = WeeklyDigestService()
        let top = svc.topWeak(stats: [s4, s3, s2, s1], limit: 3)
        XCTAssertEqual(top.map(\.tag), ["a", "b", "c"])
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the service**

```swift
import Foundation

struct WeeklyDigestService {
    func topWeak(stats: [SkillStat], limit: Int) -> [SkillStat] {
        Array(stats.sorted { $0.recencyWeightedPct < $1.recencyWeightedPct }.prefix(limit))
    }
}
```

- [ ] **Step 4: Modify `NotificationManager` to schedule Sunday 19:00 local notification**

Append:

```swift
extension NotificationManager {
    func scheduleWeeklyDigest() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Your weekly maths digest"
        content.body = "See your top 3 weaknesses and recommended practice."
        var date = DateComponents()
        date.weekday = 1   // Sunday
        date.hour = 19
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: "weekly_digest", content: content, trigger: trigger)
        center.add(req)
    }
}
```

- [ ] **Step 5: Create `WeeklyDigestView.swift`**

```swift
import SwiftUI

struct WeeklyDigestView: View {
    @Environment(StatsStore.self) private var stats
    private let service = WeeklyDigestService()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.padLarge) {
                Text("Top 3 to focus on this week").font(.mathTitle)
                ForEach(service.topWeak(stats: stats.weaknessRanking(limit: 50), limit: 3), id: \.compositeKey) { s in
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text(s.tag.replacingOccurrences(of: "_", with: " ").capitalized).font(.mathBody.weight(.semibold))
                            Text("\(Int(s.recencyWeightedPct))% recent accuracy").font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding()
        }
        .navigationTitle("Weekly digest")
    }
}
```

- [ ] **Step 6: Run tests, verify pass**

- [ ] **Step 7: Commit**

```bash
git add MathScroll/Services/WeeklyDigestService.swift MathScroll/Services/NotificationManager.swift MathScroll/Views/Home/WeeklyDigestView.swift MathScrollTests/WeeklyDigestServiceTests.swift
git commit -m "feat: weekly digest service, view, and Sunday notification"
```

---

### Task 34: Manual fixture set for end-to-end verification

**Files:**
- Create: `MathScrollTests/Fixtures/questions.json`
- Create: `MathScrollTests/Fixtures/working-photos/01-correct.jpg` … `10-illegible.jpg`
- Create: `MathScrollTests/EndToEndIntegrationTests.swift`

- [ ] **Step 1: Add 10 sample questions to `questions.json`**

Use a real subset of past papers; minimum fields: `id`, `level`, `board`, `tier`, `paper_year`, `paper_code`, `question_number`, `question_image_url`, `mark_scheme_image_url`, `total_marks`, `subtopic_tags`, `skill_tags`, `difficulty`. Cover at least: 2× easy, 4× medium, 4× hard; at least 2 per board.

- [ ] **Step 2: Capture 10 working photos** spanning all-correct, partial-credit, all-wrong, and illegible cases.

- [ ] **Step 3: Write `EndToEndIntegrationTests.swift`**

```swift
import XCTest
import SwiftData
@testable import MathScroll

@MainActor
final class EndToEndIntegrationTests: XCTestCase {
    func testFullAttemptUpdatesStatsAndMinutes() async throws {
        let container = try ModelContainer(
            for: UserProfile.self, QuestionAttempt.self, SkillStat.self, MinutesLedger.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile); try context.save()

        let q = Question.fixture(id: "q-1", level: .gcse, board: .edexcel)
        let imageData = Data([0x01])
        let stubResult = MarkingResult(
            totalAwarded: 3, totalPossible: 4,
            criteria: [CriterionResult(criterionId: "M1", awarded: 1, max: 1, rationale: "ok")],
            skillsCorrect: ["substitute"], skillsIncorrect: ["simplify"],
            improvementTip: "rationalise"
        )
        let stub = StubMarkingTransport(rawResponses: [(try? JSONEncoder().encode(stubResult)) ?? Data()])
        let svc = MarkingService(transport: stub)
        let store = MarkingStore(service: svc)
        await store.mark(question: q, studentImage: imageData)
        guard case .result(let r) = store.state else { return XCTFail() }

        let attempt = QuestionAttempt(
            questionId: q.id, imageData: imageData,
            marksAwarded: r.totalAwarded, totalMarks: r.totalPossible,
            criterionResults: r.criteria, skillsCorrect: r.skillsCorrect,
            skillsIncorrect: r.skillsIncorrect, improvementTip: r.improvementTip,
            secondsSpent: 60, markingMode: .ai
        )
        context.insert(attempt); try context.save()

        let stats = StatsStore(context: context)
        stats.apply(attempt: attempt, totalMarks: r.totalPossible)
        XCTAssertGreaterThan(stats.weaknessRanking(limit: 5).count, 0)

        let minutes = MinutesStore(context: context, dailyCapMinutes: 120)
        minutes.earn(minutes: r.totalAwarded)
        XCTAssertEqual(minutes.balance, 3)
    }
}
```

- [ ] **Step 4: Run all tests, verify pass**

```bash
xcodebuild test -project MathScroll.xcodeproj -scheme MathScroll \
  -destination 'platform=iOS Simulator,name=iPhone 16' | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add MathScrollTests/Fixtures MathScrollTests/EndToEndIntegrationTests.swift
git commit -m "test: end-to-end integration test + 10-question fixture set"
```

---

### Task 35: Final verification pass

**Files:**
- (no code — verification)

- [ ] **Step 1: Walk all flows on a simulator**

  - Cold start → onboarding (level / board / tier / cap / apps).
  - Free question → photo → mark (use stubbed marking in dev) → result → minutes update.
  - Paywall appears.
  - Mock-purchase via Xcode StoreKit test config → diagnostic → home.
  - Stats screen shows weakness ranking after 3 attempts.
  - Settings: change board, daily cap, restore purchases.
  - Force a malformed marking response → self-mark fallback UI appears.

- [ ] **Step 2: Confirm no `Goal`, `CompletionRecord`, `microHabit`, or `proof` symbols remain**

```bash
grep -rn "Goal\b\|CompletionRecord\|microHabit\|ProofItem" MathScroll/ MathScrollTests/ || echo "clean"
# Expected: clean.
```

- [ ] **Step 3: Run full test suite**

```bash
xcodebuild test -project MathScroll.xcodeproj -scheme MathScroll \
  -destination 'platform=iOS Simulator,name=iPhone 16' | tail -30
# Expected: all tests pass.
```

- [ ] **Step 4: Tag the v1 candidate**

```bash
git tag v1.0-rc.1
```

---

## Out of scope (do not attempt in this plan)

- The PDF ingestion pipeline that populates the Supabase `questions` table — separate spec.
- Family-shared subscriptions.
- Web companion.
- Subjects beyond Maths.
- Offline marking.
