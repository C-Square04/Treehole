# Treehole — Real-Device QA Checklist / 真机 QA 测试清单

Test on a physical iPhone with iOS 18.1+, plus an iPad (or iPad simulator) for the split-view items. Run through each item in both English and Chinese modes.
请在搭载 iOS 18.1+ 的真机上测试，分栏相关条目另需 iPad（或 iPad 模拟器）。分别在英文和中文模式下完成所有条目。

---

## Onboarding / 新手引导

- [ ] Page 1 (Welcome) displays correctly with app icon and tagline / 第 1 页（欢迎）正确显示应用图标与标语
- [ ] Page 2 (Features) lists all main features without layout overflow / 第 2 页（功能介绍）列出所有主要功能，无布局溢出
- [ ] Page 3 (Privacy & Aliases) explains alias system clearly / 第 3 页（隐私与别名）清晰说明别名系统
- [ ] Page 4 (Get Started) shows "Continue as Guest" and "Sign in with Apple" buttons / 第 4 页（开始）显示"游客模式"和"Apple 登录"按钮
- [ ] Swiping left/right navigates between pages smoothly / 左右滑动可在页面间流畅切换
- [ ] Language switch (EN ↔ ZH) on onboarding updates all text immediately / 新手引导中切换语言（英/中）后所有文字立即更新
- [ ] Tapping "Continue as Guest" skips to the main app / 点击"以游客身份继续"跳转至主界面
- [ ] Onboarding does NOT re-show on subsequent launches / 后续启动不再显示新手引导

---

## Cloud Posts / 漂流瓶云朵

- [ ] "Clouds" tab loads and shows the grab button or existing posts / "云朵"标签加载并显示抓取按钮或现有帖子
- [ ] Tapping "Grab a Cloud" fetches a random post (or shows no-more-clouds message) / 点击"抓一朵云"获取随机帖子（或显示无更多云朵的提示）
- [ ] Grabbed cloud shows post text, alias, mood tag, and reaction buttons / 抓到的云显示帖子内容、别名、心情标签和反应按钮
- [ ] Tapping "Breeze / Hug / Starlight" reaction increments the count / 点击"微风/拥抱/星光"反应，计数加一
- [ ] Writing a new cloud post saves and appears in "My Clouds" / 发布新云朵后，出现在"我的云朵"中
- [ ] Cloud post text is content-moderated (inappropriate text is rejected) / 云朵内容经过审核（不当内容被拒绝）
- [ ] Leaving a comment on a cloud post succeeds and displays the comment / 在云朵上留言成功并正确显示
- [ ] "My Clouds" tab shows only posts created by the current user / "我的云朵"仅显示当前用户发布的帖子
- [ ] Deleting own post removes it from "My Clouds" immediately / 删除自己的帖子后立即从"我的云朵"中消失
- [ ] Other users' posts cannot be deleted / 无法删除其他用户的帖子

---

## Pet / 虚拟宠物

- [ ] Pet tab loads and displays the cat with correct mood animation / 宠物标签加载并显示猫咪的对应心情动画
- [ ] Pet stats (hunger, energy, XP, level) are visible / 宠物属性（饥饿值、精力、经验值、等级）可见
- [ ] "Feed" button is enabled when food > 0 and decrements food count / 食物 > 0 时"喂食"按钮可用，点击后食物数量减少
- [ ] "Feed" button is disabled when food = 0 / 食物 = 0 时"喂食"按钮不可用
- [ ] Pet mood changes visually after feeding / 喂食后宠物心情动画发生变化
- [ ] Voice chat (microphone) opens and sends audio input to pet / 语音聊天（麦克风）打开并将音频发送给宠物
- [ ] Pet replies to voice chat with TTS audio / 宠物以 TTS 语音回复语音聊天
- [ ] Text chat sends a message and receives an AI NPC reply / 文字聊天发送消息并收到 AI NPC 回复
- [ ] Pet mood changes over time based on hunger/energy / 宠物心情随饥饿值/精力随时间变化

---

## Plant Garden / 植物花园

- [ ] Garden tab loads correctly / 花园标签正确加载
- [ ] First plant can be created from the empty state ("Plant a Seed") / 可从空白状态创建第一株植物（"播种"）
- [ ] Plant displays correct growth stage emoji/art / 植物显示正确的成长阶段表情/图示
- [ ] Watering a plant grants XP and shows water animation / 浇水为植物增加经验值并显示浇水动画
- [ ] Water button becomes unavailable after watering (cooldown) / 浇水后"浇水"按钮进入冷却状态不可用
- [ ] A second plant can be added via the "+" toolbar button (up to 5) / 可通过"+"工具栏按钮添加第二株植物（最多 5 株）
- [ ] Switching between plants via the plant selector updates the main display / 通过植物选择器切换植物，主视图更新
- [ ] Plant name and species are shown correctly for each plant / 每株植物的名称和种类正确显示

---

## Journal / 日记

