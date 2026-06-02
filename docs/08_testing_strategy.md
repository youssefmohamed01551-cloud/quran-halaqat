# Testing Strategy

## Test Pyramid

- Unit tests: role parsing, validators, score calculations, repository mappers.
- Widget tests: login, navigation, forms, responsive behavior.
- Integration tests: Supabase auth, RLS policies, record creation, report generation.
- End-to-end tests: teacher daily workflow, parent read-only workflow, admin onboarding.

## RLS Tests

Create seeded users for each role:

- super admin
- admin for organization A
- supervisor for organization A
- teacher for circle A
- parent linked to student A
- student A
- unrelated teacher for organization B

Assertions:

- Teacher A cannot read circle B students.
- Student A cannot read student B records.
- Parent A can read linked child records only.
- Admin A cannot read organization B.
- Super admin can read all organizations.
- Only staff can insert attendance and memorization records.

## SQL Tests

Recommended with pgTAP or a migration test harness:

- Generated columns calculate totals correctly.
- Partial unique indexes prevent duplicate active enrollment.
- Absence trigger queues notifications.
- Memorization trigger awards points.
- `can_access_student()` returns correct values by role.

## Flutter Tests

Current included starter test:

```bash
cd flutter_app
flutter test
```

Add next:

- `SignInPage` validation.
- `HomeShell` destinations by role.
- `MemorizationPage` form validation.
- `AttendancePage` chip persistence.
- `ReportRepository` PDF generation smoke test.

## Load Tests

Target scenarios:

- 10,000 teachers logging attendance within a 30-minute window.
- 100,000 students with 180 daily records each.
- 1,000 concurrent parent users reading progress.
- Large report export for 20,000 students.

Recommended tools:

- k6 for REST and Edge Function load tests.
- Supabase query performance dashboard.
- Postgres `EXPLAIN ANALYZE` for slow queries.

## Acceptance Criteria

- P95 teacher save latency below 800 ms in the target region.
- P95 dashboard read latency below 1,200 ms with summary views.
- Zero cross-tenant data exposure in RLS tests.
- All critical workflows recover gracefully from network errors.
