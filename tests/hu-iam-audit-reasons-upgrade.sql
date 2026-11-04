\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.role_assignment_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000213' AND reason IS NULL) <> 1
     OR (SELECT count(*) FROM iam.account_lock_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000215'
        AND reason IS NULL AND idempotency_key IS NULL AND expected_version IS NULL) <> 1 THEN
    RAISE EXCEPTION 'Audit history or migration record was not preserved';
  END IF;
END $$;
