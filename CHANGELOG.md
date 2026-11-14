# Changelog

Notable changes to `dlc-iam-db` are recorded here.

## [3.0.0] - 2026-11-14

First release of the IAM database migrations to `main`, promoted from `qa` for MVP 3.

### Added

- `iam` schema persistence for staff users, roles, role assignment audit, verification and recovery challenges and sessions with lineage and versioning.
- Staff lifecycle audit with request reasons, account lock audit and unlock request keys.
- Registration replay requests that preserve the original response for keyed replay.
- Identity email request limits and minimal login IP attempt windows.
- Owner outbox with delivery state tracking.
- Service clients, secrets and grants for client-credential service tokens (ADR-020).
- Owned staff display name for the Auth contract.

### Fixed

- Automatic account unlock expiry is audited.

### Notes

- Seed changesets run only in the `dev` and `qa` Liquibase contexts; `prod` applies schema and grants only.
