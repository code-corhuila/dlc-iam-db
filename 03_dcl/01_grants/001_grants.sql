GRANT SELECT, INSERT, UPDATE ON
  iam.users, iam.sessions, iam.refresh_token_families,
  iam.refresh_credentials, iam.security_challenges, iam.outbox_events
TO iam_runtime;
GRANT SELECT, INSERT, DELETE ON iam.user_roles TO iam_runtime;
