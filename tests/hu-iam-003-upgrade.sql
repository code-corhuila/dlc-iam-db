\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.users WHERE email='prior@example.test' AND status='ACTIVE') <> 1
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000032'
         AND revoked_at IS NULL) <> 1
     OR (SELECT count(*) FROM iam.databasechangelog
         WHERE id IN ('001-iam-identity', '002-iam-session-security',
                      '001-iam-runtime-grants', '004-iam-staff-lifecycle')) <> 4 THEN
    RAISE EXCEPTION 'Previous-version IAM records or migration history changed';
  END IF;
  IF to_regclass('iam.staff_account_audit') IS NULL THEN
    RAISE EXCEPTION 'Staff audit table missing after upgrade';
  END IF;
END $$;
