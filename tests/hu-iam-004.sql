\set ON_ERROR_STOP on
BEGIN;
INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000011','challenge@example.test','synthetic-hash',
        'PENDING_VERIFICATION',now(),now());
INSERT INTO iam.security_challenges
  (challenge_id,user_id,purpose,token_hash,created_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000011',
        'EMAIL_VERIFICATION',repeat('a',64),now(),now()+interval '1 hour');
DO $$
DECLARE affected integer;
BEGIN
  UPDATE iam.security_challenges SET consumed_at=now()
    WHERE challenge_id='00000000-0000-0000-0000-000000000012'
      AND purpose='PASSWORD_RECOVERY' AND consumed_at IS NULL AND expires_at>now();
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'Wrong-purpose consume succeeded'; END IF;
  BEGIN
    INSERT INTO iam.security_challenges
      (challenge_id,user_id,purpose,token_hash,created_at,expires_at)
    VALUES ('00000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000011',
            'MFA',repeat('b',64),now(),now()+interval '1 hour');
    RAISE EXCEPTION 'MFA purpose was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  UPDATE iam.security_challenges SET consumed_at=now()
    WHERE challenge_id='00000000-0000-0000-0000-000000000012'
      AND purpose='EMAIL_VERIFICATION' AND consumed_at IS NULL AND expires_at>now();
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 1 THEN RAISE EXCEPTION 'First consume failed'; END IF;
  UPDATE iam.security_challenges SET consumed_at=now()
    WHERE challenge_id='00000000-0000-0000-0000-000000000012'
      AND purpose='EMAIL_VERIFICATION' AND consumed_at IS NULL AND expires_at>now();
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'Consumed challenge was reused'; END IF;
  BEGIN
    UPDATE iam.security_challenges SET consumed_at=NULL
      WHERE challenge_id='00000000-0000-0000-0000-000000000012';
    RAISE EXCEPTION 'Consumed challenge was reset';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Consumed challenge was reset' THEN RAISE; END IF;
  END;
  INSERT INTO iam.security_challenges
    (challenge_id,user_id,purpose,token_hash,created_at,expires_at)
  VALUES ('00000000-0000-0000-0000-000000000015','00000000-0000-0000-0000-000000000011',
          'PASSWORD_RECOVERY',repeat('c',64),now()-interval '2 hours',now()-interval '1 hour');
  BEGIN
    UPDATE iam.security_challenges SET consumed_at=now()
      WHERE challenge_id='00000000-0000-0000-0000-000000000015';
    RAISE EXCEPTION 'Expired challenge was consumed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Expired challenge was consumed' THEN RAISE; END IF;
  END;
  BEGIN
    UPDATE iam.security_challenges SET purpose='EMAIL_VERIFICATION'
      WHERE challenge_id='00000000-0000-0000-0000-000000000015';
    RAISE EXCEPTION 'Challenge purpose was changed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Challenge purpose was changed' THEN RAISE; END IF;
  END;
  IF has_table_privilege('iam_runtime','iam.security_challenges','DELETE')
     OR has_function_privilege('iam_runtime','iam.guard_challenge_consumption()','EXECUTE') THEN
    RAISE EXCEPTION 'Runtime challenge privileges are too broad';
  END IF;
END $$;
ROLLBACK;
