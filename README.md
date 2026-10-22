# dlc-iam-db

Structural skeleton for the IAM-owned `iam` schema in Di Lucca's shared PostgreSQL database.

The physical PostgreSQL database is shared by IAM, Patients, Appointments, and Billing, while each service retains exclusive logical ownership of its own schema. This repository is scoped only to the `iam` schema. IAM must not read from or write to another service's schema during normal runtime; cross-service data exchange must use approved owner APIs or events.

This repository follows the accepted PostgreSQL architecture defined in ADR-007 and ADR-008. ADR-010 preserves the same database ownership boundaries for transversal integration.

This revision contains no executable database change. The empty SQL files are placeholders and are not referenced by a Liquibase change set. The changelog hierarchy is valid but currently applies zero changes. `deploy/compose.yml` does not launch a database or migration runner yet.

When implementing a change, add its SQL, its reviewed rollback file when applicable, and a change set in the matching folder's `changelog.yaml`. Keep changes within the `iam` schema. Production recovery uses a forward corrective migration; rollback files are tested in non-production.

The repository's existing `.github/CODEOWNERS` and professor-managed `env-tracking.yml` must be preserved when this skeleton is copied into the real repository.

## Governance

Repository workflow, branching, pull request, review, and promotion rules are defined in the Di Lucca canonical documentation:

- [Git conventions](https://github.com/code-corhuila/dlc-docs/blob/main/00-governance/git-conventions.md)

This repository follows those rules rather than duplicating them locally.