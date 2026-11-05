\set ON_ERROR_STOP on
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000411','prior-registration-admin@example.test',
   'test-hash','ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000412','prior-registration-staff@example.test',
   'test-hash','PENDING_VERIFICATION',NULL,now(),now(),1);
INSERT INTO iam.staff_account_audit
  (audit_id,user_id,action,actor_user_id,prior_status,next_status,occurred_at,correlation_id)
VALUES
  ('00000000-0000-0000-0000-000000000413','00000000-0000-0000-0000-000000000412',
   'REGISTERED','00000000-0000-0000-0000-000000000411',NULL,'PENDING_VERIFICATION',
   now(),'00000000-0000-0000-0000-000000000414');
