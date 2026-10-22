\set ON_ERROR_STOP on
INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000061','prior@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now());
INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000062','00000000-0000-0000-0000-000000000061',
        now(),now(),now()+interval '7 days');
