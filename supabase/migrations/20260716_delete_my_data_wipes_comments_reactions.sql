-- Account deletion: extend the wipe to comments and reactions.
--
-- WHY: delete_my_posts() only deletes rows from cloud_posts. Comments and
-- reactions the user left on OTHER people's posts stay behind. The client now
-- best-effort deletes them via the REST API (device_id filter + x-device-id
-- header), but that cannot reach rows created under an older device_id after
-- a reinstall — only a SECURITY DEFINER function matching on apple_user_id
-- can. This function fills that gap.
--
-- HOW TO APPLY: paste into the Supabase SQL editor and run. Review the
-- column names against the live schema first (assumed below:
--   cloud_comments(device_id, apple_user_id, ...)
--   cloud_reactions(device_id, ...)
-- If cloud_reactions has no apple_user_id column, the function below already
-- handles that by matching reactions on device_id only.)
--
-- NOTE: the iOS client already calls rpc/delete_my_data FIRST and falls back
-- to delete_my_posts + client-side comment/reaction cleanup only while this
-- function is missing (PostgREST 404). Applying this migration simply moves
-- the whole wipe server-side — no client change needed.

create or replace function delete_my_data(
  requesting_device_id text,
  requesting_apple_user_id text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_posts integer;
begin
  -- Comments this user left anywhere (own posts' comments die with the post
  -- via FK cascade, but comments on others' posts need explicit deletion).
  delete from cloud_comments
  where device_id = requesting_device_id
     or (requesting_apple_user_id is not null
         and apple_user_id = requesting_apple_user_id);

  -- Reactions this user left anywhere (reactions carry device_id only).
  delete from cloud_reactions
  where device_id = requesting_device_id;

  -- Posts (same matching rule as the existing delete_my_posts).
  delete from cloud_posts
  where device_id = requesting_device_id
     or (requesting_apple_user_id is not null
         and apple_user_id = requesting_apple_user_id);
  get diagnostics deleted_posts = row_count;

  return deleted_posts;
end;
$$;

-- Allow the anon role to call it (same exposure as delete_my_posts).
grant execute on function delete_my_data(text, text) to anon;
