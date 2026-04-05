# Treehole

<details open>
<summary>English Version</summary>

## Overview

Treehole is an iOS app for anonymous emotional expression and gentle self-care. Inspired by the ancient idea of whispering secrets into a tree hollow, users release feelings as **drift bottle clouds** that float in a shared sky — any stranger can "grab a cloud" and read it, react with a breeze, hug, or starlight, and leave an NPC-powered reply. Alongside the cloud space, users raise a virtual cat, tend a multi-plant garden, and keep a private journal — all within one cozy, bilingual app.

- **Bundle ID:** com.Toki.Treehole
- **Platform:** iOS 26, SwiftUI + SwiftData + CloudKit + @Observable, Swift 6
- **Backend:** Supabase (PostgreSQL + Edge Functions)
- **AI:** MiniMax M2.7-highspeed (content moderation + NPC replies)
- **Creators:** Jimmy Chen & Kayli Cheung / Toki Studio

---

## Features

| Module | What's Implemented |
|---|---|
| Drift Bottle Clouds | Anonymous posting, "grab a cloud" for random posts, comments, reactions (breeze / hug / starlight) with visual effects, My Clouds management, 3-layer content moderation |
| Virtual Pet | Cartoon cat with mood-based animations, feed / pet / rest actions, hunger / energy / XP / level system, 4 home themes, feeding costs food currency |
| Plant Garden | Up to 5 plants, 5 species, 5 growth stages per species, watering grants XP, custom plant visual art |
| Journal | Mood-tagged entries, photo support (up to 3 photos, iCloud synced), mood week calendar strip, mood statistics (week / month / year), mood distribution chart, streak tracking, entry detail view |
| Economy | Food / Decoration Tokens / Gems currencies, 4 daily task types, 4 weekly challenge types, login streak rewards, shop (buy food with tokens) |
| Privacy Lock | Apple-style 4-digit passcode (Keychain stored), FaceID / TouchID, lock My Clouds and/or Journal independently, gate page before passcode entry |
| Onboarding | 4-page flow: welcome, features, privacy & aliases, get started (Apple Sign-In or Guest) |
| Settings | Account, alias explanation, privacy lock, appearance (language / dark mode), iCloud sync status, privacy policy, hidden developer debug panel (5-tap version trigger) |
| Authentication | Apple Sign-In (ASAuthorizationAppleIDCredential), Guest mode, device-to-account migration |
| iCloud Sync | SwiftData + CloudKit for local data (pet / plant / journal / economy), iCloud ubiquity container for journal photos, Supabase for social data |
| Push Notifications | Feeding reminder (4 h), watering reminder (24 h), daily check-in (9 AM) |
| Localization | Full English + Simplified Chinese, L10n.t() throughout, runtime language switch |
| Developer Panel | Hidden debug panel: pet / plant / economy sliders, quick actions, device info (5-tap unlock) |

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
| Testing | XCTest — 84+ unit tests + 21 UI tests |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Treehole iOS App                    │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   Views    │  │  ViewModels  │  │     Models      │  │
│  │ (17 files) │→ │  (4 files)   │→ │   (6 files)     │  │
│  └────────────┘  └──────────────┘  └─────────────────┘  │
│       │                │                    │            │
│  ┌────▼───────────────────────────────────▼──────────┐  │
│  │               Services & Utilities                │  │
│  │  SupabaseService · L10n · NotificationService    │  │
│  │  PhotoStorage · PrivacyLockManager               │  │
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

---

## File Structure

```
Treehole/Treehole/                          (36 Swift files)
├── TreeholeApp.swift                        # @main entry, SwiftData container
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
│   ├── Pet/                                 # 2 files: home, interactions
│   ├── Plant/                               # 2 files: garden, plant detail
│   ├── Journal/                             # 3 files: list, editor, mood stats
│   ├── Shop/                                # Economy & store
│   ├── Settings/                            # 2 files: main settings, debug panel
│   ├── Auth/                                # Auth flow
│   └── PrivacyLock/                         # Passcode gate & biometric unlock
├── Services/
│   └── SupabaseService.swift
├── Utilities/
│   ├── L10n.swift
│   ├── NotificationService.swift
│   ├── PhotoStorage.swift
│   └── PrivacyLockManager.swift
├── Theme/
│   └── TreeholeTheme.swift
└── Components/
    └── SharedComponents.swift

TreeholeTests/                               # 84+ unit tests
TreeholeUITests/                             # 21 UI tests
```

