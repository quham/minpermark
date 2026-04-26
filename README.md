# GoalScroll

A habit tracking iOS app that helps users set goals, define micro-habits, choose triggers, and earn "unlocked minutes" by completing habits.

## Features

- **Goal Setting**: Create meaningful goals with guided onboarding
- **Micro-Habits**: Break down goals into tiny, actionable habits
- **Smart Triggers**: Set time-based, action-based, or location-based triggers
- **Proof System**: Verify habit completion with photos, screenshots, or reflections
- **Minutes Economy**: Earn minutes by completing habits, use them to unlock app access
- **AI Verification**: Gemini Flash integration for smart proof verification
- **Streaks & Stats**: Track your progress with daily streaks and lifetime stats
- **Focus Mode**: Soft app blocking to help you stay focused

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
GoalScroll/
├── GoalScrollApp.swift          # App entry point
├── ContentView.swift            # Main navigation controller
├── Models/
│   ├── Goal.swift               # Goal model with triggers and proof methods
│   ├── CompletionRecord.swift   # Habit completion records
│   ├── ProofItem.swift          # Proof attachments
│   └── UserStats.swift          # User statistics and streaks
├── Views/
│   ├── Components/              # Reusable UI components
│   │   ├── GradientBackgroundView.swift
│   │   ├── PrimaryButton.swift
│   │   ├── InputField.swift
│   │   ├── GoalCardView.swift
│   │   ├── ProgressPanelView.swift
│   │   └── ChipView.swift
│   ├── Onboarding/              # 6-screen onboarding flow
│   │   ├── OnboardingContainerView.swift
│   │   ├── EnterGoalView.swift
│   │   ├── DefineMicrohabitView.swift
│   │   ├── ChooseTriggerView.swift
│   │   ├── ProofSelectionView.swift
│   │   ├── WhyImportanceView.swift
│   │   └── SummaryView.swift
│   ├── Home/                    # Main app screens
│   │   ├── HomeView.swift
│   │   ├── AddGoalView.swift
│   │   └── UnlockTimerView.swift
│   ├── Proof/                   # Proof capture flow
│   │   ├── ProofCaptureView.swift
│   │   └── CameraView.swift
│   └── Settings/                # Settings screens
│       └── SettingsView.swift
├── Stores/                      # State management
│   ├── AppState.swift
│   ├── GoalsStore.swift
│   └── StatsStore.swift
├── Services/                    # External services
│   ├── GeminiService.swift      # AI integration
│   ├── NotificationManager.swift
│   └── ScreenTimeManager.swift
└── Utilities/
    ├── Theme.swift              # Colors, typography, spacing
    ├── Extensions.swift
    └── Constants.swift
```

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd GoalScroll1
   ```

2. **Open in Xcode**
   - Open `GoalScroll.xcodeproj` in Xcode 15+
   - Xcode will automatically add all Swift files to the project

3. **Configure Gemini API (Optional)**
   - Get an API key from [Google AI Studio](https://makersuite.google.com/)
   - Add `GEMINI_API_KEY` to your environment variables or update `GeminiService.swift`

4. **Build and Run**
   - Select a simulator or device (iOS 17+)
   - Press Cmd+R to build and run

## Architecture

### Data Layer
- **SwiftData** for persistence
- Models are `@Model` classes with relationships

### State Management
- **AppState**: Global app state (onboarding, active sheets)
- **GoalsStore**: CRUD operations for goals
- **StatsStore**: User statistics and streak tracking

### Services
- **GeminiService**: AI-powered suggestions and verification
- **NotificationManager**: Local notification scheduling
- **ScreenTimeManager**: Screen Time API integration (requires entitlement)

## Key Flows

### Onboarding
1. Enter Goal → 2. Define Microhabit → 3. Choose Trigger → 4. Select Proof → 5. Set Importance → 6. Summary

### Daily Flow
1. View Today's Goals
2. Complete habits ("I did this")
3. Submit proof if required
4. Earn minutes
5. Unlock apps with earned minutes

## Customization

### Colors
Edit `Theme.swift` to customize the color palette:
```swift
static let primary = Color(hex: "4A7BF7")
static let gradientStart = Color(hex: "E8D5E7")
```

### Validation Rules
Edit `Constants.swift` to adjust validation:
```swift
static let minGoalLength = 3
static let maxGoalLength = 80
```

## Screen Time Integration

For full app blocking functionality:
1. Apply for Family Controls entitlement from Apple
2. Enable the capability in Xcode
3. The `ScreenTimeManager` will automatically detect availability

Without the entitlement, the app uses "soft blocking" (in-app reminders and timers).

## Privacy

- All data stored locally on device
- Proof images processed by Gemini are not stored
- No personal data sent to servers
- Camera and photo library access required only for proof capture

## License

MIT License