- [ ] Journal tab loads and shows entry list or empty state / 日记标签加载并显示条目列表或空白状态
- [ ] Tapping "Write Entry" opens the editor / 点击"写日记"打开编辑器
- [ ] Writing text and saving creates a new journal entry / 输入文字并保存后创建新日记条目
- [ ] Mood selector shows all 16 mood options and toggles between pills and the pleasantness slider / 心情选择器显示全部 16 种心情，并可在胶囊按钮与愉悦度滑条之间切换
- [ ] Dragging the pleasantness slider updates the selected mood (nearest by valence) / 拖动愉悦度滑条时按愉悦度就近更新所选心情
- [ ] Opening an OLD entry (made with the former 2D meter) in slider mode and saving WITHOUT touching the slider leaves its mood and coordinates unchanged / 用滑条模式打开旧日记（曾用 2D 心情仪创建）且不动滑条直接保存，其心情与坐标保持不变
- [ ] Editing an existing entry saves the changes and updates the list / 编辑已有日记后保存，列表随之更新
- [ ] Attaching a photo from the library works and previews correctly / 从相册附加照片成功并正确预览
- [ ] Up to 10 photos can be attached per entry (a notice appears if photos are skipped over the limit) / 每条日记最多附加 10 张照片（超出上限被跳过时显示提示）
- [ ] Recording a voice note attaches it and auto-transcription appears (zh/en) / 录制语音备忘后成功附加，且自动转写出现（中/英）
- [ ] Recording up to the 5-minute cap auto-stops, KEEPS the take attached, and shows the limit notice / 录音达到 5 分钟上限时自动停止，录音被保留并附加，同时显示上限提示
- [ ] Saving the entry before transcription finishes still persists the transcript afterwards / 转写完成前保存日记，转写稍后仍会写入该日记
- [ ] Search finds entries by text, title, transcript, and location name / 搜索可按文字、标题、语音转写和位置名称找到日记
- [ ] Adding a location tags the entry and auto-fetches the weather (Open-Meteo) / 添加位置后日记带上位置标签并自动获取天气（Open-Meteo）
- [ ] Changing the event date (distinct from the write date) regroups the entry in the list and stats / 修改事件日期（区别于写作日期）后，日记在列表与统计中重新归组
- [ ] Per-entry AI summary generates and renders markdown (opt-in) / 单条 AI 摘要可生成并渲染 markdown（需用户开启）
- [ ] Weekly AI summary appears for the current Monday-anchored week and regenerates after a new entry is added / 每周 AI 摘要按周一起始的当前周显示，新增日记后会重新生成
- [ ] Entry detail view shows full text, mood, date, photos, voice note, and location/weather / 条目详情视图显示完整文字、心情、日期、照片、语音和位置/天气
- [ ] Mood calendar strip shows correct mood color for today / 心情周历带显示今日正确的心情颜色
- [ ] Stats view shows total entries, mood distribution, and streak count / 统计视图显示条目总数、心情分布和连续打卡天数
- [ ] Week / Month / Year filter switches the stats correctly / 周/月/年筛选器正确切换统计数据
- [ ] Year view shows a 12-month grid with each month's dominant mood (future months dimmed) / 年视图显示 12 个月网格及每月主导心情（未来月份变暗）

---

## Settings / 设置

- [ ] Settings page loads from the "Me" tab / 设置页面从"我"标签加载
- [ ] Language switch (EN ↔ ZH) in Settings updates the entire app UI immediately / 设置中切换语言（英/中）立即更新整个应用界面
- [ ] Dark mode toggle changes the app appearance / 深色模式开关切换应用外观
- [ ] Dark mode preference persists after app relaunch / 深色模式偏好在重启应用后保留
- [ ] Language preference persists after app relaunch / 语言偏好在重启应用后保留
- [ ] Passcode lock can be enabled and a 4-digit code set / 可启用密码锁并设置 4 位数字密码
- [ ] FaceID toggle enables biometric unlock when passcode is set / 设置密码后，FaceID 开关可启用生物识别解锁
- [ ] AI Insights toggle disables/enables AI features visibly / AI 洞察开关可见地开关 AI 功能
- [ ] iCloud sync status shows correct account state (signed in / not signed in) / iCloud 同步状态显示正确的账户状态（已登录/未登录）
- [ ] "Privacy Policy" link opens correctly / "隐私政策"链接正确打开
- [ ] Developer debug panel unlocks after 5 taps on the version number (Debug builds only — absent from TestFlight/Release builds) / 在版本号上连击 5 次后解锁开发者调试面板（仅 Debug 构建——TestFlight/Release 版本中不存在）

---

## Auth / 身份验证

