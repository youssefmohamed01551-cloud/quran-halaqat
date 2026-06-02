create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid() and is_active = true;
$$;

create or replace function public.current_organization_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select organization_id from public.profiles where id = auth.uid() and is_active = true;
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'super_admin', false);
$$;

create or replace function public.has_org_role(target_org_id uuid, allowed_roles public.user_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_active = true
      and (
        p.role = 'super_admin'
        or (p.organization_id = target_org_id and p.role = any(allowed_roles))
      )
  );
$$;

create or replace function public.is_teacher_of_circle(target_circle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circles c
    join public.teachers t on t.id = c.teacher_id
    where c.id = target_circle_id
      and t.profile_id = auth.uid()
      and exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.is_active = true
      )
  );
$$;

create or replace function public.can_access_student(target_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.students s
    left join public.circle_students cs on cs.student_id = s.id and cs.left_at is null
    left join public.circles c on c.id = cs.circle_id
    left join public.teachers t on t.id = c.teacher_id
    left join public.student_guardians sg on sg.student_id = s.id
    left join public.guardians g on g.id = sg.guardian_id
    left join public.profiles p on p.id = auth.uid()
    where s.id = target_student_id
      and p.is_active = true
      and (
        p.role = 'super_admin'
        or (p.organization_id = s.organization_id and p.role in ('admin', 'supervisor'))
        or t.profile_id = auth.uid()
        or g.profile_id = auth.uid()
        or s.profile_id = auth.uid()
      )
  );
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.add_points_for_memorization()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  awarded_points integer;
begin
  awarded_points := greatest(1, round(new.score)::integer);

  insert into public.points_transactions (
    organization_id,
    student_id,
    source,
    source_id,
    points,
    reason,
    created_by
  )
  values (
    new.organization_id,
    new.student_id,
    'memorization',
    new.id,
    awarded_points,
    'Daily memorization score',
    new.created_by
  );

  return new;
end;
$$;

create or replace function public.queue_absence_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status in ('absent', 'excused_absent') then
    insert into public.notifications (
      organization_id,
      recipient_profile_id,
      student_id,
      channel,
      title,
      body,
      data
    )
    select
      new.organization_id,
      g.profile_id,
      new.student_id,
      'push',
      'تنبيه حضور',
      case when new.status = 'absent'
        then 'تم تسجيل غياب الطالب اليوم.'
        else 'تم تسجيل غياب بعذر للطالب اليوم.'
      end,
      jsonb_build_object('attendance_id', new.id, 'status', new.status)
    from public.student_guardians sg
    join public.guardians g on g.id = sg.guardian_id
    where sg.student_id = new.student_id
      and sg.can_receive_notifications = true
      and g.profile_id is not null;
  end if;

  return new;
end;
$$;

create or replace function public.calculate_attendance_percentage(
  target_student_id uuid,
  from_date date,
  to_date date
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    round(
      100.0 * count(*) filter (where status in ('present', 'late'))
      / nullif(count(*), 0),
      2
    ),
    0
  )
  from public.attendance_records
  where student_id = target_student_id
    and attendance_date between from_date and to_date;
$$;

create or replace function public.suggest_review_frequency(avg_mastery numeric)
returns public.review_frequency
language sql
immutable
as $$
  select case
    when avg_mastery < 60 then 'daily'::public.review_frequency
    when avg_mastery < 75 then 'weekly'::public.review_frequency
    when avg_mastery < 90 then 'monthly'::public.review_frequency
    else 'cumulative'::public.review_frequency
  end;
$$;

create or replace function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  row_id uuid;
  org_id uuid;
begin
  row_id := coalesce((to_jsonb(new)->>'id')::uuid, (to_jsonb(old)->>'id')::uuid);
  org_id := coalesce((to_jsonb(new)->>'organization_id')::uuid, (to_jsonb(old)->>'organization_id')::uuid);

  insert into public.audit_logs (
    organization_id,
    actor_profile_id,
    action,
    table_name,
    row_id,
    old_values,
    new_values
  )
  values (
    org_id,
    auth.uid(),
    tg_op,
    tg_table_name,
    row_id,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );

  return coalesce(new, old);
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organizations','mosques','profiles','teachers','guardians','circles','students',
    'daily_memorization_records','review_plans','daily_accountability','attendance_records',
    'tests','test_results','weekly_evaluations'
  ]
  loop
    execute format('drop trigger if exists set_updated_at on public.%I', table_name);
    execute format(
      'create trigger set_updated_at before update on public.%I for each row execute function public.touch_updated_at()',
      table_name
    );
  end loop;
end $$;

drop trigger if exists award_points_on_memorization on public.daily_memorization_records;
create trigger award_points_on_memorization
after insert on public.daily_memorization_records
for each row execute function public.add_points_for_memorization();

drop trigger if exists notify_on_absence on public.attendance_records;
create trigger notify_on_absence
after insert or update of status on public.attendance_records
for each row execute function public.queue_absence_notification();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organizations','mosques','profiles','teachers','guardians','circles','students',
    'daily_memorization_records','daily_accountability','attendance_records','tests',
    'test_results','weekly_evaluations','points_transactions','student_badges','certificates'
  ]
  loop
    execute format('drop trigger if exists audit_changes on public.%I', table_name);
    execute format(
      'create trigger audit_changes after insert or update or delete on public.%I for each row execute function public.audit_row_change()',
      table_name
    );
  end loop;
end $$;
