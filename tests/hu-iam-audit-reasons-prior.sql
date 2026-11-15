\set ON_ERROR_STOP on
INSERT INTO iam.users
  (user_id,email,password_hash,status,email_verified_at,created_at,updated_at,version)
VALUES
  ('00000000-0000-0000-0000-000000000211','prior-admin@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1),
  ('00000000-0000-0000-0000-000000000212','prior-staff@example.test','test-hash',
   'ACTIVE',now(),now(),now(),1);
INSERT INTO iam.role_assignment_audit
  (audit_id,user_id,role,action,actor_user_id,occurred_at,correlation_id)
VALUES
  ('00000000-0000-0000-0000-000000000213','00000000-0000-0000-0000-000000000212',
   'DENTIST','ASSIGNED','00000000-0000-0000-0000-000000000211',now(),
   '00000000-0000-0000-0000-000000000214');
INSERT INTO iam.account_lock_audit
  (audit_id,user_id,action,actor_user_id,failed_attempts,occurred_at,correlation_id)
VALUES
  ('00000000-0000-0000-0000-000000000215','00000000-0000-0000-0000-000000000212',
   'UNLOCKED','00000000-0000-0000-0000-000000000211',0,now(),
   '00000000-0000-0000-0000-000000000216');
