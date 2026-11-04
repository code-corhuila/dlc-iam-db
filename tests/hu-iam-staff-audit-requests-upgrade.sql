\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.staff_account_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000313'
        AND reason IS NULL AND idempotency_key IS NULL AND expected_version IS NULL) <> 1 THEN
    RAISE EXCEPTION 'Previous lifecycle audit row was not preserved';
  END IF;
END $$;
