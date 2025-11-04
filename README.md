# Treehole

<details>
<summary>English Version</summary>

## Overview
- Anonymous emotional support app blending drifting-cloud venting, virtual pet companionship, and mindful plant care.
- Built for iOS 17+ with SwiftUI, Combine, Core Data/CloudKit; privacy-first, pressure-free community.
- Ships with Chinese/English locale and introduces AI features gradually.

## Experience Pillars
- **Emotion Release** – Floating cloud posts, instant NPC replies, translation toggle.
- **Comforting Companions** – Virtual pet & plant ecosystems with mood feedback and journaling.
- **Guided Wellbeing** – Daily rituals, journaling prompts, subtle reminders.
- **Sustainable Progression** – Multi-currency economy, décor unlocks, missions, seasonal events.
- **Trust & Safety** – Session aliases, layered moderation, transparent privacy controls.

## Feature Highlights
| Module | Key Notes |
| --- | --- |
| Cloud Venting | Anonymous posts, curated guest feed, NPC reply, EN/ZN translation button |
| Virtual Pet | Hunger = AI quota, décor customization, idle animation, journal nook |
| Plant Growth | Daily watering, growth stages, themed variants |
| Voice Layers | Apple TTS baseline → Backend Piper/F5 fallback → Volcengine TTS for subscribers → MegaTTS3 custom voices (future) |
| Missions & Rewards | Daily/weekly tasks, streak bonuses, surprise gifts |
| Identity & Privacy | Device-scoped aliases, local username only, data export/delete |

## Monetization
- **Free Tier**：Cloud venting, check-ins, base pet/plant loops, lightweight voice (Apple TTS or backend Piper/F5).
- **Pro Plan (Monthly)**：Higher AI chat quota, exclusive décor, monthly food pack, premium Volcengine voice lines, 7-day free trial.
- **Voice Upgrades**：MegaTTS3-based custom voices planned as advanced add-ons once stable.
- **Battle Pass & Store**：Tiered rewards, décor bundles, consumables.
- **One-off Purchases**：Food packs, outfits, themed décor.

## AI & Voice Strategy
1. **Moderation & NPC**：DeepSeek API primary; OpenAI/GPT-4o-mini or rule-based fallback.
2. **Voice Layering**：
   - Apple AVSpeechSynthesizer: instant, offline baseline.
   - Backend Piper/F5-TTS: guest/free users & outage fallback.
   - Volcengine (Doubao) TTS: premium voice packs for subscribers with emotion controls.
   - MegaTTS3: internal pilot → offline packs & custom voice cloning for future paid tiers.
3. **Safety & Compliance**：Consent prompts, encrypted storage, model monitoring, auto-renew compliance reminders.

## Tech Stack
- **Client**：SwiftUI, Combine, NavigationStack, Lottie/SpriteKit, AVFoundation, Speech Framework.
- **Data Layer**：URLSession/Alamofire, Core Data cache, optional CloudKit sync.
- **Backend**：Serverless (Cloud Functions/Supabase) for posts, economy, AI gateway; MongoDB Atlas / Supabase Postgres options.
- **DevOps**：Fastlane CI, TestFlight, Xcode Cloud UI tests, App Center/Amplitude analytics.

## Roadmap Snapshot
| Phase | Focus | Key Deliverables |
| --- | --- | --- |
| A · MVP | Core loop | Guest mode, aliasing, rule-based moderation, base pet/plant |
| B · Experience | Immersion | Animations, décor, journaling rewards, missions, push + localisation |
| C · AI Elevation | AI/Voice foundations | DeepSeek moderation, AI pet chat, MegaTTS3 prototype validation |
| D · Monetization | Revenue systems | Subscription, battle pass, voice store, Volcengine rollout |
| E · Expansion | Advanced ops | MegaTTS3 custom voice beta, voice journaling, ops tooling |

## Repository Guide
- `DesignDocument.md` – full product & technical spec (Chinese).
- `README.md` – quick overview (English + Chinese tabs).
- Planned directories: `docs/` (wireframes, APIs), `client/`, `server/`.

## Getting Started
1. Read `DesignDocument.md` for specs, economy, AI plans.
2. Produce wireframes & flows per roadmap before implementation.
3. Establish voice stack: Apple baseline, backend Piper/F5 fallback, Volcengine credentials, MegaTTS3 pilot env.
4. Build Milestone A, instrument analytics, then unlock AI/voice per roadmap.

## Communication & Support
- Capture risks/feedback at milestone reviews.
- Complete legal/privacy reviews before launching voice cloning.
- Contributions welcome—maintain bilingual resources for the team.

</details>

