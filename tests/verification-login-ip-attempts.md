# IAM login IP attempt migration verification

Isolated PostgreSQL 17.11 and Liquibase 4.33.0; no host port published.

- Empty store: 10 change sets applied, including `009-iam-login-ip-attempts`.
  The SQL probe ran as `iam_runtime`, inserted, selected and deleted a
  synthetic 32-byte digest, and rejected a one-byte digest.
- Previous version: a fresh container received the first 9 change sets from
  the preceding branch. The new migration ran against that **same** database
  container and Liquibase reported 1 applied, 9 previously run. The runtime
  SQL probe passed there too.
- `liquibase validate` passed and repeating `update` applied zero changes.

The table holds only a keyed digest of the client IP and attempt time. API
code must provide the keyed digest, serialize same-IP checks, enforce the
five-minute sliding window and purge expired attempts; this DB change alone
does not enforce rate limiting. No other owner schema or applied change set
was changed.
