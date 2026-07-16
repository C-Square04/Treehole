-- UGC report mechanism (App Review guideline 1.2).
--
-- The iOS client's "Report" button inserts a row here (best effort) and
-- always hides the post locally for the reporter. Rows are for YOUR review:
-- check reports periodically and delete offending posts from cloud_posts.
--
-- HOW TO APPLY: paste into the Supabase SQL editor and run.

create table if not exists post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references cloud_posts(id) on delete cascade,
  reporter_device_id text not null,
  reason text,
  created_at timestamptz not null default now(),
  -- One report per device per post keeps spam-reporting bounded.
  unique (post_id, reporter_device_id)
);

alter table post_reports enable row level security;

-- Anonymous clients may only insert reports — never read, update, or delete.
create policy "anon can insert reports"
  on post_reports for insert
  to anon
  with check (true);

-- Optional helper: every reported post, most-reported first.
create or replace view reported_posts_summary as
select p.id, p.text, p.author_alias, p.created_at,
       count(r.id) as report_count,
       max(r.created_at) as last_reported_at
from cloud_posts p
join post_reports r on r.post_id = p.id
group by p.id, p.text, p.author_alias, p.created_at
having count(r.id) >= 1
order by count(r.id) desc, max(r.created_at) desc;
