\set ON_ERROR_STOP on
BEGIN;
INSERT INTO iam.users (user_id, email, password_hash, status, email_verified_at, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000002', 'admin@example.test', 'synthetic-hash', 'ACTIVE', now(), now(), now()),
       ('00000000-0000-0000-0000-000000000003', 'dentist@example.test', 'synthetic-hash', 'ACTIVE', now(), now(), now());
INSERT INTO iam.user_roles (user_id, role, assigned_by, assigned_at)
VALUES ('00000000-0000-0000-0000-000000000003', 'DENTIST', '00000000-0000-0000-0000-000000000002', now());
INSERT INTO iam.role_assignment_audit (audit_id, user_id, role, action, actor_user_id, occurred_at, correlation_id)
VALUES ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003',
        'DENTIST', 'ASSIGNED', '00000000-0000-0000-0000-000000000002', now(),
        '00000000-0000-0000-0000-000000000005');
DO $$
BEGIN
  BEGIN
    INSERT INTO iam.user_roles (user_id, role, assigned_at)
    VALUES ('00000000-0000-0000-0000-000000000003', 'DENTIST', now());
    RAISE EXCEPTION 'Duplicate role assignment was accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO iam.role_assignment_audit (audit_id, user_id, role, action, actor_user_id, occurred_at, correlation_id)
    VALUES ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003',
            'PATIENT', 'ASSIGNED', '00000000-0000-0000-0000-000000000002', now(),
            '00000000-0000-0000-0000-000000000005');
    RAISE EXCEPTION 'Unapproved audit role was accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF has_table_privilege('iam_runtime', 'iam.role_assignment_audit', 'UPDATE')
     OR has_table_privilege('iam_runtime', 'iam.role_assignment_audit', 'DELETE')
     OR NOT has_table_privilege('iam_runtime', 'iam.role_assignment_audit', 'INSERT') THEN
    RAISE EXCEPTION 'IAM audit privileges are incorrect';
  END IF;
END $$;
DELETE FROM iam.user_roles WHERE user_id = '00000000-0000-0000-0000-000000000003';
INSERT INTO iam.role_assignment_audit (audit_id, user_id, role, action, actor_user_id, occurred_at, correlation_id)
VALUES ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000003',
        'DENTIST', 'REVOKED', '00000000-0000-0000-0000-000000000002', now(),
        '00000000-0000-0000-0000-000000000005');
DO $$
BEGIN
  IF (SELECT count(*) FROM iam.users WHERE email = 'prior@example.test') <> 1 THEN
    RAISE EXCEPTION 'Previous-version user was lost';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM iam.databasechangelog
                 WHERE id = '003-iam-role-assignment-audit') THEN
    RAISE EXCEPTION 'Role-assignment audit changeset was not applied';
  END IF;
  IF (SELECT count(*) FROM iam.role_assignment_audit WHERE user_id = '00000000-0000-0000-0000-000000000003') <> 2 THEN
    RAISE EXCEPTION 'Assignment history was lost after revocation';
  END IF;
END $$;
ROLLBACK;
