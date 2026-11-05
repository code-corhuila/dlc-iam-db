\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.staff_account_audit
      WHERE audit_id='00000000-0000-0000-0000-000000000413'
        AND action='REGISTERED') <> 1 THEN
    RAISE EXCEPTION 'Prior registration audit row was changed';
  END IF;
  IF to_regclass('iam.registration_requests') IS NULL THEN
    RAISE EXCEPTION 'Registration request table missing after upgrade';
  END IF;
  IF (SELECT count(*) FROM iam.registration_requests) <> 0 THEN
    RAISE EXCEPTION 'Upgrade invented replay records for old registrations';
  END IF;
END $$;
