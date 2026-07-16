# Treehole — Design Document & PRD

> **Version:** Phase 4 In Progress (July 2026)
> **Authors:** Jimmy Chen & Kayli Cheung / Toki Studio

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Target Users](#2-target-users)
3. [Feature Specifications](#3-feature-specifications)
4. [Data Model](#4-data-model)
5. [AI Integration](#5-ai-integration)
6. [Privacy & Security Design](#6-privacy--security-design)
7. [Economy System Design](#7-economy-system-design)
8. [Architecture](#8-architecture)
9. [Monetization Plans](#9-monetization-plans)
10. [Roadmap](#10-roadmap)

---

## 1. Product Vision

**English:** Treehole is a safe, anonymous emotional outlet and gentle self-care companion for mobile users. Named after the old idea of whispering secrets into a tree hollow, the app lets people release feelings as anonymous "drift bottle clouds" that float in a shared sky. Alongside the social cloud layer, a virtual pet, multi-plant garden, and private journal create daily rituals of care and reflection. The entire experience is wrapped in warm iOS 26 Liquid Glass design and full English/Simplified Chinese bilingual support.

**中文：** Treehole（树洞）是一款安全、匿名的情绪出口与温柔自我关怀伴侣应用。名字源自"把秘密说进树洞"的古老意象——用户将心情化为匿名"漂流瓶云朵"飘向共享天空。除社交云层外，虚拟宠物、多种植物花园和私密日记共同构成每日关怀与反思的仪式。整体体验采用温暖的 iOS 26 Liquid Glass 设计，全程支持中英双语。

**Core pillars / 核心支柱:**
- Emotional release without identity exposure / 无身份暴露的情绪释放
- Gentle gamified care rituals / 温柔游戏化的日常仪式
- Long-term motivation through economy & progression / 经济与成长系统驱动长期留存
- Trust through transparent privacy design / 透明隐私设计建立信任

---

## 2. Target Users

**Primary / 核心用户:** Gen Z (18–28) experiencing workplace or campus stress, seeking anonymous venting and emotional companionship without social pressure.

**Secondary / 次级用户:** Casual simulation / light game players who enjoy virtual pet and plant cultivation mechanics.

**Accessibility requirements / 无障碍要求:**
- Dynamic Type support for all text
- VoiceOver labels on all interactive elements
- Reduce Motion fallbacks for all animations
- Sufficient color contrast (WCAG AA minimum)

**Privacy-sensitive users / 隐私敏感用户:** Users who need clear, plain-language explanations of how anonymity and data storage work — provided via the alias explanation screen in Settings and during Onboarding.

---

## 3. Feature Specifications

### 3.1 Drift Bottle Clouds (漂流瓶云朵)

**Concept:** Users post anonymous thoughts as floating cloud bubbles. Others can discover them by "grabbing a cloud" (random post), read, react, and receive AI NPC replies.

**Posting:**
- Text entry with mood tag selection
- 3-layer content moderation before publish:
  1. Client-side keyword filter (instant, no network)
  2. MiniMax M2.7-highspeed AI moderation via Supabase Edge Function `moderate-post`
  3. PostgreSQL trigger for server-side rule enforcement
- Post stored in Supabase `cloud_posts` with `apple_user_id` and `device_id`; display alias generated per session

**Discovery:**
- Cloud list view with floating bubble animations
- "Grab a cloud" button surfaces a random post the user hasn't seen
- Post detail shows content, reaction counts (breeze / hug / starlight), and NPC reply

**Reactions:**
- Three reaction types: breeze (微风), hug (拥抱), starlight (星光)
- Each device can react once per post per type (enforced via `cloud_reactions` unique constraint)
- Visual particle effects on reaction
- Counts shown via `post_reaction_counts` view

**Comments:**
- Stored in `cloud_comments` with post reference and device/user ID
- Shown in post detail view

**NPC Replies:**
- Generated via Supabase Edge Function `generate-npc-reply` using MiniMax M2.7-highspeed
- Templates stored in `npc_reply_templates` as fallback
- Replies are attributed to named NPC personas (e.g., wise cloud, warm cat)

**My Clouds:**
- Management page listing the user's own posts
- Delete option removes from Supabase

**Reporting & hiding (post-publish UGC moderation, App Review guideline 1.2):**
- On any stranger's cloud (never on the user's own posts), an ellipsis menu offers two actions:
  - **Report Cloud** — a confirmation dialog with four reason choices (`harmful` / `spam` / `hateful` / `other`, defined by `CloudReportReason`). The chosen reason is sent best-effort to the `post_reports` table via `SupabaseService.reportPost`; the post is **always hidden locally and immediately**, whether or not the upload succeeds (offline, migration not yet applied, server error — the user-protective action never waits on the network).
  - **Hide Clouds from This Author** — blocks the author by device id; every cloud from that author is hidden from then on.
- Both actions show a confirmation banner and dismiss the cloud (sheet on iPhone, detail column on iPad).
- `HiddenPostsStore` (`Utilities/HiddenPostsStore.swift`) persists hidden post ids and blocked author device ids in UserDefaults — hides survive relaunch.
- Grab flows respect the store: "Grab a Cloud" / "Grab Another" retry up to 3 fetches, skipping any hidden or blocked candidate, before falling back to the "no clouds out there" message.

---

### 3.2 Virtual Pet (虚拟宠物)

**Character:** Cartoon cat with multiple mood states (happy, neutral, hungry, tired, excited).

**Stats:**
- `hungerLevel` (0–100): Decreases over time; triggers hungry animation below threshold
- `energyLevel` (0–100): Decreases with interactions; replenished by rest
- `xp` / `level`: XP gained from feeding, petting, rest
- `mood`: Computed from combined stats

**Actions:**
- **Feed:** Costs food currency from Economy; restores hunger; grants XP
- **Pet:** Boosts mood; costs small energy; grants XP
- **Rest:** Restores energy over time; shows sleep animation

**Animations:** Mood-based idle animations, action-response animations, level-up celebration.

**Home Themes:** 4 unlockable themes (e.g., meadow, night sky, cozy room, forest); switched via Economy tokens or level unlock.

**Notifications:** Feeding reminder fires 4 hours after last feed via `NotificationService`.

---

### 3.3 Plant Garden (植物花园)

**Capacity:** Up to 5 concurrent plants.

**Species:** 5 plant species, each with distinct visual art and growth behavior.

**Growth Stages:** 5 stages per species (seed → sprout → young → mature → bloom). Stage advances when watering XP threshold is met.

**Watering:** Daily watering action grants plant XP. Watering reminder fires 24 hours after last water.

**Visual:** Custom 2D plant art for each species × stage combination. Idle sway animation.

---

### 3.4 Journal (日记)

**Entry creation:**
- Text editor with optional title and a **single mood tag** chosen from 16 options — via mood pills or a **1D pleasantness slider** (`MoodTag.nearestByValence` maps the slider position to the nearest tag by valence only; the old 2D valence/arousal meter is retired, but entries' stored 2D coordinates are preserved and never rewritten unless the user actually moves the slider)
- Photo attachment: up to 10 photos per entry, stored via `PhotoStorage` in iCloud ubiquity container
- Voice note: one m4a recording per entry (5-minute cap — takes that hit the cap are finalized and attached, with a notice), auto-transcribed via Apple Speech (zh + en recognizers, best transcript wins; transcript still persists if the editor is closed before transcription finishes)
- Optional location tag (precise GPS + reverse-geocoded name) with automatic weather fetch via Open-Meteo
- Two dates per entry: `createdAt` (write date, immutable) and `entryDate` (user-editable event date); display/grouping uses the event date

**Mood Calendar Strip:** Week view showing mood emoji for each day; tappable to navigate to that day's entry.

**Search:** Filter entries by text / title / voice transcript / location name (`JournalSearch.filter`, results sorted by display date descending).

**Mood Statistics Page:**
- Segmented control: week / month / year — the year mode is a real yearly view (4×3 grid of 12 month cells showing each month's dominant mood, with distribution and streaks aggregated over the whole year)
- Bar/area chart of mood distribution
- Streak counter (consecutive days with entries)
- Places map with tappable mood markers → entry detail

**AI Summaries:** Auto weekly summary (Monday-anchored via `WeekAnchor`; regenerates when new entries arrive after the last generation) plus opt-in per-entry summary — both generated by the `summarize-journal` Edge Function and stored locally as `JournalSummary` models.

**Entry Detail View:** Full entry with photos, voice note, mood, location/weather, timestamps; edit and delete options.

**Privacy Lock integration:** Journal tab is lockable via the Privacy Lock system; requires passcode / biometric to access if enabled.

**iCloud Sync:** Entries stored in SwiftData (CloudKit container); photos stored separately in iCloud ubiquity container via `PhotoStorage`.

---

### 3.5 Economy System (经济系统)

**Currencies:**
- `food`: Used to feed the virtual pet. Earned via daily tasks, purchased in Shop.
- `decorationTokens`: Used for theme unlocks and shop purchases. Earned via tasks and challenges.
- `gems`: Premium currency. Reserved for future monetization (not yet spendable).

**Daily Tasks (4 types):**
1. Write a journal entry
2. Water a plant
3. Feed the pet
4. Post a drift bottle cloud

**Weekly Challenges (4 types):**
1. Complete 5 daily tasks
2. Maintain a 3-day journal streak
3. Grow a plant to the next stage
4. React to 3 drift bottle clouds

**Login Streak Rewards:** Tiered rewards (food, tokens) for consecutive daily logins. Streak counter displayed on home screen.

**Shop:** Buy food bundles with decoration tokens. Managed by `EconomyViewModel`.

---

### 3.6 Privacy Lock (隐私锁)

**Passcode:** Apple-style 4-digit PIN entry UI. Stored in iOS Keychain via `PrivacyLockManager`. Never stored in SwiftData or Supabase.

**Biometrics:** FaceID / TouchID via LocalAuthentication framework as an alternative to PIN entry.

**Scope control:** User can independently enable / disable lock for:
- My Clouds (personal posts list)
- Journal (all journal entries)

**Gate page:** Before the PIN pad is shown, a landing screen confirms which section is locked and gives context (prevents accidental lock-outs).

**Lock buttons:** Padlock icon on the My Clouds and Journal tab headers to enable locking from within each section.

---

### 3.7 Onboarding (新手引导)

4-page sequential flow:
1. **Welcome** — App name, tagline, warm illustration
2. **Features** — Brief tour of the 4 main modules (clouds, pet, garden, journal)
3. **Privacy & Aliases** — Explains the alias system: display names are randomized per session, real Apple ID or device ID never shown to other users
4. **Get Started** — Apple Sign-In button (ASAuthorizationController) or "Continue as Guest" option

**Shown once:** `AppState.hasCompletedOnboarding` flag (persisted in UserDefaults) prevents re-show.

---

### 3.8 Settings (设置)

**Sections:**
- **Account:** Signed-in Apple ID display name, sign out, guest-to-account migration prompt
- **Alias Explanation:** Dedicated screen explaining how anonymous aliases work
- **Privacy Lock:** Toggle lock for My Clouds and/or Journal; set / change passcode; enable/disable biometrics
- **Appearance:** Runtime language switch (EN / ZH); dark mode preference
- **iCloud Sync Status:** Shows CloudKit container sync state; link to iCloud settings
- **Privacy Policy:** In-app web view of the privacy policy
- **Delete My Data:** Full account deletion. The cloud post wipe is awaited first and the flow **aborts before touching any local data if it fails** (so a guest's posts can never be orphaned by a rotated device_id); it also deletes the user's comments and reactions, then clears SwiftData, the CloudKit zone, the Keychain passcode, and preferences
- **Debug Panel (Debug builds only):** Activated by tapping the version label 5 times. Shows pet/plant/economy sliders, reset buttons, device info (apple_user_id, device_id, SwiftData record counts)

---

### 3.9 Authentication (身份验证)

**Apple Sign-In:**
- Uses `ASAuthorizationAppleIDButton` and `ASAuthorizationController`
- Credential: `ASAuthorizationAppleIDCredential` with `user` (stable apple_user_id)
- `apple_user_id` stored in SwiftData `AppState` and sent to Supabase for social data linking
- Full name and email collected only on first sign-in; subsequent sign-ins return only the user ID

**Guest Mode:**
- Device UUID used as `device_id` for Supabase interactions
- All local SwiftData (pet, plant, journal, economy) available in guest mode
- Supabase social features (posting clouds, reactions, comments) also available via device_id

**Device-to-account migration:** When a Guest user signs in with Apple, existing local SwiftData is retained; `device_id` is linked to `apple_user_id` in Supabase to preserve cloud posts.

---

### 3.10 iCloud Sync (iCloud 同步)

**SwiftData + CloudKit:**
- All local models (Pet, Plant, JournalEntry, Economy, DailyTask, WeeklyChallenge, ChatMessage, JournalSummary, CloudPost cache) in a CloudKit-backed SwiftData container
- Sync happens automatically when the device is online and the user has iCloud enabled

**Journal Photos:**
- Stored via `PhotoStorage` in the app's iCloud ubiquity container (`NSFileManager.default.url(forUbiquityContainerIdentifier:)`)
- Referenced by filename in `JournalEntry`; loaded on demand

**Supabase (social layer):**
- Cloud posts, comments, reactions stored server-side in Supabase PostgreSQL
- Linked to user via `apple_user_id` (authenticated) or `device_id` (guest)
- Not synced via CloudKit; fetched from Supabase REST API

---

### 3.11 Push Notifications (推送通知)

Managed by `NotificationService`:

| Notification | Trigger | Schedule |
|---|---|---|
| Feeding reminder | 4 hours after last pet feed | Local, rescheduled on each feed |
| Watering reminder | 24 hours after last plant water | Local, rescheduled on each water |
| Daily check-in | Every day at 9:00 AM | Recurring local notification (evergreen message — unread counts are delivered by the on-launch check instead) |
| Evening check-in | Every day at 6:00 PM | Recurring local notification (pet reminder) |

All notifications are local (no APNs server required). User is prompted for permission during onboarding.

---

### 3.12 Localization (双语本地化)

- **Languages:** English (en) and Simplified Chinese (zh-Hans)
- **Implementation:** `L10n.swift` with `L10n.t()` helper used throughout all Views and ViewModels. String Catalog (`Localizable.xcstrings`) for all user-facing strings.
- **Runtime switch:** Language preference stored in `AppState`; app reloads localization bundle without restart.
- **Bilingual parity:** Every string key must have both EN and ZH values before shipping.

---

### 3.13 Developer Debug Panel (开发者调试面板)

**Access:** Tap the version/build label in Settings 5 times.

**Contents:**
- Pet stat sliders (hunger, energy, XP)
- Plant stage and watering XP adjustment
- Economy currency adjusters (food, tokens, gems)
- Quick actions: reset onboarding, clear notifications, trigger streak bonus
- Device info: `apple_user_id`, `device_id`, SwiftData record counts, app version, build number

**Distribution:** Debug panel is compiled only into Debug builds (`#if DEBUG`) — it is not present in TestFlight or App Store binaries.

---

## 4. Data Model

### 4.1 SwiftData Models (Local + CloudKit Synced)

All properties carry inline defaults (a CloudKit requirement for `@Model` classes).

```swift
// Pet — the virtual cat
@Model class Pet {
    var id: String
    var name: String
    var hungerLevel: Int               // 0–100, decays hourly
    var moodRaw: String                // enum stored as raw string
    var lastFedAt: Date?
    var lastHungerUpdateAt: Date?      // decay checkpoint — sub-hour remainders carry over
    var createdAt: Date
    var energy: Int                    // 0–100
    var level: Int
    var experience: Int
    var nextLevelExp: Int
    var homeThemeRaw: String           // enum stored as raw string
}

// Plant
@Model class Plant {
    var id: String
    var name: String
    var speciesRaw: String             // enum: 5 species
    var growthStageRaw: String         // enum: seed → sprout → young → mature → bloom
    var hydrationLevel: Int            // 0–100, decays over time
    var experience: Int
    var lastWateredAt: Date?
    var lastHydrationUpdateAt: Date?   // decay checkpoint — fractional remainders carry over
    var createdAt: Date
}

// JournalEntry (19 stored properties)
@Model class JournalEntry {
    var id: String
    var createdAt: Date                // write date — immutable
    var moodTagRaw: String             // SINGLE mood tag (one of 16)
    var text: String
    var title: String?
    var photoFilenames: [String]?      // iCloud ubiquity filenames (max 10)
    // Audio (voice note)
    var audioFilename: String?
    var audioTranscript: String?
    var audioDurationSeconds: Double?
    // Location
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    // Weather (auto-fetched via Open-Meteo when location is added)
    var weatherTempC: Double?
    var weatherCode: Int?
    var weatherEmoji: String?
    var weatherDescription: String?
    // Two-dates model: createdAt is immutable, entryDate is the user-editable event date
    var entryDate: Date?
    // Mood coordinates (nil = use MoodTag defaults; preserved unless the slider is moved)
    var moodValence: Double?
    var moodArousal: Double?
}

// Economy
@Model class Economy {
    var id: String
    var food: Int
    var decorationTokens: Int
    var gems: Int
    var loginStreak: Int
    var lastLoginDate: Date?
    var lastDailyResetDate: Date?
    var lastBonusClaimDate: Date?      // daily login bonus — claimable once per day, persisted
}

// DailyTask (one row per task type per day; deduped on load after CloudKit sync)
@Model class DailyTask {
    var id: String
    var title: String                  // stored English (identity only — UI renders localizedTitle)
    var taskDescription: String
    var typeRaw: String
    var isCompleted: Bool
    var foodReward: Int
    var tokenReward: Int
    var createdAt: Date
}

// WeeklyChallenge
@Model class WeeklyChallenge {
    var id: String
    var typeRaw: String
    var currentCount: Int
    var isCompleted: Bool
    var weekStartDate: Date
    var createdAt: Date
}

// CloudPost (local cache of fetched Supabase posts)
@Model class CloudPost {
    var id: String                     // Supabase UUID
    var authorAlias: String
    var moodTagRaw: String
    var text: String
    var createdAt: Date
    var npcReplyText: String?
    var sourceLanguage: String
}

// ChatMessage — pet chat history
@Model class ChatMessage {
    var id: String
    var text: String
    var isFromUser: Bool
    var createdAt: Date
    var modeRaw: String                // "basic" or "premium" (see ChatMode)
}

// JournalSummary — AI-generated summaries (weekly / single-entry / insights)
@Model class JournalSummary {
    var id: UUID
    var kindRaw: String                // weekly | single | insights
    var periodStart: Date              // weekly: Monday week start (WeekAnchor)
    var periodEnd: Date
    var summary: String
    var language: String
    var generatedAt: Date              // used to decide regeneration when newer entries exist
    var sourceEntryId: String?         // set for single-entry summaries
}
```

`ChatMode` (plain enum, not persisted) models the pet-chat tiers: `.basic` (on-device/scripted reply, Apple TTS, 1 hunger) vs `.premium` (MiniMax AI via `pet-chat`, MiniMax TTS via `pet-tts`, 10 hunger).

**Service layer** (`Services/`, 8 files):

| Service | Responsibility |
|---|---|
| `SupabaseService` | All Supabase REST / RPC / Edge Function calls (posts, comments, reactions, moderation, NPC replies, journal summaries, post reports, account deletion) |
| `CloudPostAPI` | Protocol seam over the cloud-post network calls — view models depend on the protocol, tests inject fakes, `LiveCloudPostAPI` forwards to `SupabaseService` |
| `PetChatService` | Pet chat replies — `pet-chat` Edge Function (premium) with a scripted offline fallback selected by app language |
| `PetVoiceService` | Pet TTS — `pet-tts` Edge Function (MiniMax voices) + AVSpeechSynthesizer fallback, audio caching (main-actor isolated) |
| `WeatherService` | Open-Meteo current-weather fetch for journal entries |
| `LocationService` | One-shot CoreLocation fetch with a 10 s timeout; concurrent callers share a single request |
| `AnalyticsService` | Fire-and-forget anonymous events to the `analytics_events` table |
| `AudioRecorder` | Voice-note recording with a 5-minute cap (capped takes are finalized and attached) |

Supporting utilities (`Utilities/`, 11 files): `L10n`, `NotificationService`, `PhotoStorage`, `AudioStorage`, `PrivacyLockManager`, `WeekAnchor` (Monday-anchored week math), `JournalSearch`, `JournalTranscription`, `HiddenPostsStore` (UserDefaults-persisted hidden post ids + blocked author device ids for report/hide), `PhotoThumbnailLoader` (async cached downsampled thumbnails), `MoodByDay` (one-pass day→mood lookup).

### 4.2 Supabase PostgreSQL Schema

**Table: `cloud_posts`**
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | auto-generated |
| content | text | moderated before insert |
| mood_tag | text | enum-like string |
| author_alias | text | random per session |
| apple_user_id | text nullable | null for guest |
| device_id | text | always present |
| created_at | timestamptz | default now() |
| is_flagged | bool | set by moderation |

**Table: `cloud_comments`**
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| post_id | uuid FK → cloud_posts | |
| content | text | |
| apple_user_id | text nullable | |
| device_id | text | |
| created_at | timestamptz | |

**Table: `cloud_reactions`**
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| post_id | uuid FK → cloud_posts | |
| reaction_type | text | breeze / hug / starlight |
| device_id | text | |
| created_at | timestamptz | |
| UNIQUE | (post_id, device_id, reaction_type) | one reaction type per device per post |

**Table: `npc_reply_templates`**
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| mood_tag | text | matches post mood_tag |
| reply_text | text | template body |
| persona | text | NPC name |

**Table: `grabbed_posts`**
| Column | Type | Notes |
|---|---|---|
| post_id | uuid FK → cloud_posts | |
| apple_user_id / device_id | text | whichever identity grabbed it |
| grabbed_at | timestamptz | powers no-repeat "grab a cloud" |

**Table: `analytics_events`**
| Column | Type | Notes |
|---|---|---|
| device_id | text | anonymous |
| event / properties | text / jsonb | never contains user content text |
| created_at | timestamptz | |

**Table: `post_reports`** *(pending migration — see below)*
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | auto-generated |
| post_id | uuid FK → cloud_posts | on delete cascade |
| reporter_device_id | text | anonymous reporter identity |
| reason | text | `harmful` / `spam` / `hateful` / `other` (CloudReportReason raw values) |
| created_at | timestamptz | default now() |
| UNIQUE | (post_id, reporter_device_id) | one report per device per post — bounds spam-reporting |

RLS: anonymous clients may only **insert** reports — never read, update, or delete.

**View: `post_reaction_counts`**
Aggregates `cloud_reactions` grouped by `post_id` and `reaction_type`.

**View: `reported_posts_summary`** *(pending migration — see below)*
Reported posts joined with their report counts and last-reported timestamps, ranked by report count — the manual review queue for deleting offending posts.

**Edge Functions:**
- `moderate-post`: Accepts post content, calls MiniMax M2.7-highspeed moderation API, returns allow/reject + reason. Called by client before insert.
- `generate-npc-reply`: Accepts post_id, calls MiniMax to generate a contextual NPC reply, falls back to `npc_reply_templates` on failure.
- `pet-chat`: Premium pet-chat replies via MiniMax (basic tier uses an on-device/scripted fallback).
- `pet-tts`: MiniMax text-to-speech for the pet's voice (voice selectable in-app).
- `summarize-journal`: Generates weekly / per-entry AI journal summaries with auto language detection.

**RPCs (SECURITY DEFINER):** `get_random_post`, `get_my_posts`, `get_my_unread_count`, `migrate_posts_to_apple_user`, `delete_my_posts` — all match on `device_id` OR `apple_user_id`.

> **Pending migration #1:** `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` adds a `delete_my_data` RPC that extends account deletion to the user's comments and reactions server-side. It must be reviewed and run in the Supabase SQL editor. The client already calls `rpc/delete_my_data` first and transparently falls back to `delete_my_posts` + client-side cleanup while the function is missing (PostgREST 404).
>
> **Pending migration #2:** `supabase/migrations/20260717_post_reports.sql` creates the `post_reports` table and the `reported_posts_summary` review view behind the in-app "Report Cloud" button. Until it is run, report uploads fail silently — the reporter's local hide still always works. After running it, review `reported_posts_summary` periodically and delete offending posts.

---

## 5. AI Integration

### 5.1 Model: MiniMax M2.7-highspeed

Used for five purposes (all proxied through Supabase Edge Functions):
1. **Content moderation** — Determines whether a draft post is safe to publish. Invoked via the `moderate-post` Edge Function. Returns a confidence score and category labels. Posts rejected by AI are blocked client-side with a user-friendly message.
2. **NPC reply generation** — Generates a short, empathetic reply from an NPC persona. Invoked via `generate-npc-reply` Edge Function after a post is saved. Falls back to `npc_reply_templates` if the AI call fails or times out.
3. **Pet chat** — Conversational replies from the pet (premium tier) via the `pet-chat` Edge Function; the basic tier uses an on-device/scripted fallback selected by app language.
4. **Pet TTS** — MiniMax text-to-speech voices for the pet via the `pet-tts` Edge Function, with AVSpeechSynthesizer as fallback.
5. **Journal summarization** — Weekly and per-entry AI summaries via the `summarize-journal` Edge Function, with auto language detection.

### 5.2 Three-Layer Moderation Pipeline

```
User submits post
       │
       ▼
[Layer 1] Client-side keyword filter
   Pass → continue   Fail → block instantly, no network call
       │
       ▼
[Layer 2] MiniMax AI via Edge Function moderate-post
   Pass → continue   Fail → block with AI reason message
       │
       ▼
[Layer 3] PostgreSQL trigger (server-side rules)
   Pass → post saved   Fail → post rejected, client notified
```

### 5.3 NPC Reply Flow

```
Post saved to Supabase
       │
       ▼
Edge Function generate-npc-reply called
       │
   ┌───┴────────────────────┐
   │ MiniMax available?     │
   │ Yes → generate reply   │
   │ No  → fallback template│
   └───┬────────────────────┘
       │
       ▼
Reply stored in cloud_posts.npc_reply
Client polls / receives updated post
```

### 5.4 Cost Controls

- All AI calls routed through Supabase Edge Functions (not called directly from client) — enables rate limiting, logging, and key security.
- `generate-npc-reply` fires once per post (not per view).
- Client-side keyword filter reduces AI call volume by blocking obvious violations early.

---

## 6. Privacy & Security Design

### 6.1 Identity & Anonymity

- **Display aliases** are randomly generated per session (e.g., "Drifting Cloud #4821"). Other users see only the alias, never the Apple user ID or device ID.
- `apple_user_id` and `device_id` are stored in Supabase to enforce reaction uniqueness and support post deletion, but are never displayed in the UI.
- Supabase Row Level Security (RLS) ensures users can only delete their own posts (matching `apple_user_id` or `device_id`).

### 6.2 Privacy Lock

- 4-digit passcode stored in iOS Keychain via `PrivacyLockManager`. Never leaves the device.
- Biometric authentication (FaceID / TouchID) via `LocalAuthentication` as a convenience alternative.
- Individual sections (My Clouds, Journal) can be locked independently.
- On incorrect passcode, a short lockout cooldown is applied.

### 6.3 Data Storage

| Data | Storage | Notes |
|---|---|---|
| Pet, Plant, Economy, Journal text | SwiftData + CloudKit | Encrypted at rest by iOS |
| Journal photos | iCloud ubiquity container | User controls via iCloud settings |
| Passcode | iOS Keychain | Never in SwiftData |
| Apple user ID | SwiftData + Supabase | Used for linking only |
| Cloud posts / comments / reactions | Supabase PostgreSQL | Anonymous alias only shown in UI |
| App preferences | UserDefaults (via AppState) | Language, theme, lock settings |

### 6.4 Minimum PII Principle

- No real name is ever collected or stored beyond what Apple provides at first Sign-In (and that is stored locally only).
- No email address is transmitted to Supabase.
- Guest mode uses only a device UUID (no identity linkage).

### 6.5 Transport Security

- All Supabase communication uses HTTPS/TLS.
- Supabase anon key is stored in the app bundle (standard practice); RLS policies enforce data access rules on the server.

### 6.6 UGC Moderation & User Reporting

The UGC safety story has two halves:

- **Pre-publish:** the 3-layer moderation pipeline (client keyword filter → MiniMax AI → PostgreSQL trigger, §5.2) blocks unsafe content before it ever reaches other users.
- **Post-publish (App Review guideline 1.2):** users can report any stranger's cloud (four reason categories) or block an author entirely (see §3.1). The protective action is **local-first**: the reported/blocked content disappears for that user instantly and permanently (persisted via `HiddenPostsStore`), independent of network state. The report itself is uploaded best-effort to `post_reports` (insert-only RLS — reporters can never read others' reports), and the developer reviews `reported_posts_summary` periodically to delete offending posts for everyone.

---

## 7. Economy System Design

### 7.1 Currency Overview

| Currency | Symbol | Earned by | Spent on |
|---|---|---|---|
| Food | 🍖 | Daily tasks, login streak | Feeding the pet |
| Decoration Tokens | 🪙 | Daily tasks, weekly challenges, login streak | Shop purchases, future theme unlocks |
| Gems | 💎 | Reserved (future monetization) | Reserved |

### 7.2 Task & Reward Structure

**Daily tasks reset at midnight local time. Weekly challenges reset Monday.**

| Daily Task | Reward |
|---|---|
| Write a journal entry | 2 food + 1 token |
| Water a plant | 2 food + 1 token |
| Feed the pet | 1 food + 2 tokens |
| Post a drift bottle cloud | 3 tokens |

| Weekly Challenge | Reward |
|---|---|
| Complete 5 daily tasks | 10 tokens |
| Maintain 3-day journal streak | 5 food + 5 tokens |
| Grow a plant to next stage | 8 food |
| React to 3 drift bottle clouds | 6 tokens |

### 7.3 Login Streak Rewards

| Streak (days) | Reward |
|---|---|
| 1–2 | 2 food |
| 3–6 | 3 food + 2 tokens |
| 7 | 5 food + 5 tokens (weekly bonus) |
| 14 | 10 food + 10 tokens |
| 30 | 20 food + 20 tokens + 1 gem |

Streak resets to 0 if a day is missed.

### 7.4 Anti-Hoarding Measures

- Food is consumed on each pet feeding — natural drain.
- Decoration tokens have no cap currently; future monetization may introduce seasonal expiry for promotional tokens.
- Gems reserved for future; no accumulation currently possible.

---

## 8. Architecture

### 8.1 App Architecture: MVVM + @Observable

```
View (SwiftUI)
  │ reads / binds
  ▼
ViewModel (@Observable)
  │ calls
  ▼
Service (SupabaseService, NotificationService, PhotoStorage, PrivacyLockManager)
  │ reads/writes
  ▼
Data Layer (SwiftData / Supabase REST / Keychain / iCloud)
```

- Views are purely declarative; no business logic.
- ViewModels hold all state and orchestrate service calls.
- Services are stateless utilities injected via `@Environment` or passed directly.
- Cloud-post network calls go through the `CloudPostAPI` protocol (`Services/CloudPostAPI.swift`) — a dependency-injection seam so view models are testable against fakes, with `LiveCloudPostAPI` forwarding to `SupabaseService` in production.
- `AppState` (@Observable, preferences persisted via UserDefaults) is the single source of truth for global state (auth, onboarding, language).

### 8.2 Navigation

- Root: `ContentView` gates on `AppState.hasCompletedOnboarding` to show Onboarding or the main TabView.
- `TabView` with 5 tabs: Clouds, Pet, Garden, Journal, Settings.
- Each tab uses `NavigationStack` for push navigation.
- Privacy Lock intercepts navigation to locked tabs with a gate view.

### 8.3 Concurrency

- Swift 6 strict concurrency throughout.
- All UI updates on `@MainActor`.
- Supabase network calls use `async/await` in non-isolated async functions, with results published back to `@MainActor` ViewModels.

### 8.4 SwiftData + CloudKit

- `ModelContainer` configured with CloudKit container ID (`iCloud.com.csquare04.Treehole`) for automatic sync.
- All `@Model` classes are CloudKit-compatible (no non-optional relationships without defaults; inline defaults on every property).
- The SwiftData store is **never auto-deleted**: if the container fails unrecoverably, the store files are moved aside as `Backup-*` and a fresh store is created, so user data is preserved for recovery.
- CloudKit sync can duplicate singleton-ish rows (Economy, DailyTask) across devices; these are deduped deterministically on load (lowest-id row wins, balances merged with `max()`).
- Journal photos use a separate iCloud ubiquity container to avoid CloudKit attachment size limits.

---

## 9. Monetization Plans

**Current state (Phase 3):** No in-app purchases implemented. Economy system uses soft currencies only.

**Planned (Phase 4–5):**

| Tier | Offering | Notes |
|---|---|---|
| Free | Full core experience (clouds, pet, garden, journal, economy) | No paywall on primary features |
| Decoration Pack (one-time) | Extra home themes, plant skins | One-time IAP |
| Subscription (monthly) | Bonus food allowance, exclusive themes, priority NPC reply quality | StoreKit 2 subscription |
| Gem top-up (one-time) | Bundles of gems for future premium items | StoreKit 2 consumable |

**Principles:**
- No paywalls on emotional/wellness features (posting, journaling, pet care basics).
- Monetization is additive (cosmetic, convenience), never punishing.
- No ads. Ever.

---

## 10. Roadmap

### Phase 1 — COMPLETE
Core loop: onboarding, cloud posts with NPC replies, virtual pet, single plant, journal, settings.

### Phase 2 — COMPLETE
Economy system, shop, daily tasks, weekly challenges, login streaks, 5 plant species with growth stages, full EN/ZH bilingual, push notifications, dark mode, pet XP/levels/themes, initial unit + UI test suites.

### Phase 3 — COMPLETE
Apple Sign-In, CloudKit sync, Privacy Lock (passcode + biometrics), drift bottle reactions (breeze / hug / starlight), My Clouds management, Supabase social layer, MiniMax AI moderation + NPC replies, journal photos (iCloud), mood statistics page, developer debug panel.

### Phase 4 — CURRENT
**Shipped so far:** journal redesign (floating toolbar editor, voice notes + transcription, search, edit, location + weather, two dates, iPad adaptive split view), 16-mood system with pills / 1D pleasantness slider, real Year mood statistics view, per-entry + Monday-anchored weekly AI summaries (`summarize-journal`), pet chat with TTS voice selection (`pet-chat` / `pet-tts`), no-repeat cloud grabbing (`grabbed_posts`), anonymous analytics (`analytics_events`), account-deletion hardening (abort-on-failure + comment/reaction cleanup, `delete_my_data` RPC with transparent fallback), privacy-lock re-lock on backgrounding, daily-login-bonus persistence + CloudKit dedupe, cloud report/hide/block UGC moderation UI (`post_reports` + `HiddenPostsStore`, App Review 1.2), accessibility pass (VoiceOver labels/traits across all screens, Dynamic Type conversions, Reduce Motion gating), `CloudPostAPI` DI seam for testable cloud networking, deterministic rewrite of the 3 formerly flaky UI tests. Test suite: 338 unit tests (Swift Testing) + 22 UI tests (XCTest) = 360 total.

**Remaining:**
- UI polish pass aligned to Figma design specs
- Animation refinement (pet, plant, cloud transitions)
- On-device manual accessibility verification (VoiceOver sweeps, Reduce Motion, Dynamic Type AX5 — see TESTING_CHECKLIST.md; the code-side pass has shipped)
- Performance profiling (SwiftData query costs, main-thread work)
- Additional AI features (enhanced NPC personas, mood-aware replies)

### Phase 5 — PLANNED
- App Store submission (privacy manifest, age rating, screenshots)
- TestFlight external beta
- IAP implementation (StoreKit 2)
- Additional languages (Traditional Chinese, Japanese)

---

## Appendix: Open Questions

- NPC content boundary policy and mental health compliance review
- Human moderation fallback tooling for edge cases
- Long-term content storage policy (auto-expiry of old posts?)
- COPPA compliance if underage users are detected
- Subscription pricing and regional pricing tiers
- Pet chat is now shipped (basic/premium tiers, hunger-based quota) — remaining question: long-term conversational memory

---

# 产品设计文档（中文摘要）

> 以下为中文版完整摘要，与上方英文文档对应。

## 产品愿景

Treehole（树洞）是一款安全、匿名的情绪出口与温柔自我关怀伴侣应用。用户将心情化为匿名"漂流瓶云朵"飘向共享天空，陌生人可以抓住云朵、阅读、用微风/拥抱/星光回应，并收到 AI NPC 留言。虚拟宠物、植物花园和私密日记共同构成每日仪式。全程采用 iOS 26 Liquid Glass 设计，支持中英双语。

## 目标用户

**核心用户：** 18-28 岁的 Z 世代，面对职场或校园压力，寻求匿名宣泄与情绪陪伴，无需社交压力。

**次级用户：** 喜欢虚拟养成、轻度休闲游戏的玩家。

**无障碍：** 支持动态字体、VoiceOver、减少动画、高对比度模式。

## 核心功能规格

### 漂流瓶云朵
- 匿名发帖，别名按会话随机生成
- 三层内容审核：客户端关键词过滤 → MiniMax AI 审核 → PostgreSQL 触发器
- "抓一朵云"随机浏览，微风/拥抱/星光三种反应（每设备每帖每类型限一次）
- 评论功能，AI NPC 回复（MiniMax M2.7-highspeed）
- 我的云朵管理（查看/删除自己的帖子）
- 举报与隐藏（发布后 UGC 审核，App Review 1.2）：陌生人云朵的菜单提供"举报云朵"（4 种理由：有害/垃圾/仇恨/其他，尽力上报到 `post_reports`）与"隐藏此作者的云朵"（按作者 device_id 屏蔽）；无论上报是否成功，**本地隐藏立即且永久生效**（`HiddenPostsStore` 持久化于 UserDefaults），抓云时自动跳过已隐藏/已屏蔽的帖子（最多重试 3 次）

### 虚拟宠物
- 卡通猫，心情动画，喂食/抚摸/休息三种互动
- 饥饿值/精力值/经验值/等级系统
- 4 套可解锁家居主题，喂食消耗食物货币
- 喂食提醒通知（4 小时后触发）

### 植物花园
- 最多 5 株并行，5 种植物，每种 5 个成长阶段
- 每日浇水获得经验值，浇水提醒（24 小时后触发）
- 自定义 2D 植物视觉艺术

### 日记
- 单一心情标签（16 种可选），可用胶囊按钮或一维愉悦度滑条选择（`MoodTag.nearestByValence` 仅按愉悦度匹配；旧日记的 2D 心情坐标会被保留，除非用户主动拖动滑条）
- 可选标题，最多 10 张照片（iCloud 同步），语音备忘（5 分钟上限——达上限的录音会被保留并附加，Apple Speech 中英自动转写）
- 可选位置标签 + 自动 Open-Meteo 天气，双日期（不可变的写作日期 + 可编辑的事件日期）
- 搜索（文本/标题/转写/位置），编辑已有日记
- 心情周历带状视图，心情统计页（周/月/年——年视图为 12 个月心情网格）
- 心情分布图，连续打卡天数追踪，地点地图
- AI 摘要：每周自动摘要（以周一为起点，有新日记时重新生成）+ 单条摘要（`summarize-journal` Edge Function）

### 经济系统
- 三种货币：食物、装饰代币、宝石
- 4 类每日任务，4 类每周挑战，登录连续奖励
- 商店：用代币购买食物

### 隐私锁
- 4 位数字密码（iOS Keychain 存储）
- FaceID/TouchID 生物识别
- 独立锁定我的云朵和/或日记

### 新手引导
4 页：欢迎 → 功能介绍 → 隐私与别名说明 → 开始（Apple 登录或游客）

### 设置
账户、别名说明、隐私锁、外观（语言/深色模式）、iCloud 同步状态、隐私政策、完整账户删除（云端清除失败时安全中止，同时删除评论/反应；优先调用 `delete_my_data` RPC，迁移执行前自动回退到 `delete_my_posts` + 客户端清理）、调试面板（仅 Debug 构建）

### 身份验证
Apple Sign-In（stable apple_user_id），游客模式（device_id），设备迁移至账户

### iCloud 同步
SwiftData + CloudKit 同步本地数据；日记照片存储于 iCloud 容器；Supabase 处理社交数据

### 推送通知
喂食提醒（4 小时）、浇水提醒（24 小时）、每日签到（上午 9 点）

### 双语本地化
L10n.t() 贯穿全局，运行时切换语言，中英字符串完全同步

### 开发者调试面板
仅 Debug 构建包含（`#if DEBUG`），连击版本号 5 次解锁，含数值滑条、快捷操作、设备信息

## 数据模型

### SwiftData 本地模型
- `Pet`：饥饿值（含衰减检查点）、精力、经验值、等级、心情、主题、最后喂食时间
- `Plant`：种类、成长阶段、水分值（含衰减检查点）、经验、最后浇水时间
- `JournalEntry`（19 个存储属性）：写作日期（不可变）、事件日期（可编辑）、单一心情标签 + 可选 2D 心情坐标、文本、可选标题、照片文件名（最多 10 张）、语音（文件名/转写/时长）、位置（经纬度/地名）、天气（温度/代码/emoji/描述）
- `Economy`：食物、代币、宝石、登录连续天数、每日重置日期、每日登录奖励领取日期（持久化）
- `DailyTask`：每类型每天一行（CloudKit 重复行加载时去重），标题渲染时本地化
- `WeeklyChallenge`：类型、进度、完成状态、周开始日期
- `CloudPost`（缓存）：Supabase UUID、别名、心情标签、内容、NPC 回复、源语言
- `ChatMessage`：宠物聊天记录（基础/高级模式）
- `JournalSummary`：AI 摘要（每周/单条/洞察，含生成时间与语言）

### Supabase 表结构
- `cloud_posts`：帖子（apple_user_id、device_id、别名、内容、心情标签、审核标记）
- `cloud_comments`：评论
- `cloud_reactions`：反应（每设备每帖每类型唯一约束）
- `grabbed_posts`：按用户记录已抓取的云朵，避免重复
- `analytics_events`：匿名分析事件
- `npc_reply_templates`：NPC 回复模板
- `post_reports`：用户举报（post_id、reporter_device_id、reason，每设备每帖限一次；匿名客户端仅可插入）——**待执行迁移**
- `post_reaction_counts`：反应数聚合视图
- `reported_posts_summary`：被举报帖子按举报次数排序的审阅视图——**待执行迁移**

**RPC：** `get_random_post`、`get_my_posts`、`get_my_unread_count`、`migrate_posts_to_apple_user`、`delete_my_posts`（均为 SECURITY DEFINER，匹配 device_id 或 apple_user_id）。**待执行迁移 #1：** `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` 新增 `delete_my_data`（连同评论/反应一并删除）——需在 Supabase SQL 编辑器审阅并执行；客户端已优先调用该 RPC，函数缺失时（PostgREST 404）自动回退到 `delete_my_posts` + 客户端清理。**待执行迁移 #2：** `supabase/migrations/20260717_post_reports.sql` 创建 `post_reports` 表与 `reported_posts_summary` 审阅视图——执行前举报上传静默失败（本地隐藏始终生效），执行后请定期审阅该视图并删除违规帖子。

Supabase 项目 URL：`https://gjtiqwkhrepwhtoyjeix.supabase.co`

## AI 集成

**模型：** MiniMax M2.7-highspeed

**用途：**
1. 内容审核 — 通过 `moderate-post` Edge Function 判断帖子是否安全
2. NPC 回复生成 — 通过 `generate-npc-reply` Edge Function 生成共情回复，失败时回退到模板
3. 宠物聊天 — 高级模式通过 `pet-chat` Edge Function；基础模式使用按应用语言选择的本地脚本回复
4. 宠物语音 — 通过 `pet-tts` Edge Function 提供 MiniMax TTS，失败时回退到 AVSpeechSynthesizer
5. 日记摘要 — 通过 `summarize-journal` Edge Function 生成每周/单条 AI 摘要（自动语言识别）

**三层审核管道：**
客户端关键词过滤 → MiniMax AI 审核 → PostgreSQL 触发器

所有 AI 调用通过 Supabase Edge Functions 路由（非客户端直调），便于速率限制与密钥安全。

## 隐私与安全设计

- 展示别名随会话随机生成，其他用户永远看不到 apple_user_id 或 device_id
- 密码存于 iOS Keychain，永不离开设备
- Supabase RLS 确保用户只能删除自己的帖子
- 最小化 PII：不向 Supabase 传输真实姓名或邮箱
- 全程 HTTPS/TLS 通信
- UGC 审核双保险：发布前三层审核管道 + 发布后用户举报/屏蔽（本地优先——被举报/屏蔽内容对该用户立即消失，与网络状态无关；举报尽力上报到 `post_reports`，开发者定期审阅 `reported_posts_summary` 删除违规帖子）

## 经济系统设计

**货币体系：** 食物（喂宠）、装饰代币（购物）、宝石（未来付费）

**每日任务奖励：** 写日记、浇水、喂食、发帖，各奖励不同数量食物/代币

**每周挑战奖励：** 完成 5 个每日任务、连续 3 天日记、植物成长一阶段、对 3 个云朵做出反应

**登录连续奖励：** 按天数递增，7 天、14 天、30 天有特殊奖励

**变现原则：** 不在情感/健康功能上设置付费墙，货币化为装饰/便利性，绝不投放广告。

## 迭代路线图

| 阶段 | 内容 | 状态 |
|---|---|---|
| Phase 1 | 核心闭环 | 已完成 |
| Phase 2 | 经济系统、任务、双语、通知 | 已完成 |
| Phase 3 | Apple 登录、CloudKit、隐私锁、反应、漂流瓶社交 | 已完成 |
| Phase 4 | 已交付：日记改版（语音/搜索/位置天气/双日期/iPad 分栏）、16 心情 + 愉悦度滑条、年视图、AI 摘要、宠物聊天 + TTS、不重复抓云、匿名分析、账户删除加固（`delete_my_data` + 透明回退）、云朵举报/隐藏/屏蔽（App Review 1.2）、无障碍代码整改（VoiceOver/动态字体/减弱动态效果）、`CloudPostAPI` 依赖注入接缝、3 个不稳定 UI 测试确定性重写（测试：338 单元 + 22 UI = 360）；进行中：UI 精修、动效、真机无障碍人工验证 | 当前阶段 |
| Phase 5 | App Store 上架、TestFlight 公测、IAP | 规划中 |
