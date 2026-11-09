\set ON_ERROR_STOP on
-- ADR-020: service clients, their hashed secrets (two slots for rotation) and grants.
BEGIN;
INSERT INTO iam.service_clients (client_id, status) VALUES ('clinical-api', 'ACTIVE');
INSERT INTO iam.service_client_secrets (client_id, slot, secret_hash)
  VALUES ('clinical-api', 1, '$argon2id$v=19$m=19456,t=2,p=1$test$test');
INSERT INTO iam.service_client_grants (client_id, audience, scope)
  VALUES ('clinical-api', 'patients-api', 'patients:validate');
SET LOCAL ROLE iam_runtime;
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.service_clients c
        JOIN iam.service_client_secrets s USING (client_id)
        JOIN iam.service_client_grants g USING (client_id)
       WHERE c.client_id = 'clinical-api' AND c.status = 'ACTIVE'
         AND g.audience = 'patients-api' AND g.scope = 'patients:validate') <> 1 THEN
    RAISE EXCEPTION 'Runtime cannot read a granted service client';
  END IF;
  BEGIN
    INSERT INTO iam.service_client_grants (client_id, audience, scope)
      VALUES ('clinical-api', 'billing-api', 'billing:encounter-freeze:write');
    RAISE EXCEPTION 'Runtime was able to grant itself a scope';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.service_client_secrets (client_id, slot, secret_hash)
      VALUES ('clinical-api', 3, 'x');
    RAISE EXCEPTION 'A third secret slot was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.service_client_grants (client_id, audience, scope)
      VALUES ('clinical-api', 'patients-api', 'a b');
    RAISE EXCEPTION 'A grant with several scopes was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.service_clients (client_id, status) VALUES ('Bad Client', 'ACTIVE');
    RAISE EXCEPTION 'An invalid client id was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.service_client_grants (client_id, audience, scope)
      VALUES ('unknown-api', 'patients-api', 'patients:validate');
    RAISE EXCEPTION 'A grant for an unknown client was accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
END $$;
ROLLBACK;
