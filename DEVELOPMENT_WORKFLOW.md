# Treehole Development Workflow Guide

## Core Principles

- **MVP First** — Build the smallest working version, verify it compiles, then iterate.
- **Tests Required** — Every new feature MUST include tests. No exceptions.
- **L10n Required** — Every user-facing string MUST use `L10n.t()`. No hardcoded UI text.
- **Zero warnings** — New code must introduce no new compiler warnings.
- **Compile before commit** — Run the compilation check after every change.

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

**Current test count: 105 total — 84+ unit tests + 21 UI tests**

New features must ship with accompanying tests before merging.

---

## Architecture

| Concern | Approach |
|---|---|
| Pattern | MVVM with @Observable (not ObservableObject) |
| Persistence | SwiftData (@Model classes) + CloudKit sync |
| Social backend | Supabase (PostgreSQL + Edge Functions) |
| AI | MiniMax M2.7-highspeed (moderation + NPC replies via Edge Functions) |
| Auth | Apple Sign-In (ASAuthorizationController) + Guest (device_id) |
| Biometrics | LocalAuthentication (FaceID / TouchID) |
| Keychain | Security framework (passcode, never in SwiftData) |
| Navigation | TabView (5 tabs) + NavigationStack |
| Design | iOS 26 Liquid Glass + warm macaroon palette |
| Concurrency | Swift 6 strict (MainActor isolation, async/await) |
| Localization | L10n.t() throughout, String Catalog, runtime language switch |

---

## Current State: 36 Swift Files

| Layer | Files | Description |
|---|---|---|
| Models (6) | CloudPost, Pet, Plant, JournalEntry, Economy, WeeklyChallenge | SwiftData @Model classes |
| ViewModels (4) | AppState, CloudPostViewModel, PetViewModel, EconomyViewModel | @Observable business logic |
| Views (17) | Onboarding (4pp), Cloud (4), Pet (2), Plant (2), Journal (3), Shop, Settings (2), Auth, PrivacyLock | Full UI |
| Services (1) | SupabaseService | Supabase REST API + Edge Functions |
| Utilities (4) | L10n, NotificationService, PhotoStorage, PrivacyLockManager | Shared services |
| Theme (1) | TreeholeTheme | Design system (colors, spacing, typography) |
| Components (1) | SharedComponents | MoodPicker, StatBadge, ProgressBar, EmptyState, etc. |
| Core (2) | TreeholeApp, ContentView | App entry + tab navigation |

---

## Phase 1 — COMPLETE

Core loop: 4-page onboarding, cloud posts with NPC replies, virtual pet (feed/pet/rest), single plant garden, journal with mood tags, settings.

---

## Phase 2 — COMPLETE

- Economy system: food, tokens, gems
- Daily tasks (4 types) and weekly challenges (4 types)
- Login streak tracking with tiered rewards
- Shop: buy food with tokens
- Multiple plants (5 species, 5 growth stages per species)
- Full bilingual localization (EN/ZH, String Catalog, L10n.t())
- Push notifications: feeding reminder (4h), watering reminder (24h), daily check-in (9 AM)
- Dark mode
- Pet enhancements: XP, levels, energy, mood animations, 4 unlockable themes

---

## Phase 3 — COMPLETE

- Apple Sign-In (ASAuthorizationAppleIDCredential, stable apple_user_id)
- Guest mode with device_id; device-to-account migration
- CloudKit sync for all SwiftData models
- iCloud ubiquity container for journal photos (up to 3 per entry via PhotoStorage)
- Privacy Lock: 4-digit Keychain passcode, FaceID/TouchID, independent lock for My Clouds and Journal
- Drift bottle reactions: breeze / hug / starlight with visual effects (unique per device per post)
- My Clouds management page (view and delete own posts)
- Comments on cloud posts
- Supabase social layer: cloud_posts, cloud_comments, cloud_reactions, npc_reply_templates, post_reaction_counts view
- MiniMax M2.7-highspeed AI content moderation (3-layer pipeline)
- MiniMax AI NPC reply generation via Edge Functions
- Mood statistics page: week / month / year view, mood distribution chart, streak tracking
- Journal entry detail view with photos
- Developer debug panel (5-tap version trigger): pet/plant/economy sliders, device info
- iCloud sync status page in Settings
- Test suite: 84+ unit tests + 21 UI tests

