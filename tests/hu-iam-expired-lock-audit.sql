BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.users (user_id, email, password_hash, status,
                       email_verified_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000081', 'expiry@example.test',
        'synthetic-hash', 'ACTIVE', now(), now(), now());
INSERT INTO iam.account_lock_audit
  (audit_id, user_id, action, failed_attempts, occurred_at,
   correlation_id, unlock_source)
VALUES ('00000000-0000-0000-0000-000000000082',
        '00000000-0000-0000-0000-000000000081', 'UNLOCKED', 0, now(),
        '00000000-0000-0000-0000-000000000083', 'EXPIRY');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.account_lock_audit
      WHERE unlock_source = 'EXPIRY' AND actor_user_id IS NULL
        AND user_id = '00000000-0000-0000-0000-000000000081') <> 1 THEN
    RAISE EXCEPTION 'Expiry unlock did not persist';
  END IF;
  BEGIN
    INSERT INTO iam.account_lock_audit
      (audit_id, user_id, action, failed_attempts, occurred_at, correlation_id)
    VALUES ('00000000-0000-0000-0000-000000000084',
            '00000000-0000-0000-0000-000000000081', 'UNLOCKED', 0, now(),
            '00000000-0000-0000-0000-000000000085');
    RAISE EXCEPTION 'Unattributed unlock was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$$;
ROLLBACK;
