CREATE TABLE iam.sessions (
  session_id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES iam.users(user_id),
  device_id text,
  created_at timestamptz NOT NULL,
  last_user_activity_at timestamptz NOT NULL,
  inactivity_expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  revocation_reason text,
  CONSTRAINT session_activity_order CHECK (last_user_activity_at >= created_at),
  CONSTRAINT session_expiry_order CHECK (inactivity_expires_at > last_user_activity_at),
  CONSTRAINT session_revocation_pair CHECK ((revoked_at IS NULL) = (revocation_reason IS NULL))
);
CREATE INDEX sessions_by_user ON iam.sessions (user_id, created_at DESC);

CREATE TABLE iam.refresh_token_families (
  family_id uuid PRIMARY KEY,
  session_id uuid NOT NULL UNIQUE REFERENCES iam.sessions(session_id),
  created_at timestamptz NOT NULL,
  revoked_at timestamptz,
  reuse_detected_at timestamptz
);

CREATE TABLE iam.refresh_credentials (
  credential_id uuid PRIMARY KEY,
  family_id uuid NOT NULL REFERENCES iam.refresh_token_families(family_id),
  token_hash text NOT NULL UNIQUE CHECK (length(token_hash) > 0),
  predecessor_id uuid UNIQUE,
  issued_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  revoked_at timestamptz,
  UNIQUE (family_id, credential_id),
  FOREIGN KEY (family_id, predecessor_id)
    REFERENCES iam.refresh_credentials(family_id, credential_id),
  CONSTRAINT refresh_expiry_order CHECK (expires_at > issued_at),
  CONSTRAINT refresh_not_own_predecessor CHECK (predecessor_id IS DISTINCT FROM credential_id)
);
CREATE INDEX refresh_credentials_by_family ON iam.refresh_credentials (family_id, issued_at DESC);

CREATE TABLE iam.security_challenges (
  challenge_id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES iam.users(user_id),
  session_id uuid REFERENCES iam.sessions(session_id),
  purpose text NOT NULL CHECK (length(btrim(purpose)) > 0),
  token_hash text NOT NULL UNIQUE CHECK (length(token_hash) > 0),
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  CONSTRAINT challenge_expiry_order CHECK (expires_at > created_at)
);
CREATE INDEX security_challenges_pending ON iam.security_challenges (user_id, purpose, expires_at)
  WHERE consumed_at IS NULL;

CREATE TABLE iam.outbox_events (
  event_id uuid PRIMARY KEY,
  event_type text NOT NULL CHECK (length(btrim(event_type)) > 0),
  aggregate_id uuid NOT NULL,
  correlation_id uuid NOT NULL,
  causation_id uuid NOT NULL,
  payload jsonb NOT NULL,
  occurred_at timestamptz NOT NULL,
  published_at timestamptz
);
CREATE INDEX outbox_events_pending ON iam.outbox_events (occurred_at)
  WHERE published_at IS NULL;
