alter table public.organizations enable row level security;
alter table public.mosques enable row level security;
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.guardians enable row level security;
alter table public.circles enable row level security;
alter table public.students enable row level security;
alter table public.student_guardians enable row level security;
alter table public.circle_students enable row level security;
alter table public.daily_memorization_records enable row level security;
alter table public.review_plans enable row level security;
alter table public.review_tasks enable row level security;
alter table public.daily_accountability enable row level security;
alter table public.attendance_records enable row level security;
alter table public.tests enable row level security;
alter table public.test_results enable row level security;
alter table public.weekly_evaluations enable row level security;
alter table public.badges enable row level security;
alter table public.points_transactions enable row level security;
alter table public.student_badges enable row level security;
alter table public.certificates enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.ai_insights enable row level security;
alter table public.audit_logs enable row level security;
alter table public.quran_surahs enable row level security;

drop policy if exists "organizations_select_scope" on public.organizations;
create policy "organizations_select_scope"
on public.organizations for select
to authenticated
using (public.is_super_admin() or id = public.current_organization_id());

drop policy if exists "organizations_admin_write" on public.organizations;
create policy "organizations_admin_write"
on public.organizations for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists "profiles_select_scope" on public.profiles;
create policy "profiles_select_scope"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.is_super_admin()
  or (organization_id = public.current_organization_id() and public.current_user_role() in ('admin','supervisor'))
);

drop policy if exists "profiles_admin_write" on public.profiles;
create policy "profiles_admin_write"
on public.profiles for all
to authenticated
using (
  public.is_super_admin()
  or public.has_org_role(organization_id, array['admin']::public.user_role[])
)
with check (
  public.is_super_admin()
  or public.has_org_role(organization_id, array['admin']::public.user_role[])
);

drop policy if exists "org_reference_select" on public.mosques;
create policy "org_reference_select"
on public.mosques for select
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher','parent','student']::public.user_role[]));

drop policy if exists "org_reference_admin_write" on public.mosques;
create policy "org_reference_admin_write"
on public.mosques for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]));

drop policy if exists "teachers_select_scope" on public.teachers;
create policy "teachers_select_scope"
on public.teachers for select
to authenticated
using (
  profile_id = auth.uid()
  or public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
);

drop policy if exists "teachers_admin_write" on public.teachers;
create policy "teachers_admin_write"
on public.teachers for all
to authenticated
using (public.has_org_role(organization_id, array['admin']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin']::public.user_role[]));

drop policy if exists "guardians_select_scope" on public.guardians;
create policy "guardians_select_scope"
on public.guardians for select
to authenticated
using (
  profile_id = auth.uid()
  or public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or exists (
    select 1
    from public.student_guardians sg
    join public.students s on s.id = sg.student_id
    where sg.guardian_id = guardians.id and public.can_access_student(s.id)
  )
);

drop policy if exists "guardians_admin_write" on public.guardians;
create policy "guardians_admin_write"
on public.guardians for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]));

drop policy if exists "circles_select_scope" on public.circles;
create policy "circles_select_scope"
on public.circles for select
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(id)
  or exists (
    select 1
    from public.circle_students cs
    join public.students s on s.id = cs.student_id
    where cs.circle_id = circles.id
      and cs.left_at is null
      and public.can_access_student(s.id)
  )
);

drop policy if exists "circles_admin_write" on public.circles;
create policy "circles_admin_write"
on public.circles for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]));

drop policy if exists "students_select_scope" on public.students;
create policy "students_select_scope"
on public.students for select
to authenticated
using (public.can_access_student(id));

drop policy if exists "students_admin_write" on public.students;
create policy "students_admin_write"
on public.students for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[]));

drop policy if exists "student_guardians_select_scope" on public.student_guardians;
create policy "student_guardians_select_scope"
on public.student_guardians for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "student_guardians_admin_write" on public.student_guardians;
create policy "student_guardians_admin_write"
on public.student_guardians for all
to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = student_guardians.student_id
      and public.has_org_role(s.organization_id, array['admin','supervisor']::public.user_role[])
  )
)
with check (
  exists (
    select 1 from public.students s
    where s.id = student_guardians.student_id
      and public.has_org_role(s.organization_id, array['admin','supervisor']::public.user_role[])
  )
);

drop policy if exists "circle_students_select_scope" on public.circle_students;
create policy "circle_students_select_scope"
on public.circle_students for select
to authenticated
using (
  exists (
    select 1
    from public.circles c
    where c.id = circle_students.circle_id
      and (
        public.has_org_role(c.organization_id, array['admin','supervisor']::public.user_role[])
        or public.is_teacher_of_circle(c.id)
      )
  )
  or public.can_access_student(student_id)
);

drop policy if exists "circle_students_admin_write" on public.circle_students;
create policy "circle_students_admin_write"
on public.circle_students for all
to authenticated
using (
  exists (
    select 1 from public.circles c
    where c.id = circle_students.circle_id
      and public.has_org_role(c.organization_id, array['admin','supervisor']::public.user_role[])
  )
)
with check (
  exists (
    select 1 from public.circles c
    where c.id = circle_students.circle_id
      and public.has_org_role(c.organization_id, array['admin','supervisor']::public.user_role[])
  )
);

drop policy if exists "student_records_select_scope" on public.daily_memorization_records;
create policy "student_records_select_scope"
on public.daily_memorization_records for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "student_records_teacher_insert" on public.daily_memorization_records;
create policy "student_records_teacher_insert"
on public.daily_memorization_records for insert
to authenticated
with check (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
);

drop policy if exists "student_records_teacher_update" on public.daily_memorization_records;
create policy "student_records_teacher_update"
on public.daily_memorization_records for update
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
)
with check (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
);

