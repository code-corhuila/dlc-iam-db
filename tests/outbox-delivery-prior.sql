INSERT INTO iam.users
  (user_id,email,password_hash,status,created_at,updated_at)
VALUES ('00000000-0000-4000-8000-000000000020','prior@example.test',
        'test-hash','PENDING_VERIFICATION',now(),now());
INSERT INTO iam.outbox_events
  (event_id,event_type,aggregate_id,correlation_id,causation_id,payload,occurred_at)
VALUES ('00000000-0000-4000-8000-000000000021','UserRegistered',
        '00000000-0000-4000-8000-000000000020',
        '00000000-0000-4000-8000-000000000022',
        '00000000-0000-4000-8000-000000000022',
        '{"userId":"00000000-0000-4000-8000-000000000020"}',now());
