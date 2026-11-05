SET ROLE iam_runtime;
INSERT INTO iam.users (user_id, email, password_hash, status,
                       email_verified_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000086', 'legacy-admin@example.test',
        'synthetic-hash', 'ACTIVE', now(), now(), now());
INSERT INTO iam.account_lock_audit
  (audit_id, user_id, action, actor_user_id, failed_attempts,
   occurred_at, correlation_id)
VALUES ('00000000-0000-0000-0000-000000000087',
        '00000000-0000-0000-0000-000000000086', 'UNLOCKED',
        '00000000-0000-0000-0000-000000000086', 0, now(),
        '00000000-0000-0000-0000-000000000088');
