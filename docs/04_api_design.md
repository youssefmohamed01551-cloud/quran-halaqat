# API Design

## API Style

The platform uses Supabase PostgREST for CRUD, Realtime for subscriptions, Storage for files, and Edge Functions for privileged workflows.

## Auth

All client requests use Supabase Auth JWT. The Flutter app never sends or stores service-role credentials.

```dart
await supabase.auth.signInWithPassword(email: email, password: password);
```

## Core REST Resources

| Resource | Methods | Roles |
| --- | --- | --- |
| `profiles` | select, admin write | self, admin, supervisor |
| `students` | select, admin/supervisor write | admin, supervisor, teacher, parent, student by RLS |
| `circles` | select, admin/supervisor write | admin, supervisor, teacher by assignment |
| `daily_memorization_records` | select, insert, update | teacher/admin/supervisor write; student/parent read own |
| `daily_accountability` | select, upsert | teacher/admin/supervisor write; student/parent read own |
| `attendance_records` | select, upsert | teacher/admin/supervisor write; student/parent read own |
| `weekly_evaluations` | select, upsert | teacher/admin/supervisor write; student/parent read own |
| `notifications` | select/update own, staff insert | recipient or staff |
| `ai_insights` | select own, staff insert | via Edge Function |

## Example Operations

### Record Memorization

```http
POST /rest/v1/daily_memorization_records
Authorization: Bearer <jwt>
apikey: <anon-key>
Content-Type: application/json

{
  "organization_id": "...",
  "circle_id": "...",
  "student_id": "...",
  "teacher_id": "...",
  "record_date": "2026-06-03",
  "activity_type": "new_memorization",
  "surah_number": 2,
  "from_ayah": 1,
  "to_ayah": 5,
  "score": 9.5
}
```

### Subscribe to Student Updates

```dart
supabase
  .channel('student-progress')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'daily_memorization_records',
    callback: (payload) {},
  )
  .subscribe();
```

### Send Notification

```http
POST /functions/v1/notify-event
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "notificationId": "..."
}
```

### Generate AI Insight

```http
POST /functions/v1/ai-insights
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "studentId": "...",
  "fromDate": "2026-05-01",
  "toDate": "2026-06-03"
}
```

## Exports

- PDF reports are generated in Flutter for single-student reports.
- CSV/Excel exports should be built from summary views for small exports.
- Large exports should be executed through an Edge Function that writes files to Storage and returns a signed URL.

## Pagination

Use range-based pagination for high-volume tables:

```dart
await supabase
  .from('daily_memorization_records')
  .select()
  .eq('student_id', studentId)
  .order('record_date', ascending: false)
  .range(0, 49);
```
