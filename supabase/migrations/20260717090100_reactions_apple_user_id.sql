-- Close the account-deletion gap for reactions left by signed-in users.
--
-- WHY: cloud_reactions only carries device_id, so delete_my_data() cannot
-- reach reactions created under an older device_id (e.g. before a reinstall).
-- Adding apple_user_id lets the wipe match a signed-in user's reactions no
-- matter which device/install left them. Guests (no Apple ID) are unaffected —
-- their reactions stay tied to the current device_id only.
--
-- The iOS client starts sending apple_user_id on new reactions immediately
-- and retries once without it if the column is missing (PostgREST 400), so
-- this migration can be applied at any time, in any order with the client.
--
-- HOW TO APPLY: paste into the Supabase SQL editor and run. Idempotent.

alter table cloud_reactions
  add column if not exists apple_user_id text;

-- Same body as 20260716's delete_my_data, except the reactions delete now
-- also matches apple_user_id. Replaces that version.
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

  -- Reactions this user left anywhere — now matched on BOTH identities.
  delete from cloud_reactions
  where device_id = requesting_device_id
     or (requesting_apple_user_id is not null
         and apple_user_id = requesting_apple_user_id);

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