---

## Database (Supabase)

Supabase project URL: `https://gjtiqwkhrepwhtoyjeix.supabase.co`

| Table / View | Purpose |
|---|---|
| `cloud_posts` | Anonymous posts (apple_user_id, device_id) |
| `cloud_comments` | Comments on posts |
| `cloud_reactions` | Breeze / hug / starlight reactions (unique per device per post) |
| `npc_reply_templates` | Pre-written NPC response templates |
| `post_reaction_counts` | View: aggregated reaction counts per post |

**Edge Functions:** `moderate-post` (MiniMax moderation), `generate-npc-reply`

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

**Current test count:** 105 total (84+ unit tests + 21 UI tests)

---

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| Phase 1 | Core loop: onboarding, cloud posts, pet, plant, journal | Complete |
| Phase 2 | Economy, shop, tasks, streaks, bilingual, push notifications | Complete |
| Phase 3 | Apple Sign-In, CloudKit sync, privacy lock, reactions, drift bottle social | Complete |
| Phase 4 | UI polish (Figma designs), animation refinement, more AI features | Current |
| Phase 5 | App Store prep, TestFlight beta, analytics | Planned |

---

## Credits

Built by **Jimmy Chen** & **Kayli Cheung** at **Toki Studio**.

Contributions welcome — please keep bilingual resources (EN/ZH) in sync and run the full test suite before submitting.

</details>

---

<details>
<summary>中文版本</summary>

## 项目概览

Treehole（树洞）是一款 iOS 匿名情绪表达与温柔自愈应用。灵感源自"把秘密说进树洞"的古老意象——用户将心情化为**漂流瓶云朵**飘向共享的云层，任何陌生人都能"抓住一朵云"阅读、用微风 / 拥抱 / 星光回应，并收到 AI 驱动的 NPC 留言。除漂流瓶外，用户还可以养一只卡通猫宠物、照料多种植物花园、写私密日记——全部收录于一款温暖、中英双语的应用中。

- **Bundle ID：** com.Toki.Treehole
- **平台：** iOS 26，SwiftUI + SwiftData + CloudKit + @Observable，Swift 6
- **后端：** Supabase（PostgreSQL + Edge Functions）
- **AI：** MiniMax M2.7-highspeed（内容审核 + NPC 回复）
- **开发者：** Jimmy Chen & Kayli Cheung / Toki Studio

---

## 功能一览

| 模块 | 已实现内容 |
|---|---|
| 漂流瓶云朵 | 匿名发帖、"抓一朵云"随机浏览、评论、微风/拥抱/星光三种反应（含视觉特效）、我的云朵管理页、三层内容审核 |
| 虚拟宠物 | 心情动画卡通猫、喂食/抚摸/休息互动、饥饿值/精力/经验值/等级系统、4 套家居主题、喂食消耗食物货币 |
| 植物花园 | 最多 5 株植物、5 种植物种类、每种 5 个成长阶段、浇水获得经验值、定制植物视觉艺术 |
| 日记 | 心情标签记录、照片支持（最多 3 张，iCloud 同步）、心情周历带状视图、心情统计页（周/月/年）、心情分布图、连续打卡追踪、条目详情视图 |
| 经济系统 | 食物/装饰代币/宝石三种货币、4 类每日任务、4 类每周挑战、登录连续奖励、商店（用代币购买食物） |
| 隐私锁 | 苹果风格 4 位数字密码（Keychain 存储）、FaceID/TouchID、独立锁定我的云朵和/或日记、密码输入前的闸门页面 |
| 新手引导 | 4 页流程：欢迎、功能介绍、隐私与别名说明、开始（Apple 登录或游客模式） |
| 设置 | 账户、别名说明、隐私锁、外观（语言/深色模式）、iCloud 同步状态页、隐私政策、隐藏开发者调试面板（连击 5 次版本号触发） |
| 身份验证 | Apple Sign-In（ASAuthorizationAppleIDCredential）、游客模式、设备迁移至账户 |
| iCloud 同步 | SwiftData + CloudKit 同步本地数据（宠物/植物/日记/经济），iCloud 容器存储日记照片，Supabase 存储社交数据 |
| 推送通知 | 喂食提醒（4 小时）、浇水提醒（24 小时）、每日签到（上午 9 点） |
| 双语本地化 | 全界面英文 + 简体中文，L10n.t() 贯穿全局，运行时语言切换 |
| 开发者面板 | 隐藏调试面板：宠物/植物/经济数值滑条、快捷操作、设备信息（连击 5 次解锁） |

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
| 测试 | XCTest — 84+ 单元测试 + 21 UI 测试 |

