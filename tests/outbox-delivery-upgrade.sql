DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM iam.users WHERE email='prior@example.test') THEN
    RAISE EXCEPTION 'Upgrade lost the existing IAM user';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM iam.outbox_events
                  WHERE event_id='00000000-0000-4000-8000-000000000021'
                    AND delivery_attempts=0 AND next_delivery_at=occurred_at
                    AND published_at IS NULL
                    AND reconciliation_required_at IS NULL) THEN
    RAISE EXCEPTION 'Upgrade lost or mis-scheduled pending IAM outbox event';
  END IF;
  IF (SELECT count(*) FROM iam.databasechangelog
       WHERE id='016-iam-outbox-delivery-state') <> 1 THEN
    RAISE EXCEPTION 'Outbox delivery migration did not execute exactly once';
  END IF;
END $$;
