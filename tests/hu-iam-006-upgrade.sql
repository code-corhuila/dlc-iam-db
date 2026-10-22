\set ON_ERROR_STOP on
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.users WHERE email='prior@example.test') <> 1
     OR (SELECT count(*) FROM iam.sessions WHERE session_id='00000000-0000-0000-0000-000000000082'
         AND revoked_at IS NULL) <> 1
     OR (SELECT count(*) FROM iam.refresh_token_families WHERE family_id='00000000-0000-0000-0000-000000000083'
         AND reuse_detected_at IS NULL) <> 1
     OR (SELECT count(*) FROM iam.refresh_credentials WHERE credential_id='00000000-0000-0000-0000-000000000084'
         AND token_hash=repeat('e',64)) <> 1
     OR (SELECT count(*) FROM iam.databasechangelog
         WHERE id IN ('001-iam-identity', '002-iam-session-security',
                      '001-iam-runtime-grants', '007-iam-session-lineage')) <> 4 THEN
    RAISE EXCEPTION 'Previous-version session, refresh lineage or history changed';
  END IF;
END $$;
