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

Preferred: the Makefile at the repo root wraps everything.

```bash
cd /Users/jimmychen/Treehole
make test         # Unit tests only (~15s) — default for everyday work
make test-fast    # Unit tests, no rebuild (~5s)
make test-full    # Everything: unit + UI tests (~3min)
make test-ui      # UI tests only (~2.5min)
make build        # Just compile, no tests (~30s)
make archive      # Release archive (for TestFlight)

# Single test class / method:
make test ONLY=AnalyticsServiceTests
make test ONLY=AnalyticsServiceTests/testTrackReturnsSynchronously
```

Raw xcodebuild equivalent:

```bash
# Run all tests (unit + UI)
cd /Users/jimmychen/Treehole/Treehole
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30

# Run only unit tests
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -only-testing:TreeholeTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed)" | tail -30
```

**Current test count: 332 total — 310 unit tests (Swift Testing, `@Test`/`#expect`) + 22 UI tests (XCTest)**

New features must ship with accompanying tests before merging.

---

## Architecture

| Concern | Approach |
|---|---|
| Pattern | MVVM with @Observable (not ObservableObject) |
| Persistence | SwiftData (@Model classes) + CloudKit sync |
| Social backend | Supabase (PostgreSQL + Edge Functions) |
| AI | MiniMax M2.7-highspeed via Edge Functions (moderation, NPC replies, pet chat, pet TTS, journal summaries) |
| Auth | Apple Sign-In (ASAuthorizationController) + Guest (device_id) |
| Biometrics | LocalAuthentication (FaceID / TouchID) |
| Keychain | Security framework (passcode, never in SwiftData) |
| Navigation | TabView (5 tabs) + NavigationStack |
| Design | iOS 26 Liquid Glass + warm macaroon palette |
| Concurrency | Swift 6 strict (MainActor isolation, async/await) |
| Localization | L10n.t() throughout, String Catalog, runtime language switch |

---

## Current State: 54 Swift Files

| Layer | Files | Description |
|---|---|---|
| Models (9) | ChatMessage, ChatMode, CloudPost, Economy (+DailyTask), JournalEntry, JournalSummary, Pet, Plant, WeeklyChallenge | SwiftData @Model classes + enums |
| ViewModels (5) | AppState, CloudPostViewModel, PetViewModel, EconomyViewModel, PostMigrationCoordinator | @Observable business logic + migration retry |
| Views (19) | Onboarding, Cloud (4), Pet (4), Plant (2), Journal (3), Shop, Settings (2), Auth, PrivacyLockView | Full UI |
| Services (7) | SupabaseService, PetChatService, PetVoiceService, WeatherService, LocationService, AnalyticsService, AudioRecorder | Network / device services |
| Utilities (8) | L10n, NotificationService, PhotoStorage, PrivacyLockManager, AudioStorage, WeekAnchor, JournalSearch, JournalTranscription | Shared helpers |
| Theme (1) | TreeholeTheme | Design system (colors, spacing, typography) |
| Components (3) | SharedComponents, AudioPlayerView, CameraPicker | MoodPicker (pills/slider), StatBadge, audio player, camera |
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
- iCloud ubiquity container for journal photos (up to 10 per entry via PhotoStorage)
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
- Initial test suite (unit + UI)

---

## Phase 4 — CURRENT

**Shipped so far:** journal redesign (floating toolbar editor, voice notes + auto-transcription, search, edit, location + Open-Meteo weather, two dates, iPad adaptive split view), 16-mood system with pills / 1D pleasantness slider, real Year mood statistics view, per-entry + Monday-anchored weekly AI summaries (`summarize-journal`), pet chat with TTS voice selection (`pet-chat` / `pet-tts`), no-repeat cloud grabbing (`grabbed_posts`), anonymous analytics (`analytics_events`), account-deletion hardening (abort if the cloud wipe fails; comments/reactions wiped too), privacy-lock re-lock on backgrounding, daily-login-bonus persistence + CloudKit Economy/DailyTask dedupe, debug panel now Debug-builds-only.

**Remaining:**
1. **UI Polish** — Implement Figma design specs across all screens; refine Liquid Glass usage; animation pass on pet, plant, and cloud transitions.
2. **Accessibility** — VoiceOver labels on all interactive elements, Dynamic Type support throughout, Reduce Motion fallbacks for all animations.
3. **Performance** — Profile SwiftData query costs, reduce main-thread work in list views, optimize CloudKit sync frequency.
4. **AI Enhancements** — Improved NPC personas, mood-aware reply generation.
5. **Backend TODO** — Review and run `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` in the Supabase SQL editor, then switch the client's deletion flow to `rpc/delete_my_data`.

---

## Phase 5 — PLANNED

1. **App Store prep** — Privacy manifest, App Store screenshots (EN + ZH), age rating, app review notes.
2. **TestFlight beta** — External tester invites, crash reporting (MetricKit or Crashlytics).
3. **IAP** — StoreKit 2 implementation for decoration packs and subscription tier.

---

## File Structure

