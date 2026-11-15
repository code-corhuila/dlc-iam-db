\set ON_ERROR_STOP on
INSERT INTO iam.users (user_id,email,password_hash,status,email_verified_at,created_at,updated_at)
VALUES ('00000000-0000-0000-0000-000000000081','prior@example.test','synthetic-hash',
        'ACTIVE',now(),now(),now());
INSERT INTO iam.sessions (session_id,user_id,device_id,created_at,last_user_activity_at,inactivity_expires_at)
VALUES ('00000000-0000-0000-0000-000000000082','00000000-0000-0000-0000-000000000081',
        'synthetic-device',now(),now(),now()+interval '7 days');
INSERT INTO iam.refresh_token_families (family_id,session_id,created_at)
VALUES ('00000000-0000-0000-0000-000000000083','00000000-0000-0000-0000-000000000082',now());
INSERT INTO iam.refresh_credentials (credential_id,family_id,token_hash,issued_at,expires_at)
VALUES ('00000000-0000-0000-0000-000000000084','00000000-0000-0000-0000-000000000083',
        repeat('e',64),now(),now()+interval '7 days');
