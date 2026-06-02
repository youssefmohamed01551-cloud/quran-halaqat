create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";
create extension if not exists "pg_stat_statements";

do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum (
      'super_admin',
      'admin',
      'supervisor',
      'teacher',
      'parent',
      'student'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'gender') then
    create type public.gender as enum ('male', 'female');
  end if;

  if not exists (select 1 from pg_type where typname = 'circle_level') then
    create type public.circle_level as enum ('beginner', 'intermediate', 'advanced', 'ijazah');
  end if;

  if not exists (select 1 from pg_type where typname = 'student_status') then
    create type public.student_status as enum ('active', 'paused', 'graduated', 'transferred', 'archived');
  end if;

  if not exists (select 1 from pg_type where typname = 'activity_type') then
    create type public.activity_type as enum ('new_memorization', 'review', 'test');
  end if;

  if not exists (select 1 from pg_type where typname = 'attendance_status') then
    create type public.attendance_status as enum ('present', 'late', 'absent', 'excused_absent');
  end if;

  if not exists (select 1 from pg_type where typname = 'review_frequency') then
    create type public.review_frequency as enum ('daily', 'weekly', 'monthly', 'cumulative');
  end if;

  if not exists (select 1 from pg_type where typname = 'test_type') then
    create type public.test_type as enum ('memorization', 'tajweed', 'monthly', 'term', 'annual');
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_channel') then
    create type public.notification_channel as enum ('push', 'email', 'sms', 'in_app');
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_status') then
    create type public.notification_status as enum ('queued', 'sent', 'failed', 'read');
  end if;
end $$;
