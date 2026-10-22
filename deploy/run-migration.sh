#!/bin/sh
set -eu

if [ -f /run/secrets/iam_migrator_password ]; then
  LIQUIBASE_COMMAND_PASSWORD=$(cat /run/secrets/iam_migrator_password)
  export LIQUIBASE_COMMAND_PASSWORD
fi

exec liquibase \
  --search-path=/workspace \
  --changelog-file=changelog/changelog-master.yaml \
  --url="jdbc:postgresql://${DLC_POSTGRES_HOST:-dlc-postgres}:5432/${DLC_POSTGRES_DB:-di_lucca}" \
  --username=iam_migrator \
  --default-schema-name=iam \
  --liquibase-schema-name=iam \
  "$@"
