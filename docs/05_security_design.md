# Security Design

## Principles

- Deny by default.
- Scope every business row by `organization_id`.
- Use RLS for data isolation, not client-side filtering.
- Allow students and parents to read only linked student data.
- Allow teachers to write only assigned circle records.
- Keep privileged keys inside Supabase Edge Functions only.

## Authentication

- Supabase Auth issues JWTs.
- Admin creates users; public signup remains disabled.
- Password reset and account recovery should be routed through institution-approved channels.
- MFA is recommended for admins, supervisors, and teachers.

## Authorization

Authorization is enforced with:

- `profiles.role`
- `profiles.organization_id`
- teacher-circle assignment through `teachers` and `circles`
- parent-child assignment through `student_guardians`
- student login assignment through `students.profile_id`

## RLS Helpers

The migration defines:

- `current_user_role()`
- `current_organization_id()`
- `is_super_admin()`
- `has_org_role(target_org_id, allowed_roles)`
- `is_teacher_of_circle(target_circle_id)`
- `can_access_student(target_student_id)`

These helpers make policies readable and reusable.

## Audit Logs

The `audit_row_change()` trigger stores insert, update, and delete snapshots for core tables. Admins can review audit logs for their organization; super admins can review all logs.

## Rate Limiting

Recommended layers:

- Supabase Auth rate limits.
- API gateway limits for Edge Functions.
- Per-user limits in Edge Functions for AI generation and export jobs.
- Device token write limits to prevent notification abuse.

## Encryption

- Supabase handles encryption at rest and TLS in transit.
- Sensitive secrets stay in Supabase function secrets.
- Avoid storing unnecessary national ID values; if required, restrict access and consider field-level encryption.

## Production Security Checklist

- Disable public signup.
- Configure MFA for staff.
- Review every RLS policy with test users.
- Rotate service-role keys after staging setup.
- Restrict Storage buckets with signed URLs.
- Enable database backups and PITR.
- Add Sentry or equivalent crash/error monitoring.
- Add alerts for failed login spikes and unusual export volume.
