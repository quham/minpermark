# MathScroll

GCSE / AS / A-Level Maths revision iOS app.

The student photographs handwritten working on real past-paper questions; Gemini Vision marks against the official scheme; marks become unlocked minutes via Apple Family Controls. Subtopic + skill weakness model drives recommendations. iOS 26 Liquid Glass UI. Paywalled after one free question via StoreKit 2.

## Status

Forked from GoalScroll1 on 2026-04-26. Implementation in progress on branch `feat/mathscroll-app`.

## Spec & plan

- Spec: `docs/superpowers/specs/2026-04-26-mathscroll-design.md`
- Plan: `docs/superpowers/plans/2026-04-27-mathscroll-app.md`

## Outstanding follow-ups (before TestFlight)

- Apply for Family Controls entitlement against new bundle id `com.mathscroll.app`.
- Set up StoreKit products in App Store Connect (`mathscroll.weekly`, `mathscroll.monthly`, `mathscroll.annual`).
- Build and run the question-bank ingestion pipeline (separate spec) to populate Supabase `questions` table.
- Replace the video-recorder `CameraView` adapter with a still-photo capture, OR retitle UI from "photo" → "record".
- Verify the auth flow — auth views were removed during cleanup; if anonymous Supabase usage isn't enough, restore.
- Open the project in Xcode on macOS and add the `MathScrollTests/` folder to the test target.
- Run the full test suite on Mac.

## Tech

iOS 26+, Swift 5.10, SwiftUI, SwiftData, Supabase, StoreKit 2, FamilyControls.
