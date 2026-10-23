# Staff display-name migration verification

Tested against isolated PostgreSQL 17.11 and Liquibase 4.33.0 containers.

- Empty-store update: 9 change sets applied, including
  `008-iam-staff-display-name`; `tests/hu-iam-staff-name.sql` passed under
  `iam_runtime` (`BEGIN`, `INSERT 0 1`, `DO`, `ROLLBACK`). It verified a
  persisted name and rejection of an untrimmed name.
- Previous-version update: applied 8 existing change sets, inserted one
  synthetic active staff row without a name, then applied the new change set.
  Liquibase reported 1 new and 8 previously run change sets. The prior email
  was preserved and `display_name` remained null for owner backfill.
- The migration does not supply, infer or publish staff names. No other owner
  schema or previously applied change set was changed.
- `liquibase validate` reported no validation errors. A second `update`
  applied zero change sets (9 previously run).

Disposable Compose project names used: `iam-staff-name-empty` and
`iam-staff-name-upgrade`. No host database port was published.
