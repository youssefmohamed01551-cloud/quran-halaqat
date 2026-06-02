# System Analysis

## Vision

The platform converts paper-based Quran memorization and accountability notebooks into a secure multi-tenant digital system for Islamic schools, mosques, Quran circles, parents, and students.

## Core Goals

- Let teachers record memorization, review, attendance, behavior, prayers, tests, and weekly evaluations.
- Let students and parents view their own progress only.
- Let supervisors and admins monitor teachers, circles, attendance, results, and performance trends.
- Support real-time updates, push notifications, PDF reports, exports, gamification, and AI recommendations.
- Scale to 100,000+ students, 10,000+ teachers, and millions of operational records.

## User Roles

| Role | Scope | Main Actions |
| --- | --- | --- |
| Super Admin | Whole platform | Manage organizations, global audit, emergency access |
| Admin | One organization | Manage users, mosques, circles, teachers, students, policies |
| Supervisor | One organization or assigned circles | Review performance, approve results, audit teachers |
| Teacher | Assigned circles | Record memorization, attendance, accountability, tests, weekly scores |
| Parent | Linked children | View progress, reports, notifications |
| Student | Own profile | View memorization, review tasks, grades, badges, certificates |

## Main Domains

- Identity and RBAC: Supabase Auth plus `profiles` and role tables.
- Organization management: organizations, mosques, circles, supervisors, teachers.
- Student management: student profile, guardian links, enrollments.
- Learning records: memorization, review plans, review tasks, tests, test results.
- Accountability: prayers, adhkar, behavior, reading, good deeds.
- Attendance: daily status and recurring absence alerts.
- Evaluation: weekly scoring, rankings, percentages.
- Gamification: points, badges, certificates.
- Reporting: dashboards, PDF, CSV, Excel export.
- AI module: performance analysis, weak-point detection, review-plan suggestions.
- Audit and compliance: audit logs and RLS.

## Key Workflows

1. Admin creates organization users through Supabase Auth and assigns roles.
2. Admin creates mosques, circles, and teacher assignments.
3. Admin enrolls students and links guardians.
4. Teacher opens assigned circle and records daily memorization and accountability.
5. Attendance updates trigger absence notifications when needed.
6. Weekly evaluations calculate total, average, percentage, and rankings.
7. Student and parent clients read progress in real time.
8. AI Edge Function analyzes records and stores recommendations in `ai_insights`.
9. Reports are generated from database views and exported to PDF/CSV/Excel.

## Non-Functional Requirements

- Security: deny by default, RLS on every business table, service-role usage only in trusted Edge Functions.
- Performance: indexed high-cardinality columns, date-based access patterns, summary views, pagination.
- Availability: Supabase managed backups, monitoring, rate limits, alerting.
- Maintainability: modular Flutter features, repositories, Riverpod providers, documented SQL migrations.
- Localization: Arabic-first, English-supported UI, RTL layout support.
