# dlc-iam-db

IAM-owned PostgreSQL persistence in Di Lucca's shared database.

The physical PostgreSQL database is shared by IAM, Patients, Appointments, and Billing, while each service retains exclusive logical ownership of its own schema. This repository is scoped only to the `iam` schema. IAM must not read from or write to another service's schema during normal runtime; cross-service data exchange must use approved owner APIs or events.

This repository follows the accepted PostgreSQL architecture defined in ADR-007 and ADR-008. ADR-010 preserves the same database ownership boundaries for transversal integration.

The first three Liquibase changesets create staff identity and approved roles,
durable sessions, refresh families and credentials, single-purpose challenges,
an owner outbox, and explicit runtime grants. Existing empty SQL files remain
unreferenced placeholders. The API remains responsible for authentication,
atomic refresh rotation, eligibility checks, event payload minimization and
publishing; a table alone does not prove those behaviors.

HU-IAM-003 keeps the existing unique normalized staff email and account status
as the IAM source of truth. A new append-only `staff_account_audit` table records
the actor, status transition and correlation ID without copying email or password
data. A verified active account is required when a session row is created.
Disabling an account atomically marks its existing sessions, refresh families
and refresh credentials revoked; re-enabling never revives those records. The
Auth API must still authorize ordinary staff creation, restrict it to Dentist
and Secretary Assistant, insert the audit entry and approved `SessionRevoked`
outbox events in the same transaction, and enforce revoked access tokens.
Database triggers do not replace those API and event responsibilities.

## Bootstrap and migration

`dlc-infra-postgres` supplies the shared engine at `dlc-postgres:5432`. A platform
DBA runs `deploy/bootstrap.sql` once against that engine. The script creates the
`iam` schema and separate `iam_migrator` and `iam_runtime` login roles without
passwords. Set both passwords through the environment's secret manager before
network use; never commit or print them. The migrator owns only the `iam` schema;
the runtime role receives DML on IAM business tables, not Liquibase history.
Do not hand the PostgreSQL bootstrap superuser to the API.
For a local development instance, a DBA can use interactive `psql` commands
`\password iam_migrator` and `\password iam_runtime` after bootstrap; these
prompt for values without placing passwords in the repository or shell history.

Put the migrator password in an ignored `secrets/iam-migrator-password.txt`,
then from this repository root run
`docker compose -f deploy/compose.yml --profile tooling run --rm iam-db-migrate`.
`deploy/compose.yml` adds only a disposable Liquibase runner to `platform`; it
does not create another PostgreSQL instance. The password file is mounted as a
Docker secret. `validate` and `status --verbose` may replace the default
`update` command. Coordinate schema changes with the other database owners.

For isolated evidence, run the disposable `tests/compose.yml` project. It has no
host port and uses trust authentication only inside its test network:

1. `docker compose -f tests/compose.yml up -d postgres`
2. `docker compose -f tests/compose.yml run --rm migrate update-count 1`
3. Insert a synthetic staff user in `iam.users` with email `staff@example.test`.
4. `docker compose -f tests/compose.yml run --rm migrate update`
5. `docker compose -f tests/compose.yml exec -T postgres psql -U postgres -d di_lucca -v ON_ERROR_STOP=1 -f /checks/verify.sql`
6. Run `migrate validate`, then `migrate update` again: it must apply zero changes.
7. `docker compose -f tests/compose.yml down -v` removes only the disposable test project.

The first command sequence proves an upgrade preserves a prior user. Repeat
from an empty test project with a direct `update` to prove a fresh installation.
The SQL check rejects a Patient role and verifies runtime schema/table scope.
Real IAM API connectivity and real environment credentials require separate
integration evidence; this fixture does not claim HU-IAM-001 is complete.

For HU-IAM-003, run `tests/hu-iam-003.sql` after an isolated fresh `update`.
For an upgrade, apply the published `origin/develop` changelog at `b94c57a`
to a disposable database, insert `tests/hu-iam-003-prior.sql`, apply this
branch's changelog, then run `tests/hu-iam-003-upgrade.sql`, `tests/verify.sql`
and the lifecycle test. See the
[HU-IAM-003 verification](tests/hu-iam-003-verification-2026-10-21.md).
The new active/verified constraint will stop an upgrade with inconsistent
legacy accounts; review owner data before retrying rather than changing it
silently.

When implementing later changes, add SQL, reviewed rollback where applicable,
and a change set in the matching folder's `changelog.yaml`. Never edit an
applied change set. Production recovery uses a forward corrective migration.

The repository's existing `.github/CODEOWNERS` and professor-managed `env-tracking.yml` must be preserved when this skeleton is copied into the real repository.

## Governance

Repository workflow, branching, pull request, review, and promotion rules are defined in the Di Lucca canonical documentation:

- [Git conventions](https://github.com/code-corhuila/dlc-docs/blob/main/00-governance/git-conventions.md)

This repository follows those rules rather than duplicating them locally.
