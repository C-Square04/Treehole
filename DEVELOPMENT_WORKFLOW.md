# Treehole Development Workflow Guide

## Core Principles

- **MVP First** — Build the smallest working version, verify it compiles, then iterate.
- **Tests Required** — Every new feature MUST include tests. No exceptions.
- **Zero warnings** — New code should introduce no new compiler warnings.

---

## Compilation Verification (Mandatory)

After every code change, run:

```bash
cd /Users/jimmychen/Treehole/Treehole
xcodebuild -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20
```

Rules:
- Never move to the next feature until the current one compiles.
- Fix errors immediately — don't accumulate technical debt.

---

## Test Commands

```bash
# Run all tests (unit + UI)
cd /Users/jimmychen/Treehole/Treehole
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30

# Run only unit tests
xcodebuild test -project Treehole.xcodeproj -scheme TreeholeTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed)" | tail -30
```

**Current test count: 83 total — 65 unit tests + 18 UI tests**

New features must ship with accompanying tests before merging.

---

## Architecture

| Concern | Approach |
|---|---|
| Pattern | MVVM with @Observable (not ObservableObject) |
| Persistence | SwiftData (@Model classes) |
| Navigation | TabView (5 tabs) + NavigationStack |
| Design | iOS 26 Liquid Glass + warm macaroon palette |
| Concurrency | Swift 6 strict (MainActor isolation) |

---

## Current State: 26 Swift Files

| Layer | Files | Description |
|---|---|---|
| Models (4) | CloudPost, Pet, Plant, JournalEntry | SwiftData @Model classes |
| ViewModels (4) | AppState, CloudPostVM, PetVM, ShopVM | @Observable business logic |
| Views (14) | Onboarding (4pp), Cloud (3), Pet (2), Garden (2), Journal (2), Shop, Settings | Full UI |
| Theme (1) | TreeholeTheme | Design system (colors, spacing, typography) |
| Components (1) | SharedComponents | MoodPicker, StatBadge, ProgressBar, EmptyState |
| Core (2) | TreeholeApp, ContentView | App entry + tab navigation |

---

## Phase 1 — COMPLETE

Core loop: 4-page onboarding, cloud posts with NPC replies, virtual pet, single plant garden, journal with mood tags, settings.

---

## Phase 2 — COMPLETE

- Economy system: food, tokens, gems
- Daily tasks (4 types) and weekly challenges (4 types)
- Login streak tracking with tiered rewards
- Shop: buy food with tokens
- Multiple plants (5 species, per-species growth stages)
- Full bilingual localization (EN/ZH, String Catalog)
- Push notifications: feeding, watering, daily check-in reminders
- Dark mode
- Pet enhancements: XP, levels, energy, unlockable themes
- Test suite: 65 unit tests + 18 UI tests

---

## Phase 3 Roadmap — NEXT

1. **UI Polish** — Implement Figma design specs, refine Liquid Glass usage, animation pass on pet and plant transitions.
2. **Accessibility** — VoiceOver labels, Dynamic Type support, Reduce Motion fallbacks.
3. **Performance** — Profile SwiftData query costs, reduce main-thread work in list views.

---

## Phase 4 Roadmap — PLANNED

1. **Backend** — Real cloud posts stored server-side (Supabase or Cloud Functions).
2. **Social features** — Real user replies, moderation pipeline (DeepSeek API).
3. **Accounts** — Sign in with Apple, cross-device SwiftData/CloudKit sync.

---

## Phase 5 Roadmap — PLANNED

1. **App Store prep** — Privacy manifest, App Store screenshots, age rating.
2. **TestFlight beta** — External tester invites, crash reporting (Crashlytics or MetricKit).
3. **Analytics** — Amplitude or PostHog for funnel tracking (opt-in only).

---

## File Structure

```
Treehole/Treehole/
├── TreeholeApp.swift          # @main entry, SwiftData container
├── ContentView.swift          # Onboarding gate + TabView (5 tabs)
├── Assets.xcassets/           # App icons, accent color
├── Models/                    # SwiftData @Model classes
├── ViewModels/                # @Observable business logic
├── Views/
│   ├── Onboarding/            # 4-page onboarding flow
│   ├── Cloud/                 # Post list, creation, detail
│   ├── Pet/                   # Pet home, interactions
│   ├── Garden/                # Multi-plant garden
│   ├── Journal/               # Entry list, editor, prompts
│   ├── Shop/                  # Economy & store
│   └── Settings/              # Settings + alias explanation
├── Theme/                     # Design system
└── Components/                # Reusable UI components

TreeholeTests/                 # 65 unit tests
TreeholeUITests/               # 18 UI tests
```

---

## Key Technical Notes

- Xcode project uses objectVersion 77 (auto-discovers files in directories).
- No need to edit `project.pbxproj` manually — just place Swift files in the right folder.
- Bundle ID: `com.Toki.Treehole`
- Deployment target: iOS 26
- SwiftData models use raw string properties for enums (e.g. `moodTagRaw`, `themeRaw`).
- Milestone 2 backup: `backup/milestone2-complete` branch.
