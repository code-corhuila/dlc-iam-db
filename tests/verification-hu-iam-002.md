# HU-IAM-002 database verification — 2026-10-21

Scope: `iam.user_roles` remains the only current-role store. The additive
`iam.role_assignment_audit` table retains assignment and revocation history;
the Auth API must write the role change, audit row and approved outbox event in
one transaction after checking administrator authorization.

Executed locally with PostgreSQL 17.11 and Liquibase 4.33.0 in disposable
containers. The shared PostgreSQL instance was not modified.

| Check | Result |
| --- | --- |
| Previous-version upgrade | Applied the three changesets from merged PR #8, inserted `prior@example.test`, then applied the new changeSet. The prior user and four changelog entries remained. |
| Empty store | Direct `update` applied all four changeSets to a fresh container. |
| Roles and history | `tests/hu-iam-002.sql` passed: duplicate user/role and `PATIENT` audit role rejected; history remained after role revocation. |
| Owner scope | `iam_runtime` has `SELECT`/`INSERT` on the IAM audit table, without `UPDATE`/`DELETE`; the table and its migration are confined to `iam`. |
| Validate and repeat | Liquibase `validate` passed; another `update` applied zero changeSets. |
| Recovery | `pg_dump -Fc -n iam` restored into another disposable database; audit rows and changelog entries counted `1|4`. |

The API's authorization, transaction, event publishing and real-environment
credentials require separate integration evidence. This DB PR does not complete
HU-IAM-002.
