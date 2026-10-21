BEGIN;
CREATE SCHEMA patients; -- synthetic neighboring owner, rolled back below
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.users WHERE email = 'staff@example.test') <> 1 THEN
    RAISE EXCEPTION 'Upgrade lost the existing IAM user';
  END IF;
  IF (SELECT count(*) FROM iam.databasechangelog) <> 3 THEN
    RAISE EXCEPTION 'Expected three applied IAM changesets';
  END IF;
  IF NOT has_schema_privilege('iam_runtime', 'iam', 'USAGE')
     OR has_schema_privilege('iam_runtime', 'iam', 'CREATE')
     OR has_schema_privilege('iam_runtime', 'patients', 'USAGE') THEN
    RAISE EXCEPTION 'Runtime schema privileges are incorrect';
  END IF;
  IF NOT has_table_privilege('iam_runtime', 'iam.users', 'SELECT')
     OR NOT has_table_privilege('iam_runtime', 'iam.users', 'INSERT')
     OR NOT has_table_privilege('iam_runtime', 'iam.users', 'UPDATE')
     OR has_table_privilege('iam_runtime', 'iam.users', 'DELETE')
     OR has_table_privilege('iam_runtime', 'iam.databasechangelog', 'SELECT') THEN
    RAISE EXCEPTION 'Runtime table privileges are incorrect';
  END IF;
  BEGIN
    INSERT INTO iam.user_roles (user_id, role, assigned_at)
    VALUES ('00000000-0000-0000-0000-000000000001', 'PATIENT', now());
    RAISE EXCEPTION 'Patient role was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
ROLLBACK;
