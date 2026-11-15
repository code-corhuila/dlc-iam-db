# HU-IAM-004 challenge migration verification — 2026-10-21

Executed locally against PostgreSQL 17.11 with Liquibase 4.33.0 using isolated
`tests/compose.yml` projects. The existing `dlc-iam-db-migration-test`
container and any shared or production database were not used.

| Check | Result |
| --- | --- |
| Fresh store | `docker compose -p dlc-iam-db-hu004-fresh -f tests/compose.yml run --rm migrate update` applied four changesets, including `005-iam-challenge-safety`. |
| Fresh challenge behavior | `tests/hu-iam-004.sql` passed: wrong-purpose consume affected no row, `MFA` purpose was rejected, valid challenge consumed once, replay affected no row, consumed challenge could not be reset, expired challenge could not be consumed, and challenge purpose could not be changed. |
| Liquibase repeatability | `validate` reported no errors; a second `update` applied zero changesets. |
| Previous-version upgrade | A separate checkout of published `origin/develop` at `b94c57a` applied its three changesets. `tests/hu-iam-004-prior.sql` inserted one staff user and one password-recovery challenge. The current branch then applied only `005-iam-challenge-safety` to that same database. `tests/hu-iam-004-upgrade.sql` confirmed both previous rows remained; the challenge and owner checks passed again. `validate` succeeded and repeat `update` applied zero changesets. |
| Existing owner checks | `tests/verify.sql` passed with four changesets: runtime has IAM DML without IAM schema CREATE, user DELETE, Liquibase-history SELECT, or Patients schema access; `PATIENT` role remains rejected. The challenge test also confirms no runtime challenge DELETE or direct trigger-function EXECUTE grant. |
| Recovery | `pg_dump -Fc -n iam` from the actual previous-version upgrade test restored with `pg_restore` into another disposable database. The restored user, recovery challenge, four Liquibase history rows and `challenge_allowed_purpose` constraint were present (`1|1|4|1`). |

These checks verify the migration and database constraints, not cryptographic
token hashing in the Auth API or real provider integration. Unsupported legacy
challenge purposes cause the migration to stop; no rows are deleted automatically.
Real IAM API tests and reviewed Definition of Done evidence remain separate.