<details>
<summary>中文版本</summary>

## 项目概览
- 面向匿名情绪宣泄与陪伴的 iOS 应用，融合漂浮云吐槽、虚拟宠物、植物养成等自愈机制。
- 基于 iOS 17+（SwiftUI/Combine/Core Data/CloudKit），强调隐私、安全与无压力社区。
- 默认中英双语，AI 能力分阶段灰度上线。

## 核心体验支柱
- **情绪释放**：漂浮云发帖、NPC 秒回、翻译按钮。
- **温柔陪伴**：虚拟宠物/植物生态，情绪反馈与日记角。
- **引导仪式**：每日签到、写作提示、柔和提醒。
- **长期动力**：多货币系统、装饰解锁、任务与节日活动。
- **信任安全**：会话别名、分层审核、透明隐私说明。

## 核心功能模块
| 模块 | 要点 |
| --- | --- |
| 漂浮云倾诉 | 匿名发帖、精选游客流、NPC 回复、翻译切换 |
| 虚拟宠物 | 饥饿=AI 配额、家园装饰、闲置动画、日记入口 |
| 植物养成 | 每日浇水、成长阶段、主题变种 |
| 语音体系 | Apple TTS 基线 → 后端 Piper/F5 fallback → 豆包 TTS 订阅层 → MegaTTS3 自定义声线（后期） |
| 任务奖励 | 日/周任务、连续签到、惊喜礼盒 |
| 身份隐私 | 设备级别名、本地存真实用户名、数据导出/删除 |

## 变现策略
- **免费层**：漂浮云、签到、基础宠物/植物、轻量语音（Apple TTS 或后端 Piper/F5）。
- **订阅（月卡/Pro）**：更高 AI 对话额度、专属装饰、月度食物包、豆包高级声线、7 天试用。
- **声线升级**：MegaTTS3 定制声线作为后期高级增值服务。
- **战令与商店**：阶梯奖励、装饰礼包、消耗品。
- **单次充值**：食物包、服饰、主题套装。

## AI 与语音策略
1. **审核与 NPC**：DeepSeek 为主，OpenAI/GPT-4o-mini 或规则引擎兜底。
2. **语音分层**：  
   - Apple AVSpeechSynthesizer：离线即时基线。  
   - 后端 Piper/F5-TTS：游客/免费用户与故障 fallback。  
   - 火山引擎豆包 TTS：订阅声线，支持情绪参数。  
   - MegaTTS3：内部试点 → 离线语音包 + 声线克隆增值。  
3. **安全合规**：语音采集授权提示、加密存储、模型切换监控、试用自动续费合规提醒。

## 技术栈
- **客户端**：SwiftUI、Combine、NavigationStack、Lottie/SpriteKit、AVFoundation、Speech Framework。
- **数据层**：URLSession/Alamofire、Core Data 缓存，可选 CloudKit 同步。
- **后端**：Serverless（Cloud Functions/Supabase）负责帖子、经济、AI 网关；数据库可选 MongoDB Atlas/Supabase Postgres。
- **工程运维**：Fastlane 自动化、TestFlight 发布、Xcode Cloud UI 测试、App Center/Amplitude 分析。

## 迭代路线图
| 阶段 | 目标 | 关键交付 |
| --- | --- | --- |
| A · MVP | 核心闭环 | 游客模式、别名、规则审核、基础宠物/植物 |
| B · 体验强化 | 沉浸打磨 | 动效、装饰、日记奖励、任务、推送+本地化 |
| C · AI 提升 | AI/语音基础 | DeepSeek 审核、AI 宠物聊天、MegaTTS3 原型验证 |
| D · 商业化 | 收益体系 | 订阅、战令、声线商店、豆包声线上线 |
| E · 拓展运营 | 高阶体验 | MegaTTS3 自定义声线内测、语音日记、运营工具 |

## 仓库说明
- `DesignDocument.md`：详细产品与技术设计（中文）。  
- `README.md`：中英简介（折叠版）。  
- TODO：`docs/` 原型与 API、`client/` 客户端、`server/` 后端等。

## 起步指南
1. 阅读 `DesignDocument.md`，掌握规格、经济与 AI 方案。
2. 按路线图绘制线框与流程，再进入开发。
3. 搭建语音体系：Apple TTS → 后端 Piper/F5 → 豆包 TTS → MegaTTS3 试点环境。
4. 先完成里程碑 A，补充埋点监控，再逐步解锁 AI/语音能力。

## 沟通与支持
- 每阶段复盘记录风险与反馈。
- 自定义声线开放前完成法律/隐私审查。
- 欢迎贡献与本地化建议，持续维护双语资料。

</details>
