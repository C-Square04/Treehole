# Treehole · 树洞

## Overview · 项目概览
- Anonymous emotional support app combining drifting clouds, virtual pets, and plant care to build gentle self-care rituals.  
  面向希望匿名倾诉与陪伴的用户，结合漂浮云吐槽、虚拟宠物、植物养成等轻疗愈机制。
- iOS 17+ first release with SwiftUI, Combine, Core Data/CloudKit；prioritise privacy, safety, and a pressure-free community.  
  首发聚焦 iOS 17+，使用 SwiftUI/Combine/Core Data/CloudKit，强调匿名与安全体验。
- Multi-language by default (Chinese/English) and gradual rollout of AI capabilities in controlled phases.  
  默认支持中英双语，AI 能力分阶段灰度上线。

## Experience Pillars · 核心体验支柱
- **Emotion Release · 情绪释放**：Drifting-cloud posts with instant NPC replies and optional translation toggle.  
- **Comforting Companions · 温柔陪伴**：Virtual pet & plant loops with mood feedback, rewards, and journaling nook.  
- **Guided Wellbeing · 引导仪式**：Daily check-ins, journaling prompts, subtle nudges.  
- **Sustainable Progression · 长期动力**：Currencies, décor, missions, seasonal events.  
- **Trust & Safety · 信任安全**：Session aliases, layered moderation, transparent privacy controls.

## Feature Highlights · 核心功能
| Module | 功能模块 | Key Notes · 要点 |
| --- | --- | --- |
| Cloud Venting | 漂浮云倾诉 | Anonymous posts, NPC response, translation button, curated guest feed |
| Virtual Pet | 虚拟宠物 | Hunger=AI quota, décor, idle animation, journaling mini-space |
| Plant Growth | 植物养成 | Daily watering, growth stages, seasonal variants |
| Voice Layers | 语音体系 | Apple TTS baseline → Backend Piper/F5 fallback → Volcengine TTS for subscribers → MegaTTS3 for future custom voices |
| Journeys & Missions | 任务体系 | Daily/weekly missions, streak rewards, surprise gifts |
| Identity & Privacy | 身份与隐私 | Device-scoped aliases, local username storage, export/delete options |

## Monetization · 变现策略
- **Free Tier · 免费层**：漂浮云、签到、基础宠物/植物、轻量语音（Apple TTS or backend Piper/F5）。  
- **Pro Plan · 订阅（月卡）**：Higher AI chat quota, exclusive décor, monthly food packs, premium voice lines via Volcengine TTS, 7-day free trial.  
- **Voice Upgrades · 声线升级**：Planned MegaTTS3 custom voice packs as advanced paid add-ons post-stabilisation.  
- **Battle Pass & Store · 战令与商店**：Tiered rewards, décor bundles, consumables.  
- **One-off Purchases · 单次充值**：Food packs, outfits, theme bundles.

## AI & Voice Strategy · AI 与语音策略
1. **Moderation & NPC Replies**：DeepSeek API primary, OpenAI/GPT-4o-mini/local rules as fallback.  
2. **Voice Layering**：  
   - Apple AVSpeechSynthesizer for instant, offline-friendly baseline.  
   - Backend Piper/F5-TTS for guest/free users or outages.  
   - Volcengine (豆包) TTS for Pro voice packs with emotional parameters.  
   - MegaTTS3 internal pilot → custom voice cloning & offline packages in later phases.  
3. **Safety & Compliance**：Voice data consent prompts, encrypted storage, model switch monitoring, trial auto-renew compliance reminders.

## Tech Stack · 技术栈
- **Client · 客户端**：SwiftUI, Combine, NavigationStack, Lottie/SpriteKit for motion, AVFoundation, Speech Framework.  
- **Data Layer · 数据层**：URLSession/Alamofire, Core Data caching, optional CloudKit sync.  
- **Backend · 后端**：Serverless (Cloud Functions/Supabase) for posts, economy, AI gateway; databases such as MongoDB Atlas / Supabase Postgres.  
- **DevOps · 工程**：Fastlane automation, TestFlight distribution, Xcode Cloud UI tests, App Center/Amplitude analytics.

## Roadmap Snapshot · 迭代里程碑
| Phase | 目标 | 重点交付 |
| --- | --- | --- |
| A · MVP | Core posting & pet loop | Guest mode, aliasing, rule-based moderation, base pet/plant cycles |
| B · Experience | Immersive polish | Animations, décor, journaling rewards, tasks, push + localisation |
| C · AI Elevation | AI & Voice foundations | DeepSeek moderation, AI pet chats, MegaTTS3 prototype validation |
| D · Monetization | 商业化 | Subscription, battle pass, voice store, Volcengine TTS rollout |
| E · Expansion | 高阶体验 | MegaTTS3 custom voices beta, voice journals, advanced events, ops tooling |

## Repository Guide · 仓库指引
- `DesignDocument.md`：完整产品与技术设计（中文）。  
- `README.md`：High-level overview (English + 中文).  
- 待扩展：`/docs` 用于原型、API 规格；`/client`、`/server` 等目录将随开发逐步补充。

## Getting Started · 起步指南
1. **Read the Design Document** (`DesignDocument.md`) for detailed specs, economy design, and AI plans.  
   阅读 `DesignDocument.md` 获取完整规格、经济系统与 AI 策略。  
2. **Prototype & Wireframes**：Create UI flows based on the roadmap before coding.  
   根据里程碑绘制关键界面流程图，再进入开发阶段。  
3. **Establish Voice Infrastructure**：  
   - Configure Apple TTS fallback and backend Piper/F5 services.  
   - Set up Volcengine TTS credentials for Pro tier.  
   - Begin controlled MegaTTS3 deployment tests.  
4. **Iterate & Measure**：Implement milestone A first, instrument analytics, then follow roadmap with gated AI/voice rollouts.  
   优先完成里程碑 A，加入埋点监控，再按路线图逐步解锁 AI 与语音能力。

## Community & Support · 沟通与支持
- Document risk/feedback at each milestone review.  
  每轮里程碑复盘记录风险与反馈。  
- Prepare legal/privacy reviews before launching voice cloning features.  
  自定义声线上线前需完成法律与隐私合规审查。  
- Contributions & localized feedback welcome—maintain both English and Chinese resources for the team.  
  欢迎贡献与本地化反馈，持续维护中英双语资料。
