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
  (4 reasons) and "Hide Clouds from This Author" on strangers' clouds. The
  server side of reporting only works after you run migration #2 above, and
  remember to check `reported_posts_summary` periodically once it's live.

## 3. Verify localized permission dialogs after next Xcode build (2 min)
- `Treehole/InfoPlist.xcstrings` was added for zh-Hans permission strings
  (camera/mic/location/photos/Face ID).
- After the next build in Xcode: Product → Show Build Folder, confirm
  `zh-Hans.lproj/InfoPlist.strings` exists in Treehole.app, or just switch a
  simulator to Chinese and trigger the camera permission prompt.
- If it didn't take: Xcode → project → Info → Localizations → add Chinese
  (Simplified), then rebuild.

## 4. Before next TestFlight archive
- Bump `CURRENT_PROJECT_VERSION` (last shipped build: 14).
- `make test-full` should be green (344 unit + 22 UI as of the report/hide +
  accessibility batch).
