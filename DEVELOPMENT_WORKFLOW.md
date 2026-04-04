# Treehole Development Workflow Guide

## Core Principle
**MVP First** — Build the smallest working version, verify it compiles and runs, then iterate.

## Compilation Verification (Mandatory)

After every code change, run:
```bash
cd /Users/jimmychen/Treehole/Treehole
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20
```

**Rules:**
- Never move to the next feature until the current one compiles
- Fix errors immediately — don't accumulate technical debt
- Zero warnings policy for new code

## Architecture

- **Pattern:** MVVM with @Observable (not ObservableObject)
- **Persistence:** SwiftData (@Model classes)
- **Navigation:** TabView + NavigationStack
- **Design:** iOS 26 Liquid Glass + warm macaroon palette
- **Concurrency:** Swift 6 strict (MainActor isolation)

## Current State: MVP (Phase 1) Complete

### What's Built (22 files)
| Layer | Files | Description |
|-------|-------|-------------|
| Models (4) | CloudPost, Pet, Plant, JournalEntry | SwiftData @Model classes |
| ViewModels (3) | AppState, CloudPostVM, PetVM | @Observable business logic |
| Views (11) | Onboarding, Cloud (3), Pet (2), Plant (2), Journal, Settings, Auth | Full UI |
| Theme (1) | TreeholeTheme | Design system |
| Components (1) | SharedComponents | MoodPicker, StatBadge, ProgressBar, EmptyState |
| Core (2) | TreeholeApp, ContentView | App entry + tab navigation |

### Features Working
- 4-page onboarding with privacy/alias explanation
- Cloud posts: create, view, delete with NPC template replies
- Virtual pet: display with mood-based animations, feeding
- Plant garden: single plant, watering, growth stages
- Journal: entries with mood tags, daily prompts, stats
- Settings: account, alias explanation, appearance
- Login prompt with Apple Sign-In
- Anonymous alias system with 7-day rotation + notification

## Phase 2 Roadmap
1. Economy system (food currency, decoration tokens)
2. Daily tasks & check-in rewards
3. Pet decorations & home themes
4. Shop view
5. Multiple plants
6. Full bilingual localization (String Catalog)
7. Enhanced animations

## Phase 3 Roadmap
1. Weekly challenges
2. Login streaks
3. Advanced pet interactions (energy, level, experience)
4. Translation service for posts
5. Push notification reminders
6. Dark mode polish

## File Structure
```
Treehole/Treehole/Treehole/
├── TreeholeApp.swift          # @main entry, SwiftData container
├── ContentView.swift          # Onboarding gate + TabView
├── Assets.xcassets/           # App icons, accent color
├── Models/                    # SwiftData @Model classes
├── ViewModels/                # @Observable business logic
├── Views/
│   ├── Onboarding/            # 4-page onboarding flow
│   ├── Cloud/                 # Post list, creation, detail
│   ├── Pet/                   # Pet home, cartoon cat art
│   ├── Plant/                 # Garden, plant visual art
│   ├── Journal/               # Entry list, editor, prompts
│   ├── Settings/              # Settings + alias explanation
│   └── Auth/                  # Login prompt
├── Theme/                     # Design system (colors, spacing)
└── Components/                # Reusable UI components
```

## Key Technical Notes
- Xcode project uses objectVersion 77 (auto-discovers files)
- No need to edit project.pbxproj — just place files in directories
- Bundle ID: com.Toki.Treehole
- Deployment target: iOS 26
- SwiftData models use raw string properties for enums (e.g., moodTagRaw)
- Backup of Milestone 2 code: `backup/milestone2-complete` branch
