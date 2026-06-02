# UI/UX Design

## Design Direction

The product is an operational education platform, so the interface should be calm, dense, readable, and fast. It should prioritize daily workflows over marketing-style screens.

## Navigation

- Teacher: dashboard, students, memorization, attendance, reports.
- Student: dashboard, reports, badges, certificates.
- Parent: children switcher, progress, attendance, reports, notifications.
- Supervisor: teachers, circles, approvals, reports.
- Admin: organization setup, users, circles, dashboards, exports.

## Arabic-First UX

- Arabic is the default locale.
- RTL layout is enabled through Flutter localization.
- English is supported for bilingual institutions.
- Labels should be short and direct.

## Core Screens

### Teacher Dashboard

- Quick search for student.
- Today's attendance completion.
- Today's memorization entries.
- Students needing review.
- Absence alerts.

### Student Profile

- Personal info.
- Current circle.
- Recent memorization.
- Review tasks.
- Attendance percentage.
- Weekly scores.
- Badges and certificates.

### Daily Memorization

- Student selector.
- Activity type: new memorization, review, test.
- Surah dropdown.
- From/to ayah.
- Mistake categories.
- Score out of 10.
- Teacher notes.

### Daily Accountability

- Prayer chips.
- Adhkar chips.
- Behavior chips.
- Reading pages and minutes.
- Good deed chips.

### Reports

- Progress chart.
- Attendance chart.
- Points summary.
- PDF export.
- CSV/Excel export for admins.

## Accessibility

- Support large text without clipped controls.
- Use icons with tooltips.
- Keep touch targets at least 44x44 logical pixels.
- Ensure contrast meets WCAG AA.
- Avoid hidden gestures for core workflows.

## Design System

- Material Design 3.
- Rounded corners up to 8px for cards and inputs.
- Teal as a primary action color with neutral surfaces.
- Status colors:
  - Present/success: green.
  - Late/warning: amber.
  - Absent/error: red.
  - Review/info: indigo.
