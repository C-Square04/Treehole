# Privacy Policy for Treehole

**Last updated: April 7, 2026**

Treehole ("we", "our", or "the app") is built by Toki Studio. This privacy policy explains what information we collect, how we use it, and the choices you have.

## 1. What We Collect

**Anonymous content you post**
When you share a "cloud" (a short post), the text, mood tag, and an auto-generated alias (e.g. "Soft Stone") are stored on our backend. Posts are not linked to your real name. We assign each device an anonymous ID so you can edit or delete your own posts.

**Sign in with Apple (optional)**
If you choose to sign in with Apple, we store the Apple user identifier provided by Apple. We do not receive your real Apple ID, name, or email unless you explicitly share them. Signing in lets your posts sync across your devices via iCloud.

**Local data**
Journal entries, photos you attach, your virtual pet state, and garden state are stored locally on your device using SwiftData. If you enable iCloud, this data syncs through your private CloudKit container — only you can access it.

**Permissions**
- **Microphone & Speech Recognition** — used only when you talk to your pet companion. Audio is processed and discarded; nothing is recorded.
- **Photo Library** — used only when you attach a photo to a journal entry.
- **FaceID** — used only to unlock the app's privacy lock if you enable it. The biometric check happens entirely on your device.

## 2. How We Use Your Data

- **Cloud posts** are shown anonymously to other users in the public feed.
- **AI moderation and AI replies** — your post text is sent to our backend (Supabase Edge Functions), which forwards it to MiniMax for content moderation and to generate the NPC reply. We do not store this text outside of the cloud_posts table.
- **Device identifier** — used only to let you manage and delete your own posts.

We do **not** sell your data, share it with advertisers, or use it for tracking.

## 3. Storage and Third Parties

- **Supabase** — hosts our database and edge functions.
- **MiniMax** — AI provider used for content moderation and pet replies. Text is sent over HTTPS and not retained by us.
- **Apple iCloud / CloudKit** — stores your private journal, pet, and garden data in your own iCloud account. We have no access to it.

## 4. Your Choices

- **Delete your own post** — tap the menu on any cloud you authored.
- **Delete all your data** — Settings → Delete All Data. This wipes local data, iCloud sync data, and your cloud posts on the server.
- **Disable iCloud sync** — turn off iCloud for Treehole in iOS Settings.

## 5. Children

Treehole is not directed at children under 13. Please do not use the app if you are under 13.

## 6. Changes

We may update this policy. Material changes will be reflected by updating the "Last updated" date above.

## 7. Contact

Questions? Email: **toki.studio.app@gmail.com**
