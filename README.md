# Treehole

<details open>
<summary>English Version</summary>

## Overview

Treehole is an iOS 26 app for anonymous emotional expression and gentle self-care. Users can vent via floating cloud posts, raise a virtual pet, tend a multi-plant garden, and keep a private journal — all within a single cozy space. The app ships with full English/Chinese bilingual support and a warm Liquid Glass design.

- **Bundle ID:** com.Toki.Treehole
- **Platform:** iOS 26, SwiftUI + SwiftData + @Observable
- **Creators:** Jimmy Chen & Kayli Cheung

---

## Features

| Module | What's Implemented |
|---|---|
| Clouds | Anonymous posts, NPC template replies, delete; EN/ZH toggle |
| Pet | Feed / pet / rest interactions; XP, levels, hunger/happiness/energy stats; unlockable themes |
| Garden | 5 plant species, per-species growth stages, daily watering, multi-plant support |
| Journal | Mood-tagged entries, daily writing prompts, entry history |
| Shop | Buy pet food with tokens; economy (food / tokens / gems) |
| Tasks | 4 daily task types, 4 weekly challenge types |
| Streaks | Login streak tracking with tiered rewards |
| Notifications | Push reminders for feeding, watering, and daily check-in |
| Onboarding | 4-page flow with alias privacy explanation |
| Localization | Full EN/ZH throughout; system locale detection |
| Design | iOS 26 Liquid Glass, dark mode, warm macaroon palette |

---

## Screenshots

_Coming soon — TestFlight build in progress._

---

## Tech Stack

| Layer | Details |
|---|---|
| Language | Swift 6 (strict concurrency, MainActor isolation) |
| UI | SwiftUI, iOS 26 Liquid Glass materials |
| State | @Observable (not ObservableObject) |
| Persistence | SwiftData (@Model classes) |
| Navigation | TabView (5 tabs) + NavigationStack |
| Notifications | UserNotifications framework |
| Testing | XCTest — 65 unit tests + 18 UI tests |

---

## Getting Started

1. Clone the repo and open `Treehole/Treehole.xcodeproj` in Xcode 26+.
2. Select an iOS 26 simulator (e.g. iPhone 17 Pro).
3. Build and run (`Cmd+R`) — no API keys or backend required for the local build.
4. To run all tests: `Cmd+U` or see the test commands in `DEVELOPMENT_WORKFLOW.md`.

---

## Testing

```bash
# Build verification
cd /Users/jimmychen/Treehole/Treehole
xcodebuild -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20

# Run all tests
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30
```

**Current test count:** 83 total (65 unit + 18 UI)

---

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| Phase 1 | Core loop: onboarding, cloud, pet, plant, journal | Complete |
| Phase 2 | Economy, shop, tasks, streaks, bilingual, notifications | Complete |
| Phase 3 | UI polish to Figma designs, animation refinement | Next up |
| Phase 4 | Backend: real posts, social features, moderation | Planned |
| Phase 5 | App Store submission, TestFlight beta, analytics | Planned |

---

## Credits

Built by **Jimmy Chen** & **Kayli Cheung**.

Contributions welcome — please keep bilingual resources (EN/ZH) in sync.

</details>

---

<details>
<summary>中文版本</summary>

## 项目概览

Treehole 是一款 iOS 26 自愈类应用，融合匿名漂浮云发帖、虚拟宠物陪伴、多植物花园养成与私密日记功能，界面采用温暖马卡龙配色与 Liquid Glass 设计语言，全程支持中英双语。

- **Bundle ID：** com.Toki.Treehole
- **平台：** iOS 26，SwiftUI + SwiftData + @Observable
- **开发者：** Jimmy Chen & Kayli Cheung

---

## 功能一览

| 模块 | 已实现内容 |
|---|---|
| 漂浮云 | 匿名发帖、NPC 模板回复、删除帖子；中英切换 |
| 虚拟宠物 | 喂食 / 抚摸 / 休息互动；经验值、等级、饥饿/快乐/精力属性；可解锁主题 |
| 花园 | 5 种植物、各自成长阶段、每日浇水、多植物并行养成 |
| 日记 | 心情标签记录、每日写作提示、历史条目浏览 |
| 商店 | 用 Token 购买宠物食物；三种货币体系（食物 / Token / 宝石） |
| 任务 | 4 类每日任务、4 类每周挑战 |
| 签到连续奖励 | 登录连续天数追踪与阶梯奖励 |
| 推送通知 | 喂食、浇水、每日签到提醒 |
| 引导流程 | 4 页新手引导，含别名隐私说明 |
| 本地化 | 全界面中英双语，自动跟随系统语言 |
| 设计 | iOS 26 Liquid Glass、深色模式、马卡龙暖色调 |

---

## 截图

_即将上线 — TestFlight 构建中。_

---

## 技术栈

| 层级 | 详情 |
|---|---|
| 语言 | Swift 6（严格并发，MainActor 隔离） |
| UI | SwiftUI + iOS 26 Liquid Glass 材质 |
| 状态管理 | @Observable（非 ObservableObject） |
| 持久化 | SwiftData（@Model 类） |
| 导航 | TabView（5 标签）+ NavigationStack |
| 通知 | UserNotifications 框架 |
| 测试 | XCTest — 65 个单元测试 + 18 个 UI 测试 |

---

## 快速开始

1. 克隆仓库，用 Xcode 26+ 打开 `Treehole/Treehole.xcodeproj`。
2. 选择 iOS 26 模拟器（如 iPhone 17 Pro）。
3. 按 `Cmd+R` 编译运行 — 本地版本无需 API Key 或后端服务。
4. 运行全部测试：`Cmd+U`，或参考 `DEVELOPMENT_WORKFLOW.md` 中的命令行方式。

---

## 测试

```bash
# 编译验证
cd /Users/jimmychen/Treehole/Treehole
xcodebuild -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "(error:|BUILD)" | tail -20

# 运行全部测试
xcodebuild test -project Treehole.xcodeproj -scheme Treehole \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -30
```

**当前测试总数：** 83（65 单元测试 + 18 UI 测试）

---

## 迭代路线图

| 阶段 | 目标 | 状态 |
|---|---|---|
| Phase 1 | 核心闭环：引导、云帖、宠物、植物、日记 | 已完成 |
| Phase 2 | 经济系统、商店、任务、签到、双语、通知 | 已完成 |
| Phase 3 | UI 精修（对齐 Figma 设计稿）、动效优化 | 下一阶段 |
| Phase 4 | 后端：真实帖子、社交功能、内容审核 | 规划中 |
| Phase 5 | App Store 上架、TestFlight 公测、数据分析 | 规划中 |

---

## 致谢

由 **Jimmy Chen** 与 **Kayli Cheung** 共同开发。

欢迎贡献代码 — 请保持中英双语资源同步更新。

</details>
