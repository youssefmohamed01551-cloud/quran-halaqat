# Handoff Checklist

## Implemented in This Package

- Supabase schema for organizations, users, circles, students, memorization, review, accountability, attendance, tests, evaluations, rewards, notifications, AI insights, audit logs, and Quran surahs.
- RLS policies for role-based and student-scoped access.
- Database functions, triggers, indexes, summary views, and storage buckets.
- Edge Function skeletons for notifications and AI insights.
- Flutter Material 3 app scaffold with Supabase Auth, Riverpod, Arabic/English localization, responsive navigation, students, memorization, attendance, and reports.
- PDF report generation with Arabic font support.
- Architecture, ERD, API, security, UI/UX, deployment, and testing documentation.

## Required Before Real Launch

- Run migrations in a real Supabase project and review generated SQL output.
- Create real Auth users and seed `profiles`, `teachers`, `guardians`, `students`, and `circles`.
- Add admin screens for full CRUD of organizations, users, mosques, circles, and enrollments.
- Add complete RLS automated tests with one account per role.
- Configure FCM/APNs credentials and device-token registration from Flutter.
- Configure the chosen AI provider behind `MODEL_GATEWAY_URL`.
- Add CSV and Excel export jobs for large reports.
- Add Sentry or equivalent monitoring for Flutter and Edge Functions.
- Run load tests before onboarding more than one institution.

## Recommended Milestones

1. Backend hardening: run migrations, add pgTAP/RLS tests, validate policies.
2. Staff workflows: finish admin/supervisor CRUD screens.
3. Parent/student polish: child switcher, read-only timelines, badges, certificates.
4. Reporting: materialized dashboard aggregates, Excel exports, scheduled monthly reports.
5. Production launch: backups, monitoring, MFA, rate limits, staged rollout.
