# IAM DB migration verification — 2026-10-20

Executed locally against the disposable `tests/compose.yml` PostgreSQL 17.11
container. No shared or production database was changed.

| Check | Result |
| --- | --- |
| Existing mapping inspection | Shared local `di_lucca` had no `iam` schema, IAM tables or IAM roles before this work. Repository SQL placeholders were empty. |
| Upgrade | `update-count 1` applied identity; a synthetic staff row was inserted; `update` applied the remaining two changesets and preserved that row. |
| Constraints and scope | `tests/verify.sql` passed: `PATIENT` role rejected, scoped runtime DML on IAM tables, no user DELETE, no schema CREATE, no Patients schema access and no Liquibase history SELECT. |
| Runtime connection | `iam_runtime` connected to the isolated database and read one IAM user; user DELETE and `CREATE TABLE iam.denied_test` failed with permission denied. |
| Empty store | Direct `update` applied all three changesets on a fresh test container. |
| Validation and repeat | `validate` reported no errors; repeated `update` ran zero changesets. |
| Recovery | `pg_dump -Fc -n iam` restored into a second disposable database; one staff row and three changelog entries were present (`1|3`). |
| Bootstrap repeat | Running `deploy/bootstrap.sql` again preserved the existing IAM schema and succeeded. |

Still pending: real environment role passwords, owner API mapping, runtime login
with its real credentials, event publishing and end-to-end HU acceptance.