drop policy if exists "accountability_select_scope" on public.daily_accountability;
create policy "accountability_select_scope"
on public.daily_accountability for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "accountability_teacher_write" on public.daily_accountability;
create policy "accountability_teacher_write"
on public.daily_accountability for all
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
)
with check (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
);

drop policy if exists "attendance_select_scope" on public.attendance_records;
create policy "attendance_select_scope"
on public.attendance_records for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "attendance_teacher_write" on public.attendance_records;
create policy "attendance_teacher_write"
on public.attendance_records for all
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
)
with check (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
);

drop policy if exists "tests_select_scope" on public.tests;
create policy "tests_select_scope"
on public.tests for select
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[])
  or exists (
    select 1 from public.test_results tr
    where tr.test_id = tests.id and public.can_access_student(tr.student_id)
  )
);

drop policy if exists "tests_staff_write" on public.tests;
create policy "tests_staff_write"
on public.tests for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "test_results_select_scope" on public.test_results;
create policy "test_results_select_scope"
on public.test_results for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "test_results_staff_write" on public.test_results;
create policy "test_results_staff_write"
on public.test_results for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "weekly_eval_select_scope" on public.weekly_evaluations;
create policy "weekly_eval_select_scope"
on public.weekly_evaluations for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "weekly_eval_staff_write" on public.weekly_evaluations;
create policy "weekly_eval_staff_write"
on public.weekly_evaluations for all
to authenticated
using (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
)
with check (
  public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
  or public.is_teacher_of_circle(circle_id)
);

drop policy if exists "review_plans_select_scope" on public.review_plans;
create policy "review_plans_select_scope"
on public.review_plans for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "review_plans_staff_write" on public.review_plans;
create policy "review_plans_staff_write"
on public.review_plans for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "review_tasks_select_scope" on public.review_tasks;
create policy "review_tasks_select_scope"
on public.review_tasks for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "review_tasks_staff_write" on public.review_tasks;
create policy "review_tasks_staff_write"
on public.review_tasks for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "badges_select_scope" on public.badges;
create policy "badges_select_scope"
on public.badges for select
to authenticated
using (
  is_system = true
  or public.has_org_role(organization_id, array['admin','supervisor','teacher','parent','student']::public.user_role[])
);

drop policy if exists "badges_admin_write" on public.badges;
create policy "badges_admin_write"
on public.badges for all
to authenticated
using (
  organization_id is not null
  and public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
)
with check (
  organization_id is not null
  and public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
);

drop policy if exists "points_select_scope" on public.points_transactions;
create policy "points_select_scope"
on public.points_transactions for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "points_staff_insert" on public.points_transactions;
create policy "points_staff_insert"
on public.points_transactions for insert
to authenticated
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "student_badges_select_scope" on public.student_badges;
create policy "student_badges_select_scope"
on public.student_badges for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "student_badges_staff_write" on public.student_badges;
create policy "student_badges_staff_write"
on public.student_badges for all
to authenticated
using (
  exists (
    select 1 from public.students s
    where s.id = student_badges.student_id
      and public.has_org_role(s.organization_id, array['admin','supervisor','teacher']::public.user_role[])
  )
)
with check (
  exists (
    select 1 from public.students s
    where s.id = student_badges.student_id
      and public.has_org_role(s.organization_id, array['admin','supervisor','teacher']::public.user_role[])
  )
);

drop policy if exists "certificates_select_scope" on public.certificates;
create policy "certificates_select_scope"
on public.certificates for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "certificates_staff_write" on public.certificates;
create policy "certificates_staff_write"
on public.certificates for all
to authenticated
using (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]))
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "notifications_recipient_select" on public.notifications;
create policy "notifications_recipient_select"
on public.notifications for select
to authenticated
using (
  recipient_profile_id = auth.uid()
  or public.has_org_role(organization_id, array['admin','supervisor']::public.user_role[])
);

drop policy if exists "notifications_recipient_update_read" on public.notifications;
create policy "notifications_recipient_update_read"
on public.notifications for update
to authenticated
using (recipient_profile_id = auth.uid())
with check (recipient_profile_id = auth.uid());

drop policy if exists "notifications_staff_insert" on public.notifications;
create policy "notifications_staff_insert"
on public.notifications for insert
to authenticated
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "device_tokens_owner_manage" on public.device_tokens;
create policy "device_tokens_owner_manage"
on public.device_tokens for all
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid() and organization_id = public.current_organization_id());

drop policy if exists "device_tokens_admin_read" on public.device_tokens;
create policy "device_tokens_admin_read"
on public.device_tokens for select
to authenticated
using (public.has_org_role(organization_id, array['admin']::public.user_role[]));

drop policy if exists "ai_insights_select_scope" on public.ai_insights;
create policy "ai_insights_select_scope"
on public.ai_insights for select
to authenticated
using (public.can_access_student(student_id));

drop policy if exists "ai_insights_staff_insert" on public.ai_insights;
create policy "ai_insights_staff_insert"
on public.ai_insights for insert
to authenticated
with check (public.has_org_role(organization_id, array['admin','supervisor','teacher']::public.user_role[]));

drop policy if exists "audit_logs_admin_select" on public.audit_logs;
create policy "audit_logs_admin_select"
on public.audit_logs for select
to authenticated
using (
  public.is_super_admin()
  or public.has_org_role(organization_id, array['admin']::public.user_role[])
);

drop policy if exists "quran_surahs_read_all_authenticated" on public.quran_surahs;
create policy "quran_surahs_read_all_authenticated"
on public.quran_surahs for select
to authenticated
using (true);
