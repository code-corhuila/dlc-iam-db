\set ON_ERROR_STOP on
BEGIN;
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000301','admin-lifecycle@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000302','staff-lifecycle@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1);
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,
   occurred_at,correlation_id,reason,idempotency_key,expected_version)
VALUES
  ('00000000-0000-0000-0000-000000000303','00000000-0000-0000-0000-000000000302',
   'DISABLED','00000000-0000-0000-0000-000000000301','ACTIVE','DISABLED',
   now(),'00000000-0000-0000-0000-000000000304','Employment ended',
   '00000000-0000-0000-0000-000000000305',1),
  ('00000000-0000-0000-0000-000000000306','00000000-0000-0000-0000-000000000302',
   'ENABLED','00000000-0000-0000-0000-000000000301','DISABLED','ACTIVE',
   now(),'00000000-0000-0000-0000-000000000307','Employment resumed',
   '00000000-0000-0000-0000-000000000308',2);
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.staff_account_audit
      WHERE user_id='00000000-0000-0000-0000-000000000302'
        AND reason IS NOT NULL AND idempotency_key IS NOT NULL
        AND expected_version IN (1,2)) <> 2 THEN
    RAISE EXCEPTION 'Lifecycle audit request metadata was not stored';
  END IF;
  BEGIN
    INSERT INTO iam.staff_account_audit
      (audit_id,user_id,action,actor_user_id,prior_status,next_status,
       occurred_at,correlation_id,reason,idempotency_key,expected_version)
    VALUES (gen_random_uuid(),'00000000-0000-0000-0000-000000000302',
      'DISABLED','00000000-0000-0000-0000-000000000301','ACTIVE','DISABLED',
      now(),gen_random_uuid(),'Different request',
      '00000000-0000-0000-0000-000000000305',1);
    RAISE EXCEPTION 'Duplicate lifecycle idempotency key accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.staff_account_audit
      (audit_id,user_id,action,actor_user_id,prior_status,next_status,
       occurred_at,correlation_id,reason,idempotency_key)
    VALUES (gen_random_uuid(),'00000000-0000-0000-0000-000000000302',
      'DISABLED','00000000-0000-0000-0000-000000000301','ACTIVE','DISABLED',
      now(),gen_random_uuid(),'Incomplete request',gen_random_uuid());
    RAISE EXCEPTION 'Incomplete lifecycle request accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.staff_account_audit
      (audit_id,user_id,action,actor_user_id,prior_status,next_status,
       occurred_at,correlation_id,reason,idempotency_key,expected_version)
    VALUES (gen_random_uuid(),'00000000-0000-0000-0000-000000000302',
      'DISABLED','00000000-0000-0000-0000-000000000301','ACTIVE','DISABLED',
      now(),gen_random_uuid(),' ',gen_random_uuid(),1);
    RAISE EXCEPTION 'Blank lifecycle reason accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF has_table_privilege('iam_runtime','iam.staff_account_audit','UPDATE')
     OR has_table_privilege('iam_runtime','iam.staff_account_audit','DELETE')
     OR NOT has_table_privilege('iam_runtime','iam.staff_account_audit','INSERT') THEN
    RAISE EXCEPTION 'Lifecycle audit privileges are incorrect';
  END IF;
END $$;
ROLLBACK;
