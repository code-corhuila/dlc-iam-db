CREATE TABLE iam.users (
  user_id uuid PRIMARY KEY,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  status text NOT NULL CHECK (status IN ('PENDING_VERIFICATION', 'ACTIVE', 'LOCKED', 'DISABLED')),
  email_verified_at timestamptz,
  failed_attempts integer NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0),
  locked_until timestamptz,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  version bigint NOT NULL DEFAULT 0 CHECK (version >= 0),
  CONSTRAINT users_normalized_email CHECK (email = lower(btrim(email))),
  CONSTRAINT users_nonempty_hash CHECK (length(password_hash) > 0),
  CONSTRAINT users_updated_after_created CHECK (updated_at >= created_at)
);

CREATE TABLE iam.user_roles (
  user_id uuid NOT NULL REFERENCES iam.users(user_id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('ADMINISTRATOR', 'DENTIST', 'SECRETARY_ASSISTANT')),
  assigned_by uuid REFERENCES iam.users(user_id),
  assigned_at timestamptz NOT NULL,
  PRIMARY KEY (user_id, role)
);
