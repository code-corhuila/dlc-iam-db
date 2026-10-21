# dlc-iam-db

IAM-owned PostgreSQL persistence in Di Lucca's shared database.

The physical PostgreSQL database is shared by IAM, Patients, Appointments, and Billing, while each service retains exclusive logical ownership of its own schema. This repository is scoped only to the `iam` schema. IAM must not read from or write to another service's schema during normal runtime; cross-service data exchange must use approved owner APIs or events.

This repository follows the accepted PostgreSQL architecture defined in ADR-007 and ADR-008. ADR-010 preserves the same database ownership boundaries for transversal integration.

The initial Liquibase changesets create staff identity and approved roles,
durable sessions, refresh families and credentials, single-purpose challenges,
an owner outbox, and explicit runtime grants. Existing empty SQL files remain
unreferenced placeholders. The API remains responsible for authentication,
atomic refresh rotation, eligibility checks, event payload minimization and
publishing; a table alone does not prove those behaviors.

The HU-IAM-004 change adds database guards for email-verification and
password-recovery challenges: only these two purposes are accepted; expiry and
consumption order are checked; consumed challenges cannot be changed or reused.
The database stores a hash field, while the Auth API must prove that it hashes
tokens before persistence. MFA challenges are outside this project under
[ADR-016](https://github.com/code-corhuila/dlc-docs/blob/main/05-architecture/decisions/ADR-016-remove-mfa-from-project-scope.md). An upgrade with
an unsupported existing purpose stops at the new constraint; inspect such IAM
rows and resolve them through a reviewed owner-only correction before retrying.

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
HU-IAM-002 adds append-only, runtime-scoped role assignment history without a
second current-role table. Its isolated SQL and recovery results are recorded in
`tests/verification-hu-iam-002.md`.
Real IAM API connectivity and real environment credentials require separate
integration evidence; this fixture does not claim HU-IAM-001 is complete.

For HU-IAM-004, run `tests/hu-iam-004.sql` after a fresh `update`. To verify an
upgrade from the published three-changeset version, initialize an isolated test
database from commit `b94c57a`, insert `tests/hu-iam-004-prior.sql`, apply the
current changelog, then run `tests/hu-iam-004-upgrade.sql`,
`tests/hu-iam-004.sql` and `tests/verify.sql`. The evidence and isolated Compose
project names are in
[HU-IAM-004 verification](tests/hu-iam-004-verification-2026-10-21.md).

When implementing later changes, add SQL, reviewed rollback where applicable,
and a change set in the matching folder's `changelog.yaml`. Never edit an
applied change set. Production recovery uses a forward corrective migration.

The repository's existing `.github/CODEOWNERS` and professor-managed `env-tracking.yml` must be preserved when this skeleton is copied into the real repository.

## Governance

Repository workflow, branching, pull request, review, and promotion rules are defined in the Di Lucca canonical documentation:

- [Git conventions](https://github.com/code-corhuila/dlc-docs/blob/main/00-governance/git-conventions.md)

This repository follows those rules rather than duplicating them locally.
