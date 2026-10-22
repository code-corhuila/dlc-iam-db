\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000041','admin@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now());
INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000042','dentist@example.test','synthetic-hash',
        'PENDING_VERIFICATION',now(),now());
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
    VALUES ('00000000-0000-0000-0000-000000000043','DENTIST@example.test','synthetic-hash',
            'PENDING_VERIFICATION',now(),now());
    RAISE EXCEPTION 'Unnormalized email accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
    VALUES ('00000000-0000-0000-0000-000000000043','dentist@example.test','synthetic-hash',
            'PENDING_VERIFICATION',now(),now());
    RAISE EXCEPTION 'Duplicate email accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
    VALUES ('00000000-0000-0000-0000-000000000043','unverified@example.test','synthetic-hash',
            'ACTIVE',now(),now());
    RAISE EXCEPTION 'Unverified active account accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
VALUES ('00000000-0000-0000-0000-000000000044','00000000-0000-0000-0000-000000000042',
        'REGISTERED','00000000-0000-0000-0000-000000000041',NULL,'PENDING_VERIFICATION',now(),
        '00000000-0000-0000-0000-000000000045');
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.staff_account_audit
      (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
    VALUES ('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000042',
            'DISABLED','00000000-0000-0000-0000-000000000041',NULL,'DISABLED',now(),
            '00000000-0000-0000-0000-000000000045');
    RAISE EXCEPTION 'Audit transition without prior status accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
UPDATE iam.users SET status='ACTIVE',email_verified_at=now(),updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000042';
INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000046','00000000-0000-0000-0000-000000000042',
        now(),now(),now()+interval '7 days');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000047','00000000-0000-0000-0000-000000000046',now());
INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000048','00000000-0000-0000-0000-000000000047',
        repeat('a',64),now(),now()+interval '7 days');
UPDATE iam.users SET status='DISABLED',updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000042';
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
VALUES ('00000000-0000-0000-0000-000000000049','00000000-0000-0000-0000-000000000042',
        'DISABLED','00000000-0000-0000-0000-000000000041','ACTIVE','DISABLED',now(),
        '00000000-0000-0000-0000-000000000050');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000046'
        AND revoked_at IS NOT NULL AND revocation_reason='ACCOUNT_DISABLED') <> 1
     OR (SELECT count(*) FROM iam.refresh_token_families WHERE family_id='00000000-0000-0000-0000-000000000047'
        AND revoked_at IS NOT NULL) <> 1
     OR (SELECT count(*) FROM iam.refresh_credentials WHERE credential_id='00000000-0000-0000-0000-000000000048'
        AND revoked_at IS NOT NULL) <> 1 THEN
    RAISE EXCEPTION 'Disable did not durably revoke all session credentials';
  END IF;
  BEGIN
    INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
    VALUES ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-000000000042',
            now(),now(),now()+interval '7 days');
    RAISE EXCEPTION 'Disabled account started a session';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Disabled account started a session' THEN RAISE; END IF;
  END;
  IF NOT has_table_privilege('iam_runtime','iam.staff_account_audit','SELECT')
     OR NOT has_table_privilege('iam_runtime','iam.staff_account_audit','INSERT')
     OR has_table_privilege('iam_runtime','iam.staff_account_audit','UPDATE')
     OR has_table_privilege('iam_runtime','iam.staff_account_audit','DELETE')
     OR has_function_privilege('iam_runtime','iam.guard_session_eligibility()','EXECUTE') THEN
    RAISE EXCEPTION 'Runtime staff audit or function privileges are incorrect';
  END IF;
END $$;
UPDATE iam.users SET status='ACTIVE',updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000042';
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
VALUES ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-000000000042',
        'ENABLED','00000000-0000-0000-0000-000000000041','DISABLED','ACTIVE',now(),
        '00000000-0000-0000-0000-000000000053');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.staff_account_audit WHERE user_id='00000000-0000-0000-0000-000000000042') <> 3
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000046'
         AND revoked_at IS NOT NULL) <> 1 THEN
    RAISE EXCEPTION 'Staff audit or revocation history was lost on enable';
  END IF;
END $$;
ROLLBACK;