```
Treehole/Treehole/                          (54 Swift files)
├── TreeholeApp.swift                        # @main entry, SwiftData + CloudKit container (moves store aside as Backup-* on unrecoverable failure — never auto-deletes)
├── ContentView.swift                        # Onboarding gate + TabView (5 tabs)
├── InfoPlist.xcstrings                      # Localized iOS permission dialogs (en + zh-Hans)
├── Models/                                  # 9 files — SwiftData @Model classes + enums
│   ├── ChatMessage.swift                    # Pet chat history
│   ├── ChatMode.swift                       # Pet chat modes: basic / premium (enum)
│   ├── CloudPost.swift                      # + MoodTag (16 cases, valence/arousal coordinates)
│   ├── Economy.swift                        # Economy + DailyTask
│   ├── JournalEntry.swift
│   ├── JournalSummary.swift                 # AI weekly / per-entry summaries
│   ├── Pet.swift
│   ├── Plant.swift
│   └── WeeklyChallenge.swift
├── ViewModels/                              # 5 files
│   ├── AppState.swift
│   ├── CloudPostViewModel.swift
│   ├── EconomyViewModel.swift               # incl. CloudKit dedupe + daily/weekly resets
│   ├── PetViewModel.swift
│   └── PostMigrationCoordinator.swift       # Persisted retry for device→account post migration
├── Views/
│   ├── Onboarding/                          # 4-page onboarding flow
│   ├── Cloud/                               # 4 files: list, create, detail, My Clouds
│   ├── Pet/                                 # 4 files: home, cat art, chat, voice selector
│   ├── Plant/                               # 2 files: garden, plant visuals
│   ├── Journal/                             # 3 files: journal + editor, entry detail, mood stats
│   ├── Shop/                                # Economy & store
│   ├── Settings/                            # 2 files: main settings, debug panel (Debug builds only)
│   ├── Auth/                                # Apple Sign-In + guest flow
│   └── PrivacyLockView.swift                # Passcode gate & biometric unlock
├── Services/                                # 7 files
│   ├── AnalyticsService.swift               # Anonymous events → analytics_events
│   ├── AudioRecorder.swift                  # Voice notes, 5-min cap (capped takes kept & attached)
│   ├── LocationService.swift                # One-shot GPS fetch, 10s timeout
│   ├── PetChatService.swift                 # pet-chat Edge Function + scripted fallback
│   ├── PetVoiceService.swift                # pet-tts Edge Function + AVSpeech fallback
│   ├── SupabaseService.swift                # Supabase REST API + Edge Functions + RPCs
│   └── WeatherService.swift                 # Open-Meteo weather for journal entries
├── Utilities/                               # 8 files
│   ├── AudioStorage.swift                   # Voice-note file storage (local + iCloud)
│   ├── JournalSearch.swift                  # Entry filter (text/title/transcript/location)
│   ├── JournalTranscription.swift           # Apple Speech transcription pipeline
│   ├── L10n.swift                           # L10n.t() localization helper
│   ├── NotificationService.swift            # Local push notification scheduling
│   ├── PhotoStorage.swift                   # iCloud ubiquity container photo read/write
│   ├── PrivacyLockManager.swift             # Keychain passcode + LocalAuthentication
│   └── WeekAnchor.swift                     # Monday-anchored week math
├── Theme/
│   └── TreeholeTheme.swift                  # Design system: colors, spacing, typography
└── Components/                              # 3 files
    ├── AudioPlayerView.swift                # Voice-note playback UI
    ├── CameraPicker.swift                   # UIImagePickerController camera bridge
    └── SharedComponents.swift               # MoodPicker (pills/slider), StatBadge, etc.

TreeholeTests/                               # 310 unit tests (Swift Testing)
TreeholeUITests/                             # 22 UI tests (XCTest)
```

---

## Key Technical Notes

- Xcode project uses objectVersion 77 (auto-discovers files in directories).
- No need to edit `project.pbxproj` manually — just place Swift files in the correct folder.
- **Bundle ID:** `com.csquare04.Treehole`
- **Deployment target:** iOS 17.0 (built with Xcode 26 / iOS 26 SDK)
- **Swift version:** Swift 6 (strict concurrency enabled)
- SwiftData models use raw string properties for enums (e.g. `moodTagRaw`, `homeThemeRaw`, `speciesRaw`).
- All user-facing strings go through `L10n.t()` — never use hardcoded string literals in Views.
- Supabase project URL: `https://gjtiqwkhrepwhtoyjeix.supabase.co`
- CloudKit container: `iCloud.com.csquare04.Treehole`
- Required Xcode capabilities: iCloud (CloudKit + Documents), Push Notifications, Sign In with Apple, Keychain Sharing.
- Passcode is stored in Keychain only — never in SwiftData, never in Supabase.
- AI calls (moderation, NPC reply, pet chat, pet TTS, journal summaries) are always routed through Supabase Edge Functions (`moderate-post`, `generate-npc-reply`, `pet-chat`, `pet-tts`, `summarize-journal`), not called directly from the client.
- Pending server-side migration: `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` (adds `delete_my_data` RPC) — run in the Supabase SQL editor, then switch the client to `rpc/delete_my_data`.
