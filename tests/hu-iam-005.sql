\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000063','admin@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now()),
       ('00000000-0000-0000-0000-000000000064','locked@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now());
INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000065','00000000-0000-0000-0000-000000000064',
        now(),now(),now()+interval '7 days');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000066','00000000-0000-0000-0000-000000000065',now());
INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000067','00000000-0000-0000-0000-000000000066',
        repeat('d',64),now(),now()+interval '7 days');
UPDATE iam.users SET failed_attempts=1,updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000064';
UPDATE iam.users SET failed_attempts=2,updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000064';
DO $$
BEGIN
  BEGIN
    UPDATE iam.users SET status='LOCKED',failed_attempts=3,updated_at=now()
      WHERE user_id='00000000-0000-0000-0000-000000000064';
    RAISE EXCEPTION 'Lock without expiry accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
UPDATE iam.users SET status='LOCKED',failed_attempts=3,
    updated_at=now(),locked_until=now()+interval '15 minutes'
  WHERE user_id='00000000-0000-0000-0000-000000000064';
INSERT INTO iam.account_lock_audit
  (audit_id,user_id,action,failed_attempts,locked_until,occurred_at,correlation_id)
VALUES ('00000000-0000-0000-0000-000000000068','00000000-0000-0000-0000-000000000064',
        'LOCKED',3,now()+interval '15 minutes',now(),
        '00000000-0000-0000-0000-000000000069');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000065'
        AND revoked_at IS NOT NULL AND revocation_reason='ACCOUNT_LOCKED') <> 1
     OR (SELECT count(*) FROM iam.refresh_token_families WHERE family_id='00000000-0000-0000-0000-000000000066'
        AND revoked_at IS NOT NULL) <> 1
     OR (SELECT count(*) FROM iam.refresh_credentials WHERE credential_id='00000000-0000-0000-0000-000000000067'
        AND revoked_at IS NOT NULL) <> 1 THEN
    RAISE EXCEPTION 'Lock did not revoke session credentials';
  END IF;
  BEGIN
    INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
    VALUES ('00000000-0000-0000-0000-000000000070','00000000-0000-0000-0000-000000000064',
            now(),now(),now()+interval '7 days');
    RAISE EXCEPTION 'Locked account started a session';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Locked account started a session' THEN RAISE; END IF;
  END;
  BEGIN
    INSERT INTO iam.account_lock_audit
      (audit_id,user_id,action,failed_attempts,occurred_at,correlation_id)
    VALUES ('00000000-0000-0000-0000-000000000071','00000000-0000-0000-0000-000000000064',
            'UNLOCKED',0,now(),'00000000-0000-0000-0000-000000000072');
    RAISE EXCEPTION 'Unlock without actor accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF NOT has_table_privilege('iam_runtime','iam.account_lock_audit','INSERT')
     OR has_table_privilege('iam_runtime','iam.account_lock_audit','UPDATE')
     OR has_table_privilege('iam_runtime','iam.account_lock_audit','DELETE')
     OR has_function_privilege('iam_runtime','iam.guard_locked_session()','EXECUTE') THEN
    RAISE EXCEPTION 'Runtime account-lock privileges are incorrect';
  END IF;
END $$;
UPDATE iam.users SET status='ACTIVE',failed_attempts=0,locked_until=NULL,updated_at=now()
  WHERE user_id='00000000-0000-0000-0000-000000000064';
INSERT INTO iam.account_lock_audit
  (audit_id,user_id,action,actor_user_id,failed_attempts,occurred_at,correlation_id)
VALUES ('00000000-0000-0000-0000-000000000073','00000000-0000-0000-0000-000000000064',
        'UNLOCKED','00000000-0000-0000-0000-000000000063',0,now(),
        '00000000-0000-0000-0000-000000000074');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.account_lock_audit WHERE user_id='00000000-0000-0000-0000-000000000064') <> 2
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000065'
         AND revoked_at IS NOT NULL) <> 1 THEN
    RAISE EXCEPTION 'Unlock lost audit or revived a revoked session';
  END IF;
END $$;
ROLLBACK;
