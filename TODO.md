# TODO — Jimmy's action items

Things only you can do (Claude noted these during the 2026-07-17 health pass).
Delete items as you finish them.

## 1. ~~Run the Supabase migrations~~ — DONE 2026-07-17
Applied via the Management API and verified live:
- `delete_my_data` RPC exists (SECURITY DEFINER, search_path=public) — anon
  call with fake ids returns 0 instead of 404
- `post_reports` table live with insert-only RLS for anon; anon SELECT
  returns no rows
- `reported_posts_summary` view live; anon/authenticated SELECT is revoked
  (42501) — moderation queue is not world-readable
- `delete_my_data` upgraded to wipe reactions by apple_user_id too
  (`cloud_reactions.apple_user_id` already existed and the client now sends it)
- Bonus hardening: `delete_my_posts` and `get_my_unread_count` also got
  `search_path = public` pinned
- History rows recorded in `supabase_migrations.schema_migrations`, so a
  future `supabase db push` (e.g. to a self-hosted instance) won't re-apply
- Remaining habit: check `reported_posts_summary` occasionally and delete
  offending posts.

## 2. Review AppStoreMetadata.md wording (10 min)
- The old file claimed "no data collected / 100% local / no network requests" —
  false since Supabase shipped, and an App Review rejection risk. Claude
  rewrote the claims to be accurate (see the Privacy Nutrition Label and
  Review Notes sections).
- Read it once and adjust the marketing voice to your taste before submission.
- Also decide the age rating: the cloud space is user-generated content, so
  App Review guideline 1.2 expects moderation (you have it, 3 layers) plus a
  user-facing way to report/flag a post — the app now has both: "Report Cloud"
  (4 reasons) and "Hide Clouds from This Author" on strangers' clouds, and the
  server side (post_reports + reported_posts_summary) is live since
  2026-07-17. Remember to check `reported_posts_summary` periodically.
  Current draft says 4+ — UGC apps usually rate 12+; decide before submission.

## 3. ~~Verify localized permission dialogs~~ — DONE 2026-07-17
- Verified in the release archive (build 15): `zh-Hans.lproj/InfoPlist.strings`
  exists in Treehole.app, alongside `PrivacyInfo.xcprivacy`.
- Optional: switch a device to Chinese and trigger the camera/mic prompt once
  to see the localized dialog live.

## 4. Before next TestFlight archive
- `CURRENT_PROJECT_VERSION` is 16 (15 was already taken on App Store Connect).
  Next time: bump before archiving.
- `make test-full` should be green (344 unit + 22 UI as of the report/hide +
  accessibility batch).
