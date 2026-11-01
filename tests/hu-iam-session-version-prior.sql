INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000111', 'version@example.test', 'hash',
        'ACTIVE', now(), now(), now());
INSERT INTO iam.sessions (session_id,user_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000112',
        '00000000-0000-0000-0000-000000000111', now(), now(), now() + interval '7 days');
