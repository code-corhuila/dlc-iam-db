# dlc-iam-db

Structural skeleton for the IAM-owned `iam` schema in Di Lucca's shared PostgreSQL instance.

This revision contains no executable database change. The empty SQL files are placeholders and are not referenced by a Liquibase change set. The changelog hierarchy is valid but currently applies zero changes. `deploy/compose.yml` does not launch a database or migration runner yet.

When implementing a change, add its SQL, its reviewed rollback file when applicable, and a change set in the matching folder's `changelog.yaml`. Keep changes within the `iam` schema. Production recovery uses a forward corrective migration; rollback files are tested in non-production.

The repository's existing `.github/CODEOWNERS` and professor-managed `env-tracking.yml` must be preserved when this skeleton is copied into the real repository.
