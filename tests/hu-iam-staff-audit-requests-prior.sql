\set ON_ERROR_STOP on
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000311','prior-admin-lifecycle@example.test',
   'test-hash','ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000312','prior-staff-lifecycle@example.test',
   'test-hash','ACTIVE',now(),now(),now(),1);
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,
   occurred_at,correlation_id)
VALUES
  ('00000000-0000-0000-0000-000000000313','00000000-0000-0000-0000-000000000312',
   'DISABLED','00000000-0000-0000-0000-000000000311','ACTIVE','DISABLED',
   now(),'00000000-0000-0000-0000-000000000314');
