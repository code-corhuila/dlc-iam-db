DO $$
BEGIN
  IF NOT has_schema_privilege('iam_runtime', 'iam', 'USAGE')
     OR has_schema_privilege('iam_runtime', 'iam', 'CREATE')
     OR NOT has_table_privilege('iam_runtime', 'iam.sessions', 'SELECT')
     OR NOT has_table_privilege('iam_runtime', 'iam.sessions', 'UPDATE')
     OR has_table_privilege('iam_runtime', 'iam.databasechangelog', 'SELECT') THEN
    RAISE EXCEPTION 'IAM runtime scope changed';
  END IF;
  IF (SELECT version FROM iam.sessions
      WHERE session_id = '00000000-0000-0000-0000-000000000112') <> 1 THEN
    RAISE EXCEPTION 'Prior session did not receive version 1';
  END IF;
END $$;

UPDATE iam.sessions SET device_id = 'device-a'
WHERE session_id = '00000000-0000-0000-0000-000000000112';
DO $$
BEGIN
  IF (SELECT version FROM iam.sessions
      WHERE session_id = '00000000-0000-0000-0000-000000000112') <> 2 THEN
    RAISE EXCEPTION 'Session update did not advance version';
  END IF;
END $$;

DO $$
BEGIN
  BEGIN
    UPDATE iam.sessions SET version = 99
    WHERE session_id = '00000000-0000-0000-0000-000000000112';
    RAISE EXCEPTION 'Runtime changed the managed version';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'Runtime changed the managed version' THEN RAISE; END IF;
  END;
  IF (SELECT version FROM iam.sessions
      WHERE session_id = '00000000-0000-0000-0000-000000000112') <> 2 THEN
    RAISE EXCEPTION 'Rejected version write changed the row';
  END IF;
END $$;
