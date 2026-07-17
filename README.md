# Treehole

<details open>
<summary>English Version</summary>

## Overview

Treehole is an iOS app for anonymous emotional expression and gentle self-care. Inspired by the ancient idea of whispering secrets into a tree hollow, users release feelings as **drift bottle clouds** that float in a shared sky — any stranger can "grab a cloud" and read it, react with a breeze, hug, or starlight, and leave an NPC-powered reply. Alongside the cloud space, users raise a virtual cat, tend a multi-plant garden, and keep a private journal — all within one cozy, bilingual app.

- **Bundle ID:** com.csquare04.Treehole
- **Platform:** iOS 17.0+ (universal — iPhone + iPad with adaptive split view in landscape), SwiftUI + SwiftData + CloudKit + @Observable, Swift 6
- **Backend:** Supabase (PostgreSQL + Edge Functions)
- **AI:** MiniMax M2.7-highspeed via Supabase Edge Functions (content moderation, NPC replies, pet chat, pet TTS, journal summarization with auto-language detection)
- **Distribution:** TestFlight (Toki Studio)

---

## Features

| Module | What's Implemented |
|---|---|
| Drift Bottle Clouds | Anonymous posting, "grab a cloud" for random posts (no repeats — server tracks grabbed history per user), comments, reactions (breeze / hug / starlight) with visual effects, My Clouds management, 3-layer content moderation, report a cloud (4 reason choices) or hide all clouds from an author — hiding is instant and local (persisted on-device), grabs skip hidden/blocked clouds, report upload is best-effort |
| Virtual Pet | Cartoon cat with mood-based animations, feed / pet / rest actions, hunger / energy / XP / level system, 4 home themes, feeding costs food currency |
| Plant Garden | Up to 5 plants, 5 species, 5 growth stages per species, watering grants XP, custom plant visual art |
| Journal | **16 mood tags picked via pills or a 1D pleasantness slider (valence-only — old entries' 2D mood values are preserved and never rewritten unless the slider is moved)**, redesigned editor with floating bottom toolbar (camera/photos/mic/location/date/more), optional title field, edit existing entries, search across text/title/transcript/location, two dates per entry (event date + write date), photo support (up to 10 photos, iCloud synced), voice notes (m4a, 5 min cap — capped takes are kept and attached, auto-transcribed via Apple Speech in zh/en), optional location tagging (precise GPS + reverse-geocoded name), automatic weather fetch via Open-Meteo when location added, mood week calendar strip, mood statistics (week / month / **real year view with 12-month mood grid**, all keyed by event date), mood distribution chart, Places map (tappable mood markers → entry detail), streak tracking, entry detail view, AI Insights card + auto weekly summary (**Monday-anchored, regenerates when new entries arrive**) + per-entry AI summary (opt-in, renders markdown) |
| Notifications | Daily 9 AM check-in (evergreen message — unread reply counts are delivered by the on-launch check instead), evening 6 PM pet reminder, on-launch unread interaction local notification (6h throttle), feeding / watering reminders |
| Analytics | Anonymous event tracking via Supabase `analytics_events` table — fire-and-forget, never blocks UI, never logs user content text |
| Economy | Food / Decoration Tokens / Gems currencies, 4 daily task types (titles localized at render time), 4 weekly challenge types, login streak rewards, daily login bonus claimable once per day (persisted), CloudKit-duplicated Economy/DailyTask rows deduped on load, shop (buy food with tokens) |
| Privacy Lock | Apple-style 4-digit passcode (Keychain stored), FaceID / TouchID, lock My Clouds and/or Journal independently, gate page before passcode entry, re-locks automatically when the app is backgrounded |
| Onboarding | 4-page flow: welcome, features, privacy & aliases, get started (Apple Sign-In or Guest) |
| Settings | Account, alias explanation, privacy lock, appearance (language / dark mode), iCloud sync status (real CKContainer.accountStatus check, requires Apple sign-in), full account deletion (aborts safely if the cloud wipe fails — nothing local is touched; also removes the user's comments/reactions; calls the `delete_my_data` RPC first and transparently falls back to `delete_my_posts` + client-side cleanup until the migration is applied), moderation management (unhide clouds / authors), [privacy policy](https://c-square04.github.io/Treehole/privacy.html), developer debug panel (Debug builds only, 5-tap version trigger) |
| Authentication | Apple Sign-In (ASAuthorizationAppleIDCredential), Guest mode, device-to-account post migration with persisted retry (on launch/foreground until it succeeds) |
| iCloud Sync | SwiftData + CloudKit for local data (pet / plant / journal / economy), iCloud ubiquity container for journal photos, Supabase for social data; the SwiftData store is never auto-deleted — on unrecoverable failure it is moved aside as `Backup-*` and recreated |
| Push Notifications | Feeding reminder (4 h), watering reminder (24 h), daily check-in (9 AM) |
| Localization | Full English + Simplified Chinese, L10n.t() throughout, runtime language switch, iOS permission dialogs localized via InfoPlist.xcstrings (zh-Hans) |
| Accessibility | VoiceOver labels/traits across journal, pet, plant, shop, settings, onboarding, privacy-lock, and cloud screens; Dynamic Type conversions for formerly fixed tiny fonts; Reduce Motion gating for looping/spring animations |
| Developer Panel | Debug-builds-only panel: pet / plant / economy sliders, quick actions, device info (5-tap unlock) |

---

## Tech Stack

| Layer | Details |
|---|---|
| Language | Swift 6 (strict concurrency, MainActor isolation) |
| UI | SwiftUI, iOS 26 Liquid Glass materials |
| State | @Observable (not ObservableObject) |
| Persistence | SwiftData (@Model classes) + CloudKit sync |
| Social Backend | Supabase (PostgreSQL, REST API, Edge Functions) |
| AI | MiniMax M2.7-highspeed (moderation + NPC replies) |
| Auth | Apple Sign-In (ASAuthorizationController) |
| Photos | PhotosUI (photo picker), iCloud ubiquity container |
| Biometrics | LocalAuthentication (FaceID / TouchID) |
| Keychain | Security framework (passcode storage) |
| Notifications | UserNotifications framework |
| Navigation | TabView (5 tabs) + NavigationStack |
| Testing | Swift Testing (342 unit tests) + XCTest (22 UI tests) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Treehole iOS App                    │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   Views    │  │  ViewModels  │  │     Models      │  │
│  │ (19 files) │→ │  (5 files)   │→ │   (9 files)     │  │
│  └────────────┘  └──────────────┘  └─────────────────┘  │
│       │                │                    │            │
│  ┌────▼───────────────────────────────────▼──────────┐  │
│  │          Services (8) & Utilities (12)             │  │
│  │  Supabase · CloudPostAPI · PetChat · PetVoice    │  │
│  │  Weather · Location · Analytics · AudioRecorder  │  │
│  │  L10n · NotificationService · PhotoStorage       │  │
│  │  AudioStorage · PrivacyLockManager · WeekAnchor  │  │
│  │  JournalSearch · JournalTranscription            │  │
│  │  HiddenPostsStore · UITestSupport · MoodByDay    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         │                    │                 │
   ┌─────▼──────┐    ┌────────▼──────┐   ┌─────▼──────┐
   │  SwiftData │    │  Supabase     │   │  CloudKit  │
   │  + CloudKit│    │  PostgreSQL   │   │  (photos)  │
   │  (local)   │    │  Edge Funcs   │   └────────────┘
   └────────────┘    │  MiniMax AI   │
                     └───────────────┘
```

Cloud-post network calls go through the `CloudPostAPI` protocol (`Services/CloudPostAPI.swift`) — a dependency-injection seam so view models can be tested against fakes; `LiveCloudPostAPI` forwards to `SupabaseService` in production.

---

## File Structure

```
Treehole/Treehole/                          (59 Swift files)
├── TreeholeApp.swift                        # @main entry, SwiftData container (never auto-deletes the store — moves it aside as Backup-* on unrecoverable failure)
├── ContentView.swift                        # Onboarding gate + TabView (5 tabs)
├── InfoPlist.xcstrings                      # Localized iOS permission dialogs (en + zh-Hans)
├── Models/                                  # 9 files — SwiftData @Model classes + enums
│   ├── ChatMessage.swift                    # Pet chat history
│   ├── ChatMode.swift                       # Pet chat modes (enum)
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
│   ├── EconomyViewModel.swift
│   ├── PetViewModel.swift
│   └── PostMigrationCoordinator.swift       # Persisted retry for device→account post migration
├── Views/
│   ├── Onboarding/                          # 4-page onboarding flow
│   ├── Cloud/                               # 4 files: list, create, reaction components, My Clouds
│   ├── Pet/                                 # 4 files: home, cat art, chat, voice selector
│   ├── Plant/                               # 2 files: garden, plant visuals
│   ├── Journal/                             # 3 files: journal + editor, entry detail, mood stats
│   ├── Shop/                                # Economy & store
│   ├── Settings/                            # 2 files: main settings, debug panel (Debug builds only)
│   ├── Auth/                                # LoginPromptView
│   └── PrivacyLockView.swift                # Passcode gate & biometric unlock
├── Services/                                # 8 files
│   ├── AnalyticsService.swift
│   ├── AudioRecorder.swift                  # 5-min cap — capped takes finalized & attached
│   ├── CloudPostAPI.swift                   # DI seam: cloud-post network protocol + live impl
│   ├── LocationService.swift
│   ├── PetChatService.swift
│   ├── PetVoiceService.swift
│   ├── SupabaseService.swift
│   └── WeatherService.swift
├── Utilities/                               # 12 files
│   ├── AudioStorage.swift
│   ├── HiddenPostsStore.swift               # Hidden/blocked clouds (report/hide) — UserDefaults persisted
│   ├── JournalSearch.swift
│   ├── JournalTranscription.swift
│   ├── L10n.swift
│   ├── MoodByDay.swift                      # One-pass day→mood lookup for the week strip
│   ├── NotificationService.swift
│   ├── PhotoStorage.swift
│   ├── PhotoThumbnailLoader.swift           # Async, cached, downsampled photo thumbnails
│   ├── PrivacyLockManager.swift
│   ├── UITestSupport.swift                  # Debug-only --uitest-reset-state launch hook
│   └── WeekAnchor.swift                     # Monday-anchored week math
├── Theme/
│   └── TreeholeTheme.swift
└── Components/                              # 3 files
    ├── AudioPlayerView.swift
    ├── CameraPicker.swift
    └── SharedComponents.swift               # MoodPicker (pills / pleasantness slider)

TreeholeTests/                               # 341 unit tests (Swift Testing)
TreeholeUITests/                             # 22 UI tests (XCTest)
```

---

## Database (Supabase)

Supabase project URL: `https://gjtiqwkhrepwhtoyjeix.supabase.co`

| Table / View | Purpose |
|---|---|
| `cloud_posts` | Anonymous posts (apple_user_id, device_id) |
| `cloud_comments` | Comments on posts |
| `cloud_reactions` | Breeze / hug / starlight reactions (unique per device per post) |
| `grabbed_posts` | Tracks which posts each user has already grabbed (apple_user_id or device_id), prevents duplicates |
| `npc_reply_templates` | Pre-written NPC response templates |
| `post_reports` | User reports of cloud posts (post_id, reporter_device_id, reason; one report per device per post; insert-only for anonymous clients) — **pending migration, see TODO below** |
| `post_reaction_counts` | View: aggregated reaction counts per post |
| `reported_posts_summary` | View: reported posts ranked by report count for manual review — **pending migration, see TODO below** |
| `analytics_events` | Anonymous analytics events (device_id, event name, properties) |

**Edge Functions:** `moderate-post`, `generate-npc-reply`, `pet-chat`, `pet-tts`, `summarize-journal` (all proxy MiniMax — API key stays server-side via `MINIMAX_API_KEY` env var)

**RPCs:**

| RPC | Purpose |
|---|---|
| `get_random_post(device_id, apple_user_id)` | Returns an un-grabbed post for the user and records the grab; falls back to oldest-grabbed when exhausted |
| `get_my_posts(device_id, apple_user_id)` | The user's own posts for My Clouds (matches either identity) |
| `get_my_unread_count(device_id, apple_user_id)` | Unread comment/reaction counts for check-in notifications |
| `migrate_posts_to_apple_user(p_device_id, p_apple_user_id)` | Re-attributes guest posts to the Apple account after sign-in |
| `delete_my_posts(requesting_device_id, requesting_apple_user_id)` | Account deletion: wipes the user's cloud posts (matches device_id OR apple_user_id, SECURITY DEFINER) |

**TODO — pending server-side migration #1:** `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` adds a `delete_my_data` RPC that also wipes the user's comments and reactions server-side. Review it against the live schema and run it in the Supabase SQL editor. The client already calls `rpc/delete_my_data` first and transparently falls back to `delete_my_posts` + client-side cleanup while the function is missing (PostgREST 404).

**TODO — pending server-side migration #2:** `supabase/migrations/20260717_post_reports.sql` creates the `post_reports` table (insert-only for anonymous clients, one report per device per post) and the `reported_posts_summary` review view behind the in-app "Report Cloud" button. Until it is run, report uploads fail silently server-side — the local hide still always works. After running it, review `reported_posts_summary` periodically and delete offending posts.

---

## Getting Started

1. Clone the repo and open `Treehole/Treehole.xcodeproj` in Xcode 26+.
2. Select an iOS 26 simulator (e.g. iPhone 17 Pro).
3. Configure Xcode capabilities: iCloud (CloudKit + Documents), Push Notifications, Sign In with Apple, Keychain Sharing.
4. Add your Supabase credentials (URL + anon key) to `SupabaseService.swift` or a local config file.
5. Build and run (`Cmd+R`). Guest mode works without credentials; Supabase features require the backend keys.

---

## Testing

```bash
# Build verification
cd /Users/jimmychen/Treehole/Treehole
xcodebuild -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20

# Run all tests (unit + UI)
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30
```

Or use the Makefile shortcuts from the repo root: `make test` (unit only, ~15s), `make test-full` (unit + UI), `make build`, `make archive`.

**Current test count:** 364 total (342 unit tests via Swift Testing + 22 UI tests via XCTest)

---

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| Phase 1 | Core loop: onboarding, cloud posts, pet, plant, journal | Complete |
| Phase 2 | Economy, shop, tasks, streaks, bilingual, push notifications | Complete |
| Phase 3 | Apple Sign-In, CloudKit sync, privacy lock, reactions, drift bottle social | Complete |
| Phase 4 | UI polish (Figma designs), animation refinement, more AI features | Current |
| Phase 5 | App Store prep, TestFlight external beta, IAP | Planned |

---

## Credits

Built at **Toki Studio**.

Contributions welcome — please keep bilingual resources (EN/ZH) in sync and run the full test suite before submitting.

**[Privacy Policy](https://c-square04.github.io/Treehole/privacy.html)**

</details>

---

<details>
<summary>中文版本</summary>

## 项目概览

Treehole（树洞）是一款 iOS 匿名情绪表达与温柔自愈应用。灵感源自"把秘密说进树洞"的古老意象——用户将心情化为**漂流瓶云朵**飘向共享的云层，任何陌生人都能"抓住一朵云"阅读、用微风 / 拥抱 / 星光回应，并收到 AI 驱动的 NPC 留言。除漂流瓶外，用户还可以养一只卡通猫宠物、照料多种植物花园、写私密日记——全部收录于一款温暖、中英双语的应用中。

- **Bundle ID：** com.csquare04.Treehole
- **平台：** iOS 17.0+（通用 — iPhone + iPad，横屏自适应分栏），SwiftUI + SwiftData + CloudKit + @Observable，Swift 6
- **后端：** Supabase（PostgreSQL + Edge Functions）
- **AI：** MiniMax M2.7-highspeed，通过 Supabase Edge Functions 代理（内容审核、NPC 回复、宠物聊天、宠物 TTS、日记智能摘要 + 自动语言识别）
- **发布渠道：** TestFlight（Toki Studio）

---

## 功能一览

| 模块 | 已实现内容 |
|---|---|
| 漂流瓶云朵 | 匿名发帖、"抓一朵云"随机浏览（服务端按用户记录已抓取记录，不会重复）、评论、微风/拥抱/星光三种反应（含视觉特效）、我的云朵管理页、三层内容审核、举报云朵（4 种理由可选）或隐藏某作者的全部云朵——隐藏立即在本地生效（设备端持久化），抓云时自动跳过已隐藏/已屏蔽的云朵，举报上传为尽力而为 |
| 虚拟宠物 | 心情动画卡通猫、喂食/抚摸/休息互动、饥饿值/精力/经验值/等级系统、4 套家居主题、喂食消耗食物货币 |
| 植物花园 | 最多 5 株植物、5 种植物种类、每种 5 个成长阶段、浇水获得经验值、定制植物视觉艺术 |
| 日记 | **16 种心情标签，可用胶囊按钮或一维愉悦度滑条选择（仅基于愉悦度——旧日记的 2D 心情坐标会被保留，除非用户主动拖动滑条才会改写）**、全新编辑器，浮动底栏（相机/照片/录音/位置/日期/更多）、可选标题、编辑已有日记、搜索文本/标题/语音转写/位置、双日期（事件日期 + 写作日期）、照片支持（最多 10 张，iCloud 同步）、语音备忘（m4a，5 分钟上限——达到上限的录音会被保留并附加到日记，Apple Speech 中英自动转写）、可选位置标签（精确 GPS + 反向解析地名）、添加位置时自动通过 Open-Meteo 获取当地天气、心情周历带状视图、心情统计页（周/月/**真正的年视图，12 个月心情网格**，全部按事件日期统计）、心情分布图、地点地图（按心情着色的可点击 marker → 进入日记详情）、连续打卡追踪、条目详情视图、AI 洞察卡片 + 每周自动摘要（**以周一为起点，有新日记时自动重新生成**）+ 单条 AI 摘要（用户授权后，渲染 markdown） |
| 通知 | 每日上午 9 点签到（固定文案——未读回复数改由应用启动时的检查推送）、傍晚 6 点宠物提醒、应用启动时本地通知未读互动（6 小时节流）、喂食/浇水提醒 |
| 数据分析 | 通过 Supabase `analytics_events` 表的匿名事件追踪 — fire-and-forget，永不阻塞 UI，永不记录用户内容文本 |
| 经济系统 | 食物/装饰代币/宝石三种货币、4 类每日任务（标题在渲染时本地化）、4 类每周挑战、登录连续奖励、每日登录奖励每天仅可领取一次（持久化存储）、CloudKit 同步产生的重复 Economy/DailyTask 行会在加载时去重、商店（用代币购买食物） |
| 隐私锁 | 苹果风格 4 位数字密码（Keychain 存储）、FaceID/TouchID、独立锁定我的云朵和/或日记、密码输入前的闸门页面、应用进入后台时自动重新上锁 |
| 新手引导 | 4 页流程：欢迎、功能介绍、隐私与别名说明、开始（Apple 登录或游客模式） |
| 设置 | 账户、别名说明、隐私锁、外观（语言/深色模式）、iCloud 同步状态页（真实 CKContainer.accountStatus 检测，需 Apple 登录）、完整账户删除（云端清除失败时安全中止——不动任何本地数据；同时删除用户的评论/反应；优先调用 `delete_my_data` RPC，迁移执行前自动透明回退到 `delete_my_posts` + 客户端清理）、内容管理（恢复已隐藏的云朵/作者）、[隐私政策](https://c-square04.github.io/Treehole/privacy.html)、开发者调试面板（仅 Debug 构建，连击 5 次版本号触发） |
| 身份验证 | Apple Sign-In（ASAuthorizationAppleIDCredential）、游客模式、设备帖子迁移至账户（持久化重试——启动/回到前台时自动重试直至成功） |
| iCloud 同步 | SwiftData + CloudKit 同步本地数据（宠物/植物/日记/经济），iCloud 容器存储日记照片，Supabase 存储社交数据；SwiftData 存储永不自动删除——遇到不可恢复的错误时会被移到 `Backup-*` 备份后重建 |
| 推送通知 | 喂食提醒（4 小时）、浇水提醒（24 小时）、每日签到（上午 9 点） |
| 双语本地化 | 全界面英文 + 简体中文，L10n.t() 贯穿全局，运行时语言切换，iOS 系统权限弹窗通过 InfoPlist.xcstrings 本地化（简体中文） |
| 无障碍 | 日记、宠物、植物、商店、设置、引导、隐私锁与云朵界面全面添加 VoiceOver 标签/特征；原先固定小字号文本改用动态字体（Dynamic Type）；循环/弹簧动画在"减弱动态效果"开启时停用 |
| 开发者面板 | 仅 Debug 构建的调试面板：宠物/植物/经济数值滑条、快捷操作、设备信息（连击 5 次解锁） |

---

## 技术栈

| 层级 | 详情 |
|---|---|
| 语言 | Swift 6（严格并发，MainActor 隔离） |
| UI | SwiftUI + iOS 26 Liquid Glass 材质 |
| 状态管理 | @Observable（非 ObservableObject） |
| 持久化 | SwiftData（@Model 类）+ CloudKit 同步 |
| 社交后端 | Supabase（PostgreSQL、REST API、Edge Functions） |
| AI | MiniMax M2.7-highspeed（审核 + NPC 回复） |
| 身份验证 | Apple Sign-In（ASAuthorizationController） |
| 照片 | PhotosUI（图片选择器）、iCloud 容器 |
| 生物识别 | LocalAuthentication（FaceID/TouchID） |
| 钥匙串 | Security 框架（密码存储） |
| 通知 | UserNotifications 框架 |
| 导航 | TabView（5 标签）+ NavigationStack |
| 测试 | Swift Testing（342 个单元测试）+ XCTest（22 个 UI 测试） |

---

## 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    Treehole iOS 应用                    │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   视图层   │  │  视图模型层  │  │    数据模型层    │  │
│  │ (19 个文件)│→ │  (5 个文件)  │→ │  (9 个文件)     │  │
│  └────────────┘  └──────────────┘  └─────────────────┘  │
│       │                │                    │            │
│  ┌────▼───────────────────────────────────▼──────────┐  │
│  │          服务层（8）与工具层（12）                │  │
│  │  Supabase · CloudPostAPI · PetChat · PetVoice    │  │
│  │  Weather · Location · Analytics · AudioRecorder  │  │
│  │  L10n · NotificationService · PhotoStorage       │  │
│  │  AudioStorage · PrivacyLockManager · WeekAnchor  │  │
│  │  JournalSearch · JournalTranscription            │  │
│  │  HiddenPostsStore · UITestSupport · MoodByDay    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         │                    │                 │
   ┌─────▼──────┐    ┌────────▼──────┐   ┌─────▼──────┐
   │  SwiftData │    │  Supabase     │   │  CloudKit  │
   │  + CloudKit│    │  PostgreSQL   │   │（照片存储） │
   │ （本地数据）│    │  Edge Funcs   │   └────────────┘
   └────────────┘    │  MiniMax AI   │
                     └───────────────┘
```

云朵帖子的网络调用统一经过 `CloudPostAPI` 协议（`Services/CloudPostAPI.swift`）——这是一个依赖注入接缝，测试中可注入假实现；生产环境由 `LiveCloudPostAPI` 转发到 `SupabaseService`。

---

## 文件结构

```
Treehole/Treehole/                          （共 59 个 Swift 文件）
├── TreeholeApp.swift                        # @main 入口，SwiftData 容器（永不自动删除存储——不可恢复时移为 Backup-* 备份）
├── ContentView.swift                        # 引导闸门 + TabView（5 标签）
├── InfoPlist.xcstrings                      # iOS 权限弹窗本地化（英文 + 简体中文）
├── Models/                                  # 9 个文件 — SwiftData @Model 类 + 枚举
│   ├── ChatMessage.swift                    # 宠物聊天记录
│   ├── ChatMode.swift                       # 宠物聊天模式（枚举）
│   ├── CloudPost.swift                      # + MoodTag（16 种心情，含愉悦度/唤醒度坐标）
│   ├── Economy.swift                        # Economy + DailyTask
│   ├── JournalEntry.swift
│   ├── JournalSummary.swift                 # AI 每周 / 单条摘要
│   ├── Pet.swift
│   ├── Plant.swift
│   └── WeeklyChallenge.swift
├── ViewModels/                              # 5 个文件
│   ├── AppState.swift
│   ├── CloudPostViewModel.swift
│   ├── EconomyViewModel.swift
│   ├── PetViewModel.swift
│   └── PostMigrationCoordinator.swift       # 设备→账户帖子迁移的持久化重试
├── Views/
│   ├── Onboarding/                          # 4 页新手引导
│   ├── Cloud/                               # 4 个文件：列表、发帖、反应组件、我的云朵
│   ├── Pet/                                 # 4 个文件：宠物家园、猫咪绘制、聊天、语音选择
│   ├── Plant/                               # 2 个文件：花园、植物视觉
│   ├── Journal/                             # 3 个文件：日记 + 编辑器、条目详情、心情统计
│   ├── Shop/                                # 经济系统与商店
│   ├── Settings/                            # 2 个文件：主设置、调试面板（仅 Debug 构建）
│   ├── Auth/                                # LoginPromptView 登录提示
│   └── PrivacyLockView.swift                # 密码闸门与生物识别解锁
├── Services/                                # 8 个文件
│   ├── AnalyticsService.swift
│   ├── AudioRecorder.swift                  # 5 分钟上限——达上限的录音会被完整保存并附加
│   ├── CloudPostAPI.swift                   # 依赖注入接缝：云朵网络调用协议 + 生产实现
│   ├── LocationService.swift
│   ├── PetChatService.swift
│   ├── PetVoiceService.swift
│   ├── SupabaseService.swift
│   └── WeatherService.swift
├── Utilities/                               # 12 个文件
│   ├── AudioStorage.swift
│   ├── HiddenPostsStore.swift               # 已隐藏/已屏蔽云朵（举报/隐藏）——UserDefaults 持久化
│   ├── JournalSearch.swift
│   ├── JournalTranscription.swift
│   ├── L10n.swift
│   ├── MoodByDay.swift                      # 周历条按天取心情的一次遍历查询
│   ├── NotificationService.swift
│   ├── PhotoStorage.swift
│   ├── PhotoThumbnailLoader.swift           # 异步、带缓存的降采样照片缩略图
│   ├── PrivacyLockManager.swift
│   ├── UITestSupport.swift                  # 仅 Debug 的 --uitest-reset-state 启动钩子
│   └── WeekAnchor.swift                     # 以周一为起点的周计算
├── Theme/
│   └── TreeholeTheme.swift
└── Components/                              # 3 个文件
    ├── AudioPlayerView.swift
    ├── CameraPicker.swift
    └── SharedComponents.swift               # MoodPicker（胶囊按钮 / 愉悦度滑条）

TreeholeTests/                               # 342 个单元测试（Swift Testing）
TreeholeUITests/                             # 22 个 UI 测试（XCTest）
```

---

## 数据库（Supabase）

Supabase 项目 URL：`https://gjtiqwkhrepwhtoyjeix.supabase.co`

| 表 / 视图 | 用途 |
|---|---|
| `cloud_posts` | 匿名帖子（含 apple_user_id、device_id） |
| `cloud_comments` | 帖子评论 |
| `cloud_reactions` | 微风/拥抱/星光反应（每设备每帖唯一） |
| `grabbed_posts` | 按用户记录已抓取的云朵（apple_user_id 优先，否则 device_id），避免重复 |
| `npc_reply_templates` | NPC 预设回复模板 |
| `post_reports` | 用户对云朵的举报（post_id、reporter_device_id、reason；每设备每帖限一次举报；匿名客户端仅可插入）——**待执行迁移，见下方 TODO** |
| `post_reaction_counts` | 视图：每帖反应数聚合统计 |
| `reported_posts_summary` | 视图：被举报的帖子按举报次数排序，供人工审阅——**待执行迁移，见下方 TODO** |
| `analytics_events` | 匿名分析事件（device_id、事件名、属性） |

**Edge Functions：** `moderate-post`、`generate-npc-reply`、`pet-chat`、`pet-tts`、`summarize-journal`（全部代理 MiniMax — API key 保存在服务端 `MINIMAX_API_KEY` 环境变量）

**RPC 函数：**

| RPC | 用途 |
|---|---|
| `get_random_post(device_id, apple_user_id)` | 为用户返回未抓取过的云朵并记录这次抓取；全部抓完后回退到最早抓取的那一条 |
| `get_my_posts(device_id, apple_user_id)` | 返回用户自己的帖子，用于"我的云朵"页面（两种身份任一匹配） |
| `get_my_unread_count(device_id, apple_user_id)` | 未读评论/反应计数，用于签到通知 |
| `migrate_posts_to_apple_user(p_device_id, p_apple_user_id)` | Apple 登录后将游客帖子归属到 Apple 账户 |
| `delete_my_posts(requesting_device_id, requesting_apple_user_id)` | 账户删除：清除用户的云朵帖子（匹配 device_id 或 apple_user_id，SECURITY DEFINER） |

**TODO——待执行的服务端迁移 #1：** `supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql` 新增 `delete_my_data` RPC，在服务端一并清除用户的评论和反应。请先对照线上 schema 审阅，然后在 Supabase SQL 编辑器中执行。客户端已优先调用 `rpc/delete_my_data`，在函数尚不存在时（PostgREST 404）自动透明回退到 `delete_my_posts` + 客户端清理。

**TODO——待执行的服务端迁移 #2：** `supabase/migrations/20260717_post_reports.sql` 创建 `post_reports` 表（匿名客户端仅可插入，每设备每帖限一次举报）与 `reported_posts_summary` 审阅视图，支撑应用内的"举报云朵"按钮。执行前，举报上传会在服务端静默失败——本地隐藏始终生效。执行后请定期查看 `reported_posts_summary` 并删除违规帖子。

---

## 快速开始

1. 克隆仓库，用 Xcode 26+ 打开 `Treehole/Treehole.xcodeproj`。
2. 选择 iOS 26 模拟器（如 iPhone 17 Pro）。
3. 配置 Xcode 能力：iCloud（CloudKit + 文档）、推送通知、Sign In with Apple、钥匙串共享。
4. 在 `SupabaseService.swift` 或本地配置文件中填入 Supabase 凭据（URL + anon key）。
5. 按 `Cmd+R` 编译运行。游客模式无需凭据；Supabase 功能需要后端密钥。

---

## 测试

```bash
# 编译验证
cd /Users/jimmychen/Treehole/Treehole
xcodebuild -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20

# 运行全部测试（单元测试 + UI 测试）
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30
```

也可以在仓库根目录使用 Makefile 快捷命令：`make test`（仅单元测试，约 15 秒）、`make test-full`（单元 + UI）、`make build`、`make archive`。

**当前测试总数：** 364（342 个单元测试，Swift Testing + 22 个 UI 测试，XCTest）

---

## 迭代路线图

| 阶段 | 目标 | 状态 |
|---|---|---|
| Phase 1 | 核心闭环：引导、云帖、宠物、植物、日记 | 已完成 |
| Phase 2 | 经济系统、商店、任务、签到、双语、推送通知 | 已完成 |
| Phase 3 | Apple 登录、CloudKit 同步、隐私锁、反应功能、漂流瓶社交 | 已完成 |
| Phase 4 | UI 精修（Figma 设计稿）、动效优化、更多 AI 功能 | 当前阶段 |
| Phase 5 | App Store 上架、TestFlight 公测、内购 | 规划中 |

---

## 致谢

由 **Toki Studio** 开发。

欢迎贡献代码 — 请保持中英双语资源同步更新，并在提交前运行完整测试套件。

**[隐私政策](https://c-square04.github.io/Treehole/privacy.html)**

</details>
