-- One-time owner bootstrap, run by the platform DBA before Liquibase.
-- Set passwords through the secret manager; never put them in this file.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'iam_migrator') THEN
    CREATE ROLE iam_migrator LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'iam_runtime') THEN
    CREATE ROLE iam_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_roles
    WHERE rolname IN ('iam_migrator', 'iam_runtime')
      AND (NOT rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)
  ) THEN
    RAISE EXCEPTION 'Existing IAM role has unexpected privileges';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_namespace n
    JOIN pg_roles r ON r.oid = n.nspowner
    WHERE n.nspname = 'iam' AND r.rolname <> 'iam_migrator'
  ) THEN
    RAISE EXCEPTION 'Existing IAM schema has another owner';
  END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS iam AUTHORIZATION iam_migrator;
REVOKE ALL ON SCHEMA iam FROM PUBLIC;
GRANT USAGE ON SCHEMA iam TO iam_runtime;
