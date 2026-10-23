BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.login_ip_attempts (attempt_id, ip_digest, occurred_at)
VALUES ('00000000-0000-0000-0000-000000000091', decode(repeat('ab', 32), 'hex'), now());
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.login_ip_attempts
      WHERE ip_digest = decode(repeat('ab', 32), 'hex')) <> 1 THEN
    RAISE EXCEPTION 'IAM runtime cannot inspect its login attempt';
  END IF;
  BEGIN
    INSERT INTO iam.login_ip_attempts (attempt_id, ip_digest, occurred_at)
    VALUES ('00000000-0000-0000-0000-000000000092', decode('ab', 'hex'), now());
    RAISE EXCEPTION 'Short digest was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$$;
DELETE FROM iam.login_ip_attempts
WHERE attempt_id = '00000000-0000-0000-0000-000000000091';
ROLLBACK;
