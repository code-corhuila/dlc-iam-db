DO $$
BEGIN
  IF (SELECT count(*) FROM iam.account_lock_audit
      WHERE audit_id = '00000000-0000-0000-0000-000000000087'
        AND actor_user_id = '00000000-0000-0000-0000-000000000086'
        AND unlock_source IS NULL) <> 1 THEN
    RAISE EXCEPTION 'Prior administrator audit row changed';
  END IF;
END;
$$;
