create index if not exists profiles_org_role_idx on public.profiles(organization_id, role) where is_active;
create index if not exists teachers_org_profile_idx on public.teachers(organization_id, profile_id);
create index if not exists circles_org_teacher_idx on public.circles(organization_id, teacher_id) where is_active;
create index if not exists circle_students_active_idx on public.circle_students(circle_id, student_id) where left_at is null;
create index if not exists students_org_status_idx on public.students(organization_id, status);
create index if not exists student_guardians_guardian_idx on public.student_guardians(guardian_id, student_id);
create index if not exists memorization_student_date_idx on public.daily_memorization_records(student_id, record_date desc);
create index if not exists memorization_circle_date_idx on public.daily_memorization_records(circle_id, record_date desc);
create index if not exists accountability_student_date_idx on public.daily_accountability(student_id, record_date desc);
create index if not exists attendance_student_date_idx on public.attendance_records(student_id, attendance_date desc);
create index if not exists attendance_circle_date_idx on public.attendance_records(circle_id, attendance_date desc);
create index if not exists weekly_eval_circle_week_idx on public.weekly_evaluations(circle_id, week_start desc, total_score desc);
create index if not exists points_student_created_idx on public.points_transactions(student_id, created_at desc);
create index if not exists notifications_recipient_status_idx on public.notifications(recipient_profile_id, status, created_at desc);
create index if not exists device_tokens_profile_active_idx on public.device_tokens(profile_id) where is_active;
create index if not exists audit_logs_org_created_idx on public.audit_logs(organization_id, created_at desc);
create unique index if not exists badges_system_code_idx on public.badges(code) where organization_id is null;

create or replace view public.student_progress_summary
with (security_invoker = true) as
with points as (
  select
    student_id,
    coalesce(sum(points), 0)::integer as total_points
  from public.points_transactions
  group by student_id
),
memorization as (
  select
    student_id,
    round(avg(mastery_percent), 2) as avg_mastery_percent,
    count(*) as memorization_entries
  from public.daily_memorization_records
  group by student_id
)
select
  s.organization_id,
  s.id as student_id,
  s.full_name,
  s.level,
  s.status,
  coalesce(p.total_points, 0) as total_points,
  m.avg_mastery_percent,
  coalesce(m.memorization_entries, 0) as memorization_entries,
  public.calculate_attendance_percentage(s.id, current_date - 30, current_date) as attendance_last_30_days
from public.students s
left join points p on p.student_id = s.id
left join memorization m on m.student_id = s.id;

create or replace view public.circle_dashboard_summary
with (security_invoker = true) as
select
  c.organization_id,
  c.id as circle_id,
  c.name as circle_name,
  count(distinct cs.student_id) filter (where cs.left_at is null) as active_students,
  round(avg(we.percentage), 2) as avg_weekly_percentage,
  round(avg(dmr.mastery_percent), 2) as avg_mastery_percent
from public.circles c
left join public.circle_students cs on cs.circle_id = c.id and cs.left_at is null
left join public.weekly_evaluations we on we.circle_id = c.id and we.week_start >= current_date - interval '8 weeks'
left join public.daily_memorization_records dmr on dmr.circle_id = c.id and dmr.record_date >= current_date - interval '30 days'
group by c.organization_id, c.id, c.name;
