\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000085','sessions@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now());
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.sessions (session_id,user_id,device_id,created_at,last_user_activity_at,inactivity_expires_at)
    VALUES ('00000000-0000-0000-0000-000000000086','00000000-0000-0000-0000-000000000085',
            ' ',now(),now(),now()+interval '7 days');
    RAISE EXCEPTION 'Blank device accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
    VALUES ('00000000-0000-0000-0000-000000000086','00000000-0000-0000-0000-000000000085',
            now(),now(),now()+interval '8 days');
    RAISE EXCEPTION 'Eight-day inactivity accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
INSERT INTO iam.sessions (session_id,user_id,device_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000086','00000000-0000-0000-0000-000000000085',
        'synthetic-device',now(),now(),now()+interval '7 days');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000087','00000000-0000-0000-0000-000000000086',now());
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
    VALUES ('00000000-0000-0000-0000-000000000088','00000000-0000-0000-0000-000000000087',
            repeat('f',64),now(),now()+interval '8 days');
    RAISE EXCEPTION 'Eight-day refresh accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000088','00000000-0000-0000-0000-000000000087',
        repeat('f',64),now(),now()+interval '7 days');
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.refresh_credentials
      (credential_id,family_id,token_hash,predecessor_id,issued_at,expires_at)
    VALUES ('00000000-0000-0000-0000-000000000089','00000000-0000-0000-0000-000000000087',
            repeat('g',64),'00000000-0000-0000-0000-000000000088',now(),now()+interval '7 days');
    RAISE EXCEPTION 'Successor before consumption accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Successor before consumption accepted' THEN RAISE; END IF;
  END;
  BEGIN
    INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
    VALUES ('00000000-0000-0000-0000-000000000090','00000000-0000-0000-0000-000000000087',
            repeat('h',64),now(),now()+interval '7 days');
    RAISE EXCEPTION 'Second family root accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END $$;
UPDATE iam.refresh_credentials SET consumed_at=now()
  WHERE credential_id='00000000-0000-0000-0000-000000000088';
INSERT INTO iam.refresh_credentials
  (credential_id,family_id,token_hash,predecessor_id,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000089','00000000-0000-0000-0000-000000000087',
        repeat('g',64),'00000000-0000-0000-0000-000000000088',now(),now()+interval '7 days');
DO $$
BEGIN
  BEGIN
    UPDATE iam.refresh_credentials SET consumed_at=NULL
      WHERE credential_id='00000000-0000-0000-0000-000000000088';
    RAISE EXCEPTION 'Consumed refresh credential reset';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Consumed refresh credential reset' THEN RAISE; END IF;
  END;
END $$;
UPDATE iam.refresh_token_families SET reuse_detected_at=now()
  WHERE family_id='00000000-0000-0000-0000-000000000087';
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.refresh_token_families WHERE family_id='00000000-0000-0000-0000-000000000087'
        AND reuse_detected_at IS NOT NULL AND revoked_at IS NOT NULL) <> 1
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000086'
        AND revoked_at IS NOT NULL AND revocation_reason='REFRESH_REUSE') <> 1
     OR (SELECT count(*) FROM iam.refresh_credentials WHERE family_id='00000000-0000-0000-0000-000000000087'
        AND revoked_at IS NOT NULL) <> 2 THEN
    RAISE EXCEPTION 'Reuse evidence or revocation was not persisted';
  END IF;
  BEGIN
    UPDATE iam.refresh_token_families SET reuse_detected_at=NULL
      WHERE family_id='00000000-0000-0000-0000-000000000087';
    RAISE EXCEPTION 'Reuse evidence reset';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Reuse evidence reset' THEN RAISE; END IF;
  END;
  BEGIN
    UPDATE iam.sessions SET revoked_at=NULL,revocation_reason=NULL
      WHERE session_id='00000000-0000-0000-0000-000000000086';
    RAISE EXCEPTION 'Session revocation reset';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Session revocation reset' THEN RAISE; END IF;
  END;
  IF has_function_privilege('iam_runtime','iam.guard_refresh_credential()','EXECUTE') THEN
    RAISE EXCEPTION 'Runtime can directly execute refresh guard';
  END IF;
END $$;
INSERT INTO iam.sessions (session_id,user_id,device_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000091','00000000-0000-0000-0000-000000000085',
        'old-device',now()-interval '8 days',now()-interval '8 days',now()-interval '1 day');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000092','00000000-0000-0000-0000-000000000091',
        now()-interval '8 days');
DO $$
BEGIN
  BEGIN
    UPDATE iam.sessions SET last_user_activity_at=now(),inactivity_expires_at=now()+interval '7 days'
      WHERE session_id='00000000-0000-0000-0000-000000000091';
    RAISE EXCEPTION 'Inactive session was extended';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Inactive session was extended' THEN RAISE; END IF;
  END;
  BEGIN
    INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
    VALUES ('00000000-0000-0000-0000-000000000093','00000000-0000-0000-0000-000000000092',
            repeat('i',64),now(),now()+interval '7 days');
    RAISE EXCEPTION 'Inactive session obtained refresh credential';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Inactive session obtained refresh credential' THEN RAISE; END IF;
  END;
END $$;
INSERT INTO iam.sessions (session_id,user_id,device_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000094','00000000-0000-0000-0000-000000000085',
        'logout-device',now(),now(),now()+interval '7 days');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000095','00000000-0000-0000-0000-000000000094',now());
INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000096','00000000-0000-0000-0000-000000000095',
        repeat('j',64),now(),now()+interval '7 days');
UPDATE iam.sessions SET revoked_at=now(),revocation_reason='LOGOUT'
  WHERE session_id='00000000-0000-0000-0000-000000000094';
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.refresh_token_families WHERE family_id='00000000-0000-0000-0000-000000000095'
        AND revoked_at IS NOT NULL) <> 1
     OR (SELECT count(*) FROM iam.refresh_credentials WHERE credential_id='00000000-0000-0000-0000-000000000096'
        AND revoked_at IS NOT NULL) <> 1 THEN
    RAISE EXCEPTION 'Logout did not persist family and credential revocation';
  END IF;
END $$;
ROLLBACK;
