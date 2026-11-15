\set ON_ERROR_STOP on
INSERT INTO iam.users (user_id,email,password_hash,status,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000021','prior@example.test','synthetic-hash',
        'PENDING_VERIFICATION',now(),now());
INSERT INTO iam.security_challenges
  (challenge_id,user_id,purpose,token_hash,created_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000022','00000000-0000-0000-0000-000000000021',
        'PASSWORD_RECOVERY',repeat('d',64),now(),now()+interval '1 day');
