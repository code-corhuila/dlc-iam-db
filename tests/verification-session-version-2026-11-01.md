# HU-IAM-006 session version verification — 2026-11-01

All checks ran on isolated PostgreSQL 17.11 containers with Liquibase 4.33.0.
The two Compose projects used disposable databases and were removed with `down -v`.

| Check | Result |
| --- | --- |
| Fresh store | Nine changesets applied, including `011-iam-session-version`. `hu-iam-session-version-prior.sql` and `hu-iam-session-version.sql` passed as `iam_runtime`. A new session starts at version 1, an update advances it to 2, and direct version edits are rejected. |
| Previous version | `origin/develop` at `05b72fe` applied eight changesets and stored a user and session. This branch applied only `011-iam-session-version`; the existing session received version 1. The same runtime SQL checks passed. |
| Owner scope | `iam_runtime` has IAM schema usage and session SELECT/UPDATE, but cannot create in IAM or read Liquibase history. |
| Repeatability | Liquibase `validate` found no errors. A second `update` ran zero changesets. |
| Recovery | An IAM-only `pg_dump -Fc -n iam` restored into a second disposable database. The updated session retained version 2. |

This migration adds only IAM-owned session metadata. The Auth API must still expose
the approved session list and enforce its own caller-scoped authorization.
