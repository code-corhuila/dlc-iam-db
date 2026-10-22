\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.users WHERE email='prior@example.test' AND failed_attempts=0
        AND locked_until IS NULL) <> 1
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000062'
         AND revoked_at IS NULL) <> 1
     OR (SELECT count(*) FROM iam.databasechangelog
         WHERE id IN ('001-iam-identity', '002-iam-session-security',
                      '001-iam-runtime-grants', '006-iam-account-lock')) <> 4 THEN
    RAISE EXCEPTION 'Previous-version account, session or history changed';
  END IF;
  IF to_regclass('iam.account_lock_audit') IS NULL THEN
    RAISE EXCEPTION 'Account lock audit table missing';
  END IF;
END $$;
