# Quran Halaqat Platform

Production-oriented starter package for a Quran halaqat and Islamic school management system. It includes a Supabase backend schema with RLS, Edge Functions, a Flutter clean-architecture scaffold, reporting, AI-insight entry points, and deployment documentation.

## Contents

- `supabase/migrations`: PostgreSQL schema, functions, indexes, RLS policies, seed reference data.
- `supabase/functions`: Edge Functions for push notifications and AI performance insights.
- `flutter_app`: Flutter Material 3 app scaffold using Riverpod and Supabase.
- `docs`: System analysis, architecture, ERD, API design, security, UI/UX, deployment, and testing docs.

## Quick Start

1. Install Supabase CLI and Flutter SDK.
2. From the project root, start Supabase:

```bash
cd supabase
supabase start
supabase db reset
```

3. Copy the local Supabase URL and anon key into Flutter dart defines:

```bash
cd ../flutter_app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

4. Create users in Supabase Auth, then insert matching rows in `profiles` and role-specific tables.

## Production Notes

- Keep `enable_signup = false`; users are created by admins.
- Never expose `SUPABASE_SERVICE_ROLE_KEY` to Flutter.
- Deploy Edge Functions with environment variables for notification and AI providers.
- Configure database backups, point-in-time recovery, and query monitoring before onboarding real students.

## Primary Deliverables

- Analysis: `docs/01_system_analysis.md`
- Architecture: `docs/02_architecture.md`
- Database and ERD: `docs/03_database_and_erd.md`
- API: `docs/04_api_design.md`
- Security: `docs/05_security_design.md`
- UI/UX: `docs/06_ui_ux_design.md`
- Deployment: `docs/07_deployment_guide.md`
- Testing: `docs/08_testing_strategy.md`
- Handoff: `docs/09_handoff_checklist.md`
