\set ON_ERROR_STOP on
BEGIN;
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000201','admin-reason@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000202','staff-reason@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1);
INSERT INTO iam.role_assignment_audit
  (audit_id,user_id,role,action,actor_user_id,occurred_at,correlation_id,reason)
VALUES
  ('00000000-0000-0000-0000-000000000203','00000000-0000-0000-0000-000000000202',
   'DENTIST','ASSIGNED','00000000-0000-0000-0000-000000000201',now(),
   '00000000-0000-0000-0000-000000000204','Approved clinical duty');
INSERT INTO iam.account_lock_audit
  (audit_id,user_id,action,actor_user_id,failed_attempts,occurred_at,correlation_id,
   reason,idempotency_key,expected_version)
VALUES
  ('00000000-0000-0000-0000-000000000205','00000000-0000-0000-0000-000000000202',
   'UNLOCKED','00000000-0000-0000-0000-000000000201',0,now(),
   '00000000-0000-0000-0000-000000000206','Identity verified',
   '00000000-0000-0000-0000-000000000207',1);
DO $$
BEGIN
  IF (SELECT reason FROM iam.role_assignment_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000203') <> 'Approved clinical duty'
     OR (SELECT expected_version FROM iam.account_lock_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000205') <> 1 THEN
    RAISE EXCEPTION 'Audit reason or request metadata was not stored';
  END IF;
  BEGIN
    INSERT INTO iam.account_lock_audit
      (audit_id,user_id,action,actor_user_id,failed_attempts,occurred_at,correlation_id,
       reason,idempotency_key,expected_version)
    VALUES
      (gen_random_uuid(),'00000000-0000-0000-0000-000000000202','UNLOCKED',
       '00000000-0000-0000-0000-000000000201',0,now(),gen_random_uuid(),
       'Different request','00000000-0000-0000-0000-000000000207',1);
    RAISE EXCEPTION 'Duplicate unlock idempotency key accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.account_lock_audit
      (audit_id,user_id,action,actor_user_id,failed_attempts,occurred_at,correlation_id,
       reason,idempotency_key)
    VALUES
      (gen_random_uuid(),'00000000-0000-0000-0000-000000000202','UNLOCKED',
       '00000000-0000-0000-0000-000000000201',0,now(),gen_random_uuid(),
       'Incomplete request',gen_random_uuid());
    RAISE EXCEPTION 'Incomplete unlock request accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.role_assignment_audit
      (audit_id,user_id,role,action,actor_user_id,occurred_at,correlation_id,reason)
    VALUES
      (gen_random_uuid(),'00000000-0000-0000-0000-000000000202','DENTIST',
       'ASSIGNED','00000000-0000-0000-0000-000000000201',now(),gen_random_uuid(),'  ');
    RAISE EXCEPTION 'Blank role-assignment reason accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF has_table_privilege('iam_runtime','iam.account_lock_audit','UPDATE')
     OR has_table_privilege('iam_runtime','iam.role_assignment_audit','DELETE') THEN
    RAISE EXCEPTION 'Audit runtime privileges became too broad';
  END IF;
END $$;
ROLLBACK;