---

## 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    Treehole iOS 应用                    │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   视图层   │  │  视图模型层  │  │    数据模型层    │  │
│  │ (17 个文件)│→ │  (4 个文件)  │→ │  (6 个文件)     │  │
│  └────────────┘  └──────────────┘  └─────────────────┘  │
│       │                │                    │            │
│  ┌────▼───────────────────────────────────▼──────────┐  │
│  │               服务与工具层                        │  │
│  │  SupabaseService · L10n · NotificationService    │  │
│  │  PhotoStorage · PrivacyLockManager               │  │
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

---

## 文件结构

```
Treehole/Treehole/                          （共 36 个 Swift 文件）
├── TreeholeApp.swift                        # @main 入口，SwiftData 容器
├── ContentView.swift                        # 引导闸门 + TabView（5 标签）
├── Models/                                  # 6 个 SwiftData @Model 类
│   ├── CloudPost.swift
│   ├── Pet.swift
│   ├── Plant.swift
│   ├── JournalEntry.swift
│   ├── Economy.swift
│   └── WeeklyChallenge.swift
├── ViewModels/                              # 4 个 @Observable 类
│   ├── AppState.swift
│   ├── CloudPostViewModel.swift
│   ├── PetViewModel.swift
│   └── EconomyViewModel.swift
├── Views/
│   ├── Onboarding/                          # 4 页新手引导
│   ├── Cloud/                               # 4 个文件：列表、发帖、详情、我的云朵
│   ├── Pet/                                 # 2 个文件：宠物家园、互动
│   ├── Plant/                               # 2 个文件：花园、植物详情
│   ├── Journal/                             # 3 个文件：列表、编辑器、心情统计
│   ├── Shop/                                # 经济系统与商店
│   ├── Settings/                            # 2 个文件：主设置、调试面板
│   ├── Auth/                                # 身份验证流程
│   └── PrivacyLock/                         # 密码闸门与生物识别解锁
├── Services/
│   └── SupabaseService.swift
├── Utilities/
│   ├── L10n.swift
│   ├── NotificationService.swift
│   ├── PhotoStorage.swift
│   └── PrivacyLockManager.swift
├── Theme/
│   └── TreeholeTheme.swift
└── Components/
    └── SharedComponents.swift

TreeholeTests/                               # 84+ 单元测试
TreeholeUITests/                             # 21 UI 测试
```

---

## 数据库（Supabase）

Supabase 项目 URL：`https://gjtiqwkhrepwhtoyjeix.supabase.co`

| 表 / 视图 | 用途 |
|---|---|
| `cloud_posts` | 匿名帖子（含 apple_user_id、device_id） |
| `cloud_comments` | 帖子评论 |
| `cloud_reactions` | 微风/拥抱/星光反应（每设备每帖唯一） |
| `npc_reply_templates` | NPC 预设回复模板 |
| `post_reaction_counts` | 视图：每帖反应数聚合统计 |

**Edge Functions：** `moderate-post`（MiniMax 审核）、`generate-npc-reply`

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

**当前测试总数：** 105（84+ 单元测试 + 21 UI 测试）

---

## 迭代路线图

| 阶段 | 目标 | 状态 |
|---|---|---|
| Phase 1 | 核心闭环：引导、云帖、宠物、植物、日记 | 已完成 |
| Phase 2 | 经济系统、商店、任务、签到、双语、推送通知 | 已完成 |
| Phase 3 | Apple 登录、CloudKit 同步、隐私锁、反应功能、漂流瓶社交 | 已完成 |
| Phase 4 | UI 精修（Figma 设计稿）、动效优化、更多 AI 功能 | 当前阶段 |
| Phase 5 | App Store 上架、TestFlight 公测、数据分析 | 规划中 |

---

## 致谢

由 **Jimmy Chen** 与 **Kayli Cheung** 在 **Toki Studio** 共同开发。

欢迎贡献代码 — 请保持中英双语资源同步更新，并在提交前运行完整测试套件。

</details>
