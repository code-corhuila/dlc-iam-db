\set ON_ERROR_STOP on
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM iam.users WHERE email='prior@example.test') THEN
    RAISE EXCEPTION 'Previous-version user was lost';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM iam.security_challenges
    WHERE challenge_id='00000000-0000-0000-0000-000000000022'
      AND purpose='PASSWORD_RECOVERY' AND consumed_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Previous-version recovery challenge was lost';
  END IF;
END $$;
