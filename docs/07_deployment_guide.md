# Deployment Guide

## Environments

Use three Supabase projects:

- `dev`: local development and experiments.
- `staging`: QA, training, migration validation.
- `production`: real institution data.

## Supabase Deployment

1. Create a Supabase project.
2. Link the local project:

```bash
cd supabase
supabase link --project-ref <project-ref>
```

3. Push migrations:

```bash
supabase db push
```

4. Deploy Edge Functions:

```bash
supabase functions deploy notify-event
supabase functions deploy ai-insights
```

5. Set secrets:

```bash
supabase secrets set FCM_SERVER_KEY=<value>
supabase secrets set MODEL_GATEWAY_URL=<value>
supabase secrets set MODEL_GATEWAY_KEY=<value>
```

## Flutter Deployment

### Mobile

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=<production-url> \
  --dart-define=SUPABASE_ANON_KEY=<production-anon-key>

flutter build ipa --release \
  --dart-define=SUPABASE_URL=<production-url> \
  --dart-define=SUPABASE_ANON_KEY=<production-anon-key>
```

### Web Admin

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=<production-url> \
  --dart-define=SUPABASE_ANON_KEY=<production-anon-key>
```

Host the web build on Vercel, Netlify, Firebase Hosting, or Supabase Storage behind a CDN.

## Storage Buckets

Recommended buckets:

- `avatars`: private, signed read URLs.
- `certificates`: private, generated PDF certificates.
- `reports`: private, export archive.
- `organization-assets`: private or public depending on logo usage.

Storage object paths must follow these conventions:

- Avatars: `<profile_id>/<file_name>`
- Certificates: `<organization_id>/<student_id>/<certificate_id>.pdf`
- Reports: `<organization_id>/<report_type>/<date>/<file_name>`
- Organization assets: `<organization_id>/<asset_name>`

## Monitoring

- Supabase logs and query performance.
- Postgres index hit ratio and slow queries.
- Edge Function errors and latency.
- Flutter crash/error reporting.
- Notification delivery failure rate.

## Release Checklist

- RLS tests passed for all roles.
- Backups and PITR enabled.
- Staff MFA enabled.
- Production secrets configured.
- Sample export generated.
- Notification test delivered.
- AI function tested with safe fallback.
- Legal/privacy review completed for student data.
