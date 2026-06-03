# Grupli v12.8 — Compact UI + SQL review

## UI changes

- The group home is now cleaner and more compact.
- Removed the quick buttons from the group home: Invite, Code, Members, Settings.
- Those admin/utility actions stay in the `Más` tab so the home focuses on actual group activity.
- The group hero card is shorter and only shows the group name plus private status.
- The first useful content in a group is now the next event/meeting with direct attendance.
- Upcoming events no longer duplicate the main next event; later events appear below it.
- Added a compact status strip for Agenda, Expenses, Doubts and Tournaments.
- Tightened card spacing, stats, shadows and visual density.

## SQL review

- No database migration is required for v12.8.
- `all_in_one.sql` was reviewed and still contains the clean v12 schema:
  - private groups only,
  - owner/admin/member roles,
  - events + attendance,
  - expenses + participants,
  - tournaments + teams + matches,
  - RLS enabled on all app tables,
  - `create_group_atomic`, `join_group_with_code`, `get_my_groups`.
- `security_checks.sql` now includes more complete RLS diagnostics and policy listing.
