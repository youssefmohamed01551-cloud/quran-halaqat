create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_url text,
  country_code char(2),
  timezone text not null default 'Asia/Riyadh',
  settings jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mosques (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  city text,
  district text,
  address text,
  gender public.gender,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, name)
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  role public.user_role not null,
  full_name text not null,
  avatar_url text,
  national_id text,
  phone text,
  email text,
  is_active boolean not null default true,
  locale text not null default 'ar',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_super_admin_org_chk check (
    (role = 'super_admin' and organization_id is null)
    or (role <> 'super_admin' and organization_id is not null)
  )
);

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  employee_code text not null,
  specialization text,
  hire_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, employee_code)
);

create table if not exists public.guardians (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name text not null,
  phone text not null,
  alternate_phone text,
  relation text not null default 'parent',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.circles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  mosque_id uuid references public.mosques(id) on delete set null,
  teacher_id uuid references public.teachers(id) on delete set null,
  supervisor_id uuid references public.profiles(id) on delete set null,
  name text not null,
  level public.circle_level not null default 'beginner',
  age_min smallint,
  age_max smallint,
  gender public.gender not null,
  capacity smallint not null default 25,
  is_active boolean not null default true,
  schedule jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, name),
  constraint circles_age_chk check (age_min is null or age_max is null or age_min <= age_max)
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name text not null,
  avatar_url text,
  national_id text,
  birth_date date,
  gender public.gender not null,
  phone text,
  level public.circle_level not null default 'beginner',
  status public.student_status not null default 'active',
  enrolled_at date not null default current_date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_guardians (
  student_id uuid not null references public.students(id) on delete cascade,
  guardian_id uuid not null references public.guardians(id) on delete cascade,
  is_primary boolean not null default false,
  can_receive_notifications boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (student_id, guardian_id)
);

create unique index if not exists one_primary_guardian_per_student
  on public.student_guardians(student_id)
  where is_primary;

create table if not exists public.circle_students (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  joined_at date not null default current_date,
  left_at date,
  is_active boolean generated always as (left_at is null) stored,
  created_at timestamptz not null default now(),
  unique (circle_id, student_id, joined_at)
);

create unique index if not exists one_active_circle_per_student
  on public.circle_students(student_id)
  where left_at is null;

create table if not exists public.daily_memorization_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  record_date date not null,
  activity_type public.activity_type not null,
  surah_number smallint not null check (surah_number between 1 and 114),
  from_ayah smallint not null check (from_ayah > 0),
  to_ayah smallint not null check (to_ayah >= from_ayah),
  page_count numeric(5,2) not null default 0 check (page_count >= 0),
  total_mistakes smallint not null default 0 check (total_mistakes >= 0),
  memorization_mistakes smallint not null default 0 check (memorization_mistakes >= 0),
  tajweed_mistakes smallint not null default 0 check (tajweed_mistakes >= 0),
  waqf_ibtida_mistakes smallint not null default 0 check (waqf_ibtida_mistakes >= 0),
  teacher_notes text,
  score numeric(5,2) not null check (score between 0 and 10),
  mastery_percent numeric(5,2) generated always as (least(100, greatest(0, score * 10))) stored,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.review_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  frequency public.review_frequency not null,
  from_surah smallint not null check (from_surah between 1 and 114),
  from_ayah smallint not null check (from_ayah > 0),
  to_surah smallint not null check (to_surah between 1 and 114),
  to_ayah smallint not null check (to_ayah > 0),
  target_mastery_percent numeric(5,2) not null default 90,
  is_active boolean not null default true,
  ai_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.review_tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  plan_id uuid not null references public.review_plans(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  due_date date not null,
  completed_at timestamptz,
  score numeric(5,2) check (score between 0 and 10),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_accountability (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  record_date date not null,
  fajr boolean not null default false,
  dhuhr boolean not null default false,
  asr boolean not null default false,
  maghrib boolean not null default false,
  isha boolean not null default false,
  morning_adhkar boolean not null default false,
  evening_adhkar boolean not null default false,
  honesty boolean not null default false,
  trustworthiness boolean not null default false,
  kindness_to_parents boolean not null default false,
  discipline boolean not null default false,
  teacher_respect boolean not null default false,
  daily_pages numeric(5,2) not null default 0 check (daily_pages >= 0),
  reading_minutes smallint not null default 0 check (reading_minutes >= 0),
  charity boolean not null default false,
  fasting boolean not null default false,
  helped_others boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, record_date)
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  attendance_date date not null,
  status public.attendance_status not null,
  minutes_late smallint not null default 0 check (minutes_late >= 0),
  excuse_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, attendance_date)
);

