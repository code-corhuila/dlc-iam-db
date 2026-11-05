BEGIN;
SET LOCAL ROLE iam_runtime;
INSERT INTO iam.outbox_events
  (event_id,event_type,aggregate_id,correlation_id,causation_id,payload,occurred_at)
VALUES ('00000000-0000-4000-8000-000000000016','UserLocked',
        '00000000-0000-4000-8000-000000000017',
        '00000000-0000-4000-8000-000000000018',
        '00000000-0000-4000-8000-000000000018',
        '{"userId":"00000000-0000-4000-8000-000000000017"}',now());
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM iam.outbox_events
     WHERE event_id='00000000-0000-4000-8000-000000000016'
       AND delivery_attempts=0 AND next_delivery_at IS NOT NULL
       AND reconciliation_required_at IS NULL) THEN
    RAISE EXCEPTION 'New IAM outbox row lacks delivery defaults';
  END IF;
  BEGIN
    UPDATE iam.outbox_events SET delivery_attempts=11
     WHERE event_id='00000000-0000-4000-8000-000000000016';
    RAISE EXCEPTION 'Attempt cap was not enforced';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    UPDATE iam.outbox_events SET reconciliation_required_at=now()
     WHERE event_id='00000000-0000-4000-8000-000000000016';
    RAISE EXCEPTION 'Premature reconciliation was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;
UPDATE iam.outbox_events
   SET delivery_attempts=10, last_delivery_failure_at=now(),
       reconciliation_required_at=now()
 WHERE event_id='00000000-0000-4000-8000-000000000016';
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM iam.outbox_events
              WHERE event_id='00000000-0000-4000-8000-000000000016'
                AND published_at IS NULL AND reconciliation_required_at IS NULL) THEN
    RAISE EXCEPTION 'Exhausted IAM event remained deliverable';
  END IF;
END $$;
ROLLBACK;
