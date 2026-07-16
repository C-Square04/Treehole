# TODO — Jimmy's action items

Things only you can do (Claude noted these during the 2026-07-17 health pass).
Delete items as you finish them.

## 1. Run the two Supabase migrations (10 min) — do this first
- Open the Supabase SQL editor for project `gjtiqwkhrepwhtoyjeix`.
- Review and run, in order:
  1. [supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql](supabase/migrations/20260716_delete_my_data_wipes_comments_reactions.sql)
     — sanity-check the column assumptions in the file header first
     (`cloud_comments.apple_user_id` existing, etc.).
  2. [supabase/migrations/20260717_post_reports.sql](supabase/migrations/20260717_post_reports.sql)
     — the report-post table behind the new in-app "Report" button.
- The iOS client calls `rpc/delete_my_data` first and silently falls back to
  the old `delete_my_posts` path until the function exists, so there is no
  deadline — but until you run #1, comments/reactions from re-installed
  devices can't be fully wiped on account deletion. Until you run #2,
  reports are hidden locally for the reporter but not recorded server-side.
- After #2: check `reported_posts_summary` in Supabase occasionally and
  delete offending posts.

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
- `make test-full` should be green (338 unit + 22 UI as of the report/hide +
  accessibility batch).