create table if not exists public.tests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  circle_id uuid references public.circles(id) on delete set null,
  title text not null,
  test_type public.test_type not null,
  scheduled_at timestamptz,
  max_score numeric(6,2) not null default 100 check (max_score > 0),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.test_results (
  id uuid primary key default gen_random_uuid(),
  test_id uuid not null references public.tests(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid references public.teachers(id) on delete set null,
  score numeric(6,2) not null check (score >= 0),
  notes text,
  strengths text,
  improvement_points text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (test_id, student_id)
);

create table if not exists public.weekly_evaluations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  teacher_id uuid not null references public.teachers(id) on delete restrict,
  week_start date not null,
  memorization_score numeric(5,2) not null check (memorization_score between 0 and 10),
  review_score numeric(5,2) not null check (review_score between 0 and 10),
  prayer_score numeric(5,2) not null check (prayer_score between 0 and 10),
  behavior_score numeric(5,2) not null check (behavior_score between 0 and 10),
  attendance_score numeric(5,2) not null check (attendance_score between 0 and 10),
  total_score numeric(6,2) generated always as (
    memorization_score + review_score + prayer_score + behavior_score + attendance_score
  ) stored,
  average_score numeric(5,2) generated always as (
    (memorization_score + review_score + prayer_score + behavior_score + attendance_score) / 5
  ) stored,
  percentage numeric(5,2) generated always as (
    ((memorization_score + review_score + prayer_score + behavior_score + attendance_score) / 50) * 100
  ) stored,
  circle_rank integer,
  organization_rank integer,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, week_start)
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  code text not null,
  name_ar text not null,
  name_en text not null,
  description_ar text,
  description_en text,
  icon_name text not null default 'workspace_premium',
  points_required integer not null default 0,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  unique (organization_id, code)
);

create table if not exists public.points_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  source text not null,
  source_id uuid,
  points integer not null,
  reason text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.student_badges (
  student_id uuid not null references public.students(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  awarded_by uuid references public.profiles(id) on delete set null,
  awarded_at timestamptz not null default now(),
  primary key (student_id, badge_id)
);

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  title text not null,
  certificate_url text,
  issued_by uuid references public.profiles(id) on delete set null,
  issued_at timestamptz not null default now(),
  metadata jsonb not null default '{}'
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  recipient_profile_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  channel public.notification_channel not null default 'in_app',
  status public.notification_status not null default 'queued',
  title text not null,
  body text not null,
  data jsonb not null default '{}',
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android', 'web')),
  device_name text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (profile_id, token)
);

create table if not exists public.ai_insights (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  insight_type text not null,
  summary text not null,
  recommendations jsonb not null default '[]',
  confidence numeric(4,3) not null check (confidence between 0 and 1),
  generated_by text not null default 'edge-function',
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigserial primary key,
  organization_id uuid references public.organizations(id) on delete set null,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  action text not null,
  table_name text not null,
  row_id uuid,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists public.quran_surahs (
  number smallint primary key check (number between 1 and 114),
  name_ar text not null,
  name_en text not null,
  ayah_count smallint not null check (ayah_count > 0)
);
