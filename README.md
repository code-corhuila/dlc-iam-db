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

HU-IAM-005 retains the existing IAM-owned `failed_attempts`, `status` and
`locked_until` columns. The new lock constraint requires a third failure to
carry a bounded expiry, and an append-only `account_lock_audit` table records
lock/unlock facts with a correlation ID and no IP address or raw credential.
Locking an account atomically revokes its existing IAM sessions and refresh
records; a locked account cannot start another session. The Auth API still
owns atomic failure counting, exact 15-minute lock policy, the 10-attempts/IP
rate limit, authorized unlock, generic login errors and approved `UserLocked`
and `UserUnlocked` outbox events. MFA is outside the project under
[ADR-016](https://github.com/code-corhuila/dlc-docs/blob/main/05-architecture/decisions/ADR-016-remove-mfa-from-project-scope.md).

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

For HU-IAM-005, run `tests/hu-iam-005.sql` after an isolated fresh `update`.
For an upgrade, apply published `origin/develop` at `b94c57a`, insert
`tests/hu-iam-005-prior.sql`, apply this branch's changelog, then run
`tests/hu-iam-005-upgrade.sql`, the lock test and `tests/verify.sql`. See
[HU-IAM-005 verification](tests/hu-iam-005-verification-2026-10-21.md).
Inconsistent legacy lock rows stop the migration for owner review; no IAM
data is silently rewritten.

When implementing later changes, add SQL, reviewed rollback where applicable,
and a change set in the matching folder's `changelog.yaml`. Never edit an
applied change set. Production recovery uses a forward corrective migration.

The repository's existing `.github/CODEOWNERS` and professor-managed `env-tracking.yml` must be preserved when this skeleton is copied into the real repository.

## Governance

Repository workflow, branching, pull request, review, and promotion rules are defined in the Di Lucca canonical documentation:

- [Git conventions](https://github.com/code-corhuila/dlc-docs/blob/main/00-governance/git-conventions.md)

This repository follows those rules rather than duplicating them locally.
