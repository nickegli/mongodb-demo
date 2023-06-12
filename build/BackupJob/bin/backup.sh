#!/usr/bin/env bash
set -euo pipefail

DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_AUTHENTICATION_DB="${DB_AUTHENTICATION_DB:-admin}"
DB_CONNECTIONSTRING="${DB_CONNECTIONSTRING}"
OUTPUT_BASE_PATH="${OUTPUT_BASE_PATH}"
RETENTION_SPAN="${RETENTION_SPAN}"
EXCLUDE_COLLECTIONS_WITH_PREFIX="${EXCLUDE_COLLECTIONS_WITH_PREFIX:-}"
DB_NAME="${DB_NAME:-}"

echo "Starting backup task..."
if [ ! -d "${OUTPUT_BASE_PATH}" ] ; then
    echo "Backup path [${OUTPUT_BASE_PATH}] doesn't exist. Trying to create..."
    mkdir -p ${OUTPUT_BASE_PATH}
fi

if [ -z "${EXCLUDE_COLLECTIONS_WITH_PREFIX}"] ; then
    echo "Run backup job: mongodump --host=${DB_CONNECTIONSTRING} --username=${DB_USER} --password=*** --authenticationDatabase=${DB_AUTHENTICATION_DB} --gzip --archive=${OUTPUT_BASE_PATH}/backup-date+%F-%T.gz"
    mongodump --host=${DB_CONNECTIONSTRING} --username=${DB_USER} --password=${DB_PASSWORD} --authenticationDatabase=${DB_AUTHENTICATION_DB} --gzip --archive="${OUTPUT_BASE_PATH}/backup-`date +"%F-%T"`.gz"
else
    if [ -z "${DB_NAME}"] ; then
        echo "If EXCLUDE_COLLECTIONS_WITH_PREFIX is specified, DB_NAME must not be empty"
        exit 1
    fi
    echo "Run backup job: mongodump --host=${DB_CONNECTIONSTRING} --username=${DB_USER} --password=*** --authenticationDatabase=${DB_AUTHENTICATION_DB} --excludeCollectionsWithPrefix=${EXCLUDE_COLLECTIONS_WITH_PREFIX} --db=${DB_NAME} --gzip --archive=${OUTPUT_BASE_PATH}/backup-date+%F-%T.gz"
    mongodump --host=${DB_CONNECTIONSTRING} --username=${DB_USER} --password=${DB_PASSWORD} --authenticationDatabase=${DB_AUTHENTICATION_DB} --excludeCollectionsWithPrefix=${EXCLUDE_COLLECTIONS_WITH_PREFIX} --db=${DB_NAME} --gzip --archive="${OUTPUT_BASE_PATH}/backup-`date +"%F-%T"`.gz"
fi

# removes any backups older then the set limit in $RETENTION_SPAN 
echo "Run cleanup task: find ${OUTPUT_BASE_PATH}/ -maxdepth 1 -type f -mtime +${RETENTION_SPAN} -name backup* -exec rm {} \;"
find ${OUTPUT_BASE_PATH}/ -maxdepth 1 -type f -mtime "+${RETENTION_SPAN}" -name "backup*" -exec rm {} \;

echo "Finished backup task"