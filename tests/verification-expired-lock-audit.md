# Expired lock audit migration verification

PostgreSQL 17.11 and Liquibase 4.33.0 in isolated Docker projects; no host
database port published.

- Empty store: 11 changesets applied. `hu-iam-expired-lock-audit.sql` passed as
  `iam_runtime`: an expiry unlock with no human actor was recorded, while an
  unattributed unlock without `EXPIRY` was rejected.
- The existing `hu-iam-005.sql` lock and administrator-unlock test still passed
  without changing its inserts or prior migration.
- Previous version: 10 changesets applied, and a synthetic administrator
  unlock row inserted before the upgrade. The new migration applied 1 change
  while preserving that row and its actor. Liquibase validate passed and a
  repeated update applied zero changes.

This additive constraint distinguishes automatic expiry from an authorized
administrator action; it does not itself schedule or execute an unlock. The
owning API must do so and emit the approved `UserUnlocked` event atomically.