---

## Phase 4 — CURRENT

1. **UI Polish** — Implement Figma design specs across all screens; refine Liquid Glass usage; animation pass on pet, plant, and cloud transitions.
2. **Accessibility** — VoiceOver labels on all interactive elements, Dynamic Type support throughout, Reduce Motion fallbacks for all animations.
3. **Performance** — Profile SwiftData query costs, reduce main-thread work in list views, optimize CloudKit sync frequency.
4. **AI Enhancements** — Improved NPC personas, mood-aware reply generation, potential pet chat feature.

---

## Phase 5 — PLANNED

1. **App Store prep** — Privacy manifest, App Store screenshots (EN + ZH), age rating, app review notes.
2. **TestFlight beta** — External tester invites, crash reporting (MetricKit or Crashlytics).
3. **Analytics** — Opt-in, privacy-preserving funnel tracking (PostHog or Amplitude).
4. **IAP** — StoreKit 2 implementation for decoration packs and subscription tier.

---

## File Structure

```
Treehole/Treehole/                          (36 Swift files)
├── TreeholeApp.swift                        # @main entry, SwiftData + CloudKit container
├── ContentView.swift                        # Onboarding gate + TabView (5 tabs)
├── Models/                                  # 6 SwiftData @Model classes
│   ├── CloudPost.swift
│   ├── Pet.swift
│   ├── Plant.swift
│   ├── JournalEntry.swift
│   ├── Economy.swift
│   └── WeeklyChallenge.swift
├── ViewModels/                              # 4 @Observable classes
│   ├── AppState.swift
│   ├── CloudPostViewModel.swift
│   ├── PetViewModel.swift
│   └── EconomyViewModel.swift
├── Views/
│   ├── Onboarding/                          # 4-page onboarding flow
│   ├── Cloud/                               # 4 files: list, create, detail, My Clouds
│   ├── Pet/                                 # 2 files: pet home, interactions
│   ├── Plant/                               # 2 files: garden, plant detail
│   ├── Journal/                             # 3 files: list, editor, mood stats
│   ├── Shop/                                # Economy & store
│   ├── Settings/                            # 2 files: main settings, debug panel
│   ├── Auth/                                # Apple Sign-In + guest flow
│   └── PrivacyLock/                         # Passcode gate & biometric unlock
├── Services/
│   └── SupabaseService.swift                # Supabase REST API + Edge Functions
├── Utilities/
│   ├── L10n.swift                           # L10n.t() localization helper
│   ├── NotificationService.swift            # Local push notification scheduling
│   ├── PhotoStorage.swift                   # iCloud ubiquity container photo read/write
│   └── PrivacyLockManager.swift             # Keychain passcode + LocalAuthentication
├── Theme/
│   └── TreeholeTheme.swift                  # Design system: colors, spacing, typography
└── Components/
    └── SharedComponents.swift               # Reusable UI: MoodPicker, StatBadge, etc.

TreeholeTests/                               # 84+ unit tests
TreeholeUITests/                             # 21 UI tests
```

---

## Key Technical Notes

- Xcode project uses objectVersion 77 (auto-discovers files in directories).
- No need to edit `project.pbxproj` manually — just place Swift files in the correct folder.
- **Bundle ID:** `com.Toki.Treehole`
- **Deployment target:** iOS 26
- **Swift version:** Swift 6 (strict concurrency enabled)
- SwiftData models use raw string properties for enums (e.g. `moodTagRaw`, `themeRaw`, `speciesRaw`).
- All user-facing strings go through `L10n.t()` — never use hardcoded string literals in Views.
- Supabase project URL: `https://gjtiqwkhrepwhtoyjeix.supabase.co`
- CloudKit container: `iCloud.com.Toki.Treehole`
- Required Xcode capabilities: iCloud (CloudKit + Documents), Push Notifications, Sign In with Apple, Keychain Sharing.
- Passcode is stored in Keychain only — never in SwiftData, never in Supabase.
- AI calls (moderation, NPC reply) are always routed through Supabase Edge Functions, not called directly from the client.