- [ ] "Sign in with Apple" button on onboarding initiates the Apple auth flow / 新手引导中"使用 Apple 登录"按钮发起 Apple 认证流程
- [ ] Successful Apple Sign-In sets the user account and shows Apple user ID in debug info / Apple 登录成功后设置用户账户并在调试信息中显示 Apple 用户 ID
- [ ] Logout (Settings → Account → Sign Out) returns to onboarding / 退出登录（设置 → 账户 → 退出）返回新手引导
- [ ] Signing in again with the same Apple ID restores the account / 用相同 Apple ID 再次登录后恢复账户
- [ ] Guest-mode posts migrate to the Apple account after sign-in / 游客模式下的帖子在登录后迁移至 Apple 账户
- [ ] Signing in as a different Apple ID creates a separate account / 使用不同 Apple ID 登录创建单独账户

---

## Privacy Lock / 隐私锁

- [ ] Setting a 4-digit passcode shows a confirmation entry step / 设置 4 位数字密码时显示确认输入步骤
- [ ] Mismatched confirmation prevents passcode from being saved / 确认密码不匹配时阻止保存密码
- [ ] "Lock Clouds" toggle gates "My Clouds" behind the passcode / "锁定云朵"开关将"我的云朵"置于密码保护之后
- [ ] "Lock Journal" toggle gates the Journal tab behind the passcode / "锁定日记"开关将日记标签置于密码保护之后
- [ ] Entering the correct passcode unlocks the gated section / 输入正确密码解锁受保护区域
- [ ] Entering the wrong passcode shakes the input and shows an error / 输入错误密码时输入框抖动并显示错误提示
- [ ] FaceID unlock works when biometrics are enrolled and toggle is enabled / 已注册生物识别且开关开启时，FaceID 解锁正常工作
- [ ] Gate page (blurred background) shows before passcode entry / 输入密码前显示闸门页面（模糊背景）
- [ ] Changing the passcode requires the old passcode first / 更改密码前需先输入旧密码
- [ ] Removing the passcode disables all privacy locks / 删除密码后所有隐私锁被禁用
- [ ] Backgrounding the app re-locks all locked sections — returning requires passcode/FaceID again / 应用进入后台后所有已锁区域重新上锁——返回时需再次输入密码/FaceID

---

## iPad Split View / iPad 分栏

- [ ] In landscape, the Journal shows the entry list and detail side by side / 横屏时日记以左右分栏显示列表与详情
- [ ] Selecting an entry in the list updates the detail column / 在列表中选择日记后详情栏更新
- [ ] Deleting the entry shown in the detail column clears the detail (no stale/deleted entry rendered) / 删除详情栏中正在显示的日记后详情栏被清空（不渲染已删除的条目）
- [ ] Rotating between portrait and landscape preserves the current selection / 竖屏与横屏旋转切换后当前选中项保持不变

---

## Edge Cases / 边缘情况

- [ ] App behaves gracefully with no internet connection (offline mode) / 无网络连接时应用优雅降级（离线模式）
- [ ] Cloud post grab shows an appropriate error message when offline / 离线时抓取云朵显示适当的错误提示
- [ ] Backgrounding the app and returning keeps state intact / 将应用切换到后台再返回后，状态保持不变
- [ ] Force-quitting and relaunching the app restores all local data / 强制退出并重启应用后，所有本地数据恢复
- [ ] Delete All Data (Settings → Delete All Data) wipes local, iCloud, and server data / "删除所有数据"（设置 → 删除所有数据）清除本地、iCloud 和服务器数据
- [ ] Delete All Data also removes the user's comments and reactions on other people's posts / "删除所有数据"同时删除用户在他人帖子下的评论与反应
- [ ] Delete All Data with no network shows an error and deletes NOTHING locally (retry succeeds after reconnecting) / 无网络时"删除所有数据"显示错误且不删除任何本地数据（恢复网络后重试成功）
- [ ] After Delete All Data, the app restarts cleanly to onboarding / 删除所有数据后，应用干净地重启至新手引导
- [ ] Push notification for feeding reminder appears after ~4 hours without feeding / 约 4 小时未喂食后出现喂食提醒推送通知
- [ ] Push notification for watering reminder appears after ~24 hours without watering / 约 24 小时未浇水后出现浇水提醒推送通知
- [ ] Very long journal entry text does not overflow or crash the editor / 非常长的日记文字不会溢出或导致编辑器崩溃
- [ ] Rapid tab switching does not crash the app / 快速切换标签不会导致应用崩溃

---

## Bug Reports / 缺陷报告

Use the template below for each bug found during testing. Attach a screenshot or screen recording when possible.
使用以下模板记录测试中发现的每个缺陷，尽可能附上截图或屏幕录制。

```
**Bug Report / 缺陷报告**

Title / 标题:

Steps to Reproduce / 复现步骤:
1.
2.
3.

Expected Behavior / 预期行为:

Actual Behavior / 实际行为:

Device & OS / 设备与系统版本:

Language Mode / 语言模式:  [ ] English  [ ] 中文

Severity / 严重程度:  [ ] Crash  [ ] Major  [ ] Minor  [ ] Cosmetic

Screenshot / 截图:  (attach here)

Notes / 备注:
```
