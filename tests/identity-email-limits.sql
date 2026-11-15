\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA patients; -- synthetic neighboring owner, rolled back below
DO $$
BEGIN
  IF NOT has_table_privilege('iam_runtime', 'iam.identity_email_limits', 'SELECT')
     OR NOT has_table_privilege('iam_runtime', 'iam.identity_email_limits', 'INSERT')
     OR NOT has_table_privilege('iam_runtime', 'iam.identity_email_limits', 'UPDATE')
     OR NOT has_table_privilege('iam_runtime', 'iam.identity_email_limits', 'DELETE')
     OR has_schema_privilege('iam_runtime', 'patients', 'USAGE') THEN
    RAISE EXCEPTION 'Identity-email limiter privileges are incorrect';
  END IF;
  BEGIN
    INSERT INTO iam.identity_email_limits
      (purpose,key_kind,key_digest,window_started_at,last_allowed_at,attempt_count)
    VALUES ('MFA','SOURCE_IP',decode(repeat('a',64),'hex'),now(),now(),1);
    RAISE EXCEPTION 'Unsupported identity-email purpose was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.identity_email_limits
      (purpose,key_kind,key_digest,window_started_at,last_allowed_at,attempt_count)
    VALUES ('PASSWORD_RECOVERY','SOURCE_IP',decode(repeat('a',62),'hex'),now(),now(),1);
    RAISE EXCEPTION 'Short digest was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.identity_email_limits
      (purpose,key_kind,key_digest,window_started_at,last_allowed_at,attempt_count)
    VALUES ('PASSWORD_RECOVERY','SOURCE_IP',decode(repeat('a',64),'hex'),now(),now(),11);
    RAISE EXCEPTION 'Excess attempt count was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.identity_email_limits
  (purpose,key_kind,key_digest,window_started_at,last_allowed_at,attempt_count)
VALUES ('PASSWORD_RECOVERY','SOURCE_IP',decode(repeat('a',64),'hex'),now(),now(),1);
UPDATE iam.identity_email_limits SET attempt_count=2
 WHERE purpose='PASSWORD_RECOVERY' AND key_kind='SOURCE_IP'
   AND key_digest=decode(repeat('a',64),'hex');
DO $$
BEGIN
  IF (SELECT attempt_count FROM iam.identity_email_limits
       WHERE purpose='PASSWORD_RECOVERY' AND key_kind='SOURCE_IP'
         AND key_digest=decode(repeat('a',64),'hex')) <> 2 THEN
    RAISE EXCEPTION 'Runtime limiter update failed';
  END IF;
END $$;
ROLLBACK;
