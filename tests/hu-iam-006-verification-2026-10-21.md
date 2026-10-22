# HU-IAM-006 session lineage verification — 2026-10-21

Local isolated PostgreSQL 17.11 / Liquibase 4.33.0 tests; no shared database used.

| Check | Result |
| --- | --- |
| Fresh store | Four changesets applied. `tests/hu-iam-006.sql` passed under `iam_runtime`: seven-day limits, blank-device rejection, single family root, consumed predecessor, immutable consumed state, reuse evidence and cascade revocation, inactive-session rejection, and logout cascade. |
| Owner scope | `tests/verify.sql` passed: no neighboring schema access, user DELETE, IAM schema CREATE or Liquibase history SELECT. |
| Published upgrade | `origin/develop` at `b94c57a` applied three changesets and `tests/hu-iam-006-prior.sql` inserted a user, session, family and hashed credential. This branch applied only `007-iam-session-lineage`; upgrade, lineage and owner checks passed. |
| Repeatability | Liquibase `validate` passed; repeat `update` applied zero changesets in both projects. |
| Recovery | `pg_dump -Fc -n iam` restored into a second disposable database; prior user, session, credential and four history rows remained (`1|1|1|4`). |

The Auth API still must hash real tokens, rotate them atomically, detect replay,
authorize own-session operations, secure CSRF/cookies, publish approved events
and enforce access-token revocation. These provider behaviors were not tested.
Legacy data violating the new limits or single-root rule stops migration for
owner review; no rows are silently rewritten.

## Integration with current develop — 2026-10-22

Against `develop` at `47332a7`, a fresh store applied eight changesets and
the HU-IAM-006/005/003/004 SQL and owner checks passed. An isolated upgrade
from its seven changesets preserved a prior user, session, family and hashed
credential; only `007-iam-session-lineage` was added. The lineage and owner
checks passed, `validate` found no errors, and a repeat `update` applied zero.
