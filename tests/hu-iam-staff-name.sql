\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.users
  (user_id, email, password_hash, status, email_verified_at,
   created_at, updated_at, display_name)
VALUES
  ('00000000-0000-0000-0000-000000000101', 'named@example.test',
   'synthetic-hash', 'ACTIVE', now(), now(), now(), 'Example Dentist');
DO $$
BEGIN
  IF (SELECT display_name FROM iam.users
      WHERE email = 'named@example.test') <> 'Example Dentist' THEN
    RAISE EXCEPTION 'Staff display name did not persist';
  END IF;
  BEGIN
    UPDATE iam.users SET display_name = '  Bad Name  '
      WHERE email = 'named@example.test';
    RAISE EXCEPTION 'Untrimmed display name was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
ROLLBACK;
