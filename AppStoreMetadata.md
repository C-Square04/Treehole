# Treehole — App Store Metadata

---

## English

### App Name
Treehole - Emotional Wellness

### Subtitle
Anonymous venting, pet companion & plant care

### Keywords
mental health, wellness, journal, anonymous, pet, plant, mood tracker, self-care, mindfulness, diary

### Description
Treehole is your private, judgment-free space to express how you really feel.

Life can be overwhelming — sometimes you just need somewhere safe to let it out. Treehole gives you that space. Write freely in your personal journal, knowing your identity stays protected by a randomly generated alias that refreshes every 7 days.

While you process your emotions, your virtual pet and plants grow alongside you. Feed your companion, water your plants, and check in daily — because small acts of care add up, both for your digital world and your own wellbeing.

**Key Features:**
• Anonymous journaling with auto-rotating alias for true privacy
• Virtual pet companion that responds to your daily care
• Plant growing system that rewards consistent check-ins
• Mood tracking to reflect on your emotional journey
• Release feelings as drift-bottle clouds — strangers can send a breeze, a hug, or starlight
• Bilingual support: English & 中文
• Your journal stays private: on your device and in your personal iCloud — never on our servers
• No ads, no tracking — only what you choose to share as a cloud is ever posted

Your thoughts are yours alone. Treehole keeps them that way.

### Promotional Text
Your safe space for thoughts and feelings. Feed your pet, grow your plants, write your journal.

### Category
- Primary: Health & Fitness
- Secondary: Lifestyle

### Age Rating
4+

### Bundle ID
com.csquare04.Treehole

### Developer
Jimmy Chen & Kayli Cheung / Toki Studio

---

## 中文

### 应用名称
树洞 - 情绪陪伴

### 副标题
匿名倾诉、宠物陪伴、植物养成

### 关键词
心理健康, 情绪管理, 日记, 匿名, 宠物, 植物, 心情记录, 自我关怀, 正念, 减压

### 描述
树洞，是你专属的私密空间，让你自由表达内心真实的感受。

生活有时令人喘不过气——有时候，你只是需要一个安全的地方倾诉。树洞就是这样一个地方。用随机生成、每7天自动更换的专属别名保护你的真实身份，让你放心写下任何心里话，不必顾虑他人眼光。

在整理情绪的同时，你的虚拟宠物和植物也在陪伴着你一起成长。每天喂养你的伙伴、为植物浇水、坚持打卡签到——这些小小的日常关怀，会慢慢积累成内心的力量。

**核心功能：**
• 匿名日记，别名自动轮换，真正保护隐私
• 虚拟宠物陪伴，随日常互动成长
• 植物养成系统，坚持打卡获得奖励
• 情绪追踪，回顾自己的心情历程
• 把心情放进漂流瓶云朵，陌生人可以送你微风、拥抱或星光
• 双语支持：English & 中文
• 日记完全私密：只保存在你的设备和个人 iCloud 中，绝不上传到我们的服务器
• 无广告、无追踪——只有你主动分享的云朵才会被发布

你的心事，只属于你。树洞守护着这份秘密。

---

## App Store Privacy Nutrition Label

| Data Type | Collected | Linked to Identity | Used for Tracking |
|-----------|-----------|-------------------|-------------------|
| User Content (cloud posts, comments — only what the user chooses to share) | Yes | No (pseudonymous alias + device ID) | No |
| Identifiers (random device ID; Apple user ID if signed in) | Yes | No | No |
| Usage Data (anonymous feature analytics — event names and categorical metadata only, never content text) | Yes | No | No |

Journal entries, photos, voice notes, pet, and plant data are stored on-device
(SwiftData) and synced only to the user's private iCloud (CloudKit) — the
developer has no access to them.

### Privacy Manifest

`Treehole/Treehole/PrivacyInfo.xcprivacy` ships in the app bundle and mirrors
this label: no tracking, UserDefaults as the only required-reason API
(CA92.1), and the collected data types above (Device ID, User ID, product
interaction, other user content — none linked to identity, none used for
tracking). Keep the manifest and this label in sync when data practices change.

---

## Review Notes (for App Review team)

- Private data (journal, pet, plants, economy) is stored on-device with SwiftData and synced to the user's private CloudKit database. The developer cannot read it.
- The anonymous social feature ("clouds") posts user-chosen text to a Supabase backend. Content passes 3-layer moderation: client keyword check, server-side AI moderation (MiniMax via Supabase Edge Functions), and a database trigger.
- AI features (NPC replies, pet chat, opt-in journal summaries) call Supabase Edge Functions which proxy to MiniMax; no user identity is attached to these requests.
- Anonymous usage analytics are sent to the developer's Supabase database: event names and categorical metadata only, never journal or post text.
- Notifications are local only (UNUserNotificationCenter); no remote push server is used.
- The app does not require an account. A guest alias is auto-generated on first launch; Sign in with Apple is optional (enables cross-device post ownership).
- Test account: Not required — tap "Continue as Guest" on the welcome screen.
