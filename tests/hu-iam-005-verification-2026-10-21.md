# HU-IAM-005 account-lock persistence verification — 2026-10-21

Executed locally with PostgreSQL 17.11 and Liquibase 4.33.0 in isolated
`tests/compose.yml` projects. No shared or production database was used.

| Check | Result |
| --- | --- |
| Fresh store | Four changesets applied, including `006-iam-account-lock`. `tests/hu-iam-005.sql` passed under `iam_runtime`: first and second failure counts, third-failure lock with 15-minute expiry, rejection of a lock without expiry, append-only lock/unlock audit, session creation denied while locked, and session/refresh revocation that survived unlock. |
| Owner isolation | `tests/verify.sql` passed: runtime had no neighboring schema access, user DELETE, IAM schema CREATE or Liquibase history SELECT. Runtime could insert but not update/delete lock audit rows or directly execute the trigger function. |
| Previous-version upgrade | Published `origin/develop` at `b94c57a` applied three changesets. `tests/hu-iam-005-prior.sql` inserted a verified active staff user and session. This branch applied only `006-iam-account-lock`; `tests/hu-iam-005-upgrade.sql`, lock and owner checks passed. |
| Liquibase repeatability | `validate` found no errors; repeat `update` applied zero changesets in both projects. |
| Recovery | `pg_dump -Fc -n iam` from the upgraded project restored into another disposable database. The prior user, session, four history rows and `users_lock_state` constraint were present (`1|1|4|1`). |

The Auth API must atomically count consecutive failures, apply the exact
15-minute policy, enforce the 10-attempts/IP/five-minute limit, authorize
unlock, write audit and approved outbox events, and use generic login errors.
Those behaviors and live session enforcement were not tested here. Inconsistent
legacy lock rows cause migration failure for owner review; no data is silently
rewritten. MFA remains outside this project under ADR-016.
