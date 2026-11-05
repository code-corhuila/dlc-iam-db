\set ON_ERROR_STOP on
BEGIN;
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000401','registration-admin@example.test',
   'test-hash','ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000402','registration-staff@example.test',
   'test-hash','PENDING_VERIFICATION',NULL,now(),now(),1);
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
VALUES
  ('00000000-0000-0000-0000-000000000403','00000000-0000-0000-0000-000000000402',
   'REGISTERED','00000000-0000-0000-0000-000000000401',NULL,'PENDING_VERIFICATION',
   now(),'00000000-0000-0000-0000-000000000404');
INSERT INTO iam.registration_requests
  (idempotency_key,actor_user_id,user_id,request_proof,created_at)
VALUES
  ('00000000-0000-0000-0000-000000000405','00000000-0000-0000-0000-000000000401',
   '00000000-0000-0000-0000-000000000402',decode(repeat('ab',32),'hex'),now());
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.registration_requests
      WHERE idempotency_key='00000000-0000-0000-0000-000000000405'
        AND octet_length(request_proof)=32) <> 1 THEN
    RAISE EXCEPTION 'Registration replay record missing';
  END IF;
  BEGIN
    INSERT INTO iam.registration_requests VALUES
      ('00000000-0000-0000-0000-000000000405',
       '00000000-0000-0000-0000-000000000401',
       '00000000-0000-0000-0000-000000000402',decode(repeat('cd',32),'hex'),now());
    RAISE EXCEPTION 'Duplicate key accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.registration_requests VALUES
      (gen_random_uuid(),'00000000-0000-0000-0000-000000000401',
       '00000000-0000-0000-0000-000000000402',decode('ff','hex'),now());
    RAISE EXCEPTION 'Short proof accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF NOT has_table_privilege('iam_runtime','iam.registration_requests','SELECT')
     OR NOT has_table_privilege('iam_runtime','iam.registration_requests','INSERT')
     OR has_table_privilege('iam_runtime','iam.registration_requests','UPDATE')
     OR has_table_privilege('iam_runtime','iam.registration_requests','DELETE') THEN
    RAISE EXCEPTION 'Registration request grants incorrect';
  END IF;
END $$;
ROLLBACK;
