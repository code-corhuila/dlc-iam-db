# HU-IAM-003 staff lifecycle verification — 2026-10-21

Executed locally with PostgreSQL 17.11 and Liquibase 4.33.0 in isolated
`tests/compose.yml` projects. No shared or production database was used.

| Check | Result |
| --- | --- |
| Fresh store | Four changesets applied, including `004-iam-staff-lifecycle`. `tests/hu-iam-003.sql` passed as `iam_runtime`: normalized and unique email, verified active status, append-only audit privileges, account disable/enable, and persistent revocation of session, refresh family and credential rows. A disabled account could not create a session. |
| Owner isolation | `tests/verify.sql` passed: IAM runtime had no neighboring schema access, user DELETE, IAM schema CREATE or Liquibase history SELECT. |
| Previous-version upgrade | A separate checkout of published `origin/develop` at `b94c57a` applied its three changesets. `tests/hu-iam-003-prior.sql` inserted an active verified staff user and session. This branch applied only `004-iam-staff-lifecycle`; `tests/hu-iam-003-upgrade.sql`, lifecycle and owner checks passed. |
| Liquibase repeatability | `validate` found no errors in both projects, including after switching the alter changelog to `includeAll`; repeat `update` applied zero changesets. |
| Recovery | `pg_dump -Fc -n iam` from the upgraded project restored into another disposable database. The prior user, session, four history rows and `users_active_verified` constraint were present (`1|1|4|1`). |

The Auth API must authorize staff actions, restrict ordinary creation to the
approved two roles, write audit rows and `SessionRevoked` outbox records in the
same transaction, and enforce revocation on requests. Those API behaviors and
real environment credentials were not tested here. Legacy active accounts
without verification or inconsistent revocation timestamps cause the new
constraints to fail rather than being silently rewritten.

## Integration after PRs #9 and #10 merged — 2026-10-22

Resolved the README and test Compose conflicts against `develop` at `e5e7ee8`.
An isolated fresh installation applied all six changesets; the HU-IAM-003 and
HU-IAM-004 SQL checks and owner isolation check passed. A separate database
started from that five-changeset `develop` revision, received the synthetic
prior user and session, then applied only `004-iam-staff-lifecycle`. The
previous records, lifecycle checks and owner isolation passed. Liquibase
`validate` found no errors, and a repeat `update` applied zero changesets.
