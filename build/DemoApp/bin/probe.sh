#!/bin/bash

DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_NAME="${DB_NAME}"
DB_CONNECTIONSTRING="${DB_CONNECTIONSTRING}"
DB_AUTHENTICATION_DB="${DB_AUTHENTICATION_DB:-admin}"

# Add the absolute path to the 'mongosh' binary
MONGOSH_PATH="/usr/bin/mongosh"

# Connect to MongoDB
$MONGOSH_PATH --host=${DB_CONNECTIONSTRING} --username "${DB_USER}" --password "${DB_PASSWORD}" --eval "db.getSiblingDB('${DB_NAME}')"

while true; do
  # Write to MongoDB every 5 seconds
  echo "Writing to MongoDB"
  $MONGOSH_PATH --host=${DB_CONNECTIONSTRING} --username "${DB_USER}" --password "${DB_PASSWORD}" --eval "db.getSiblingDB('${DB_NAME}').test.insertOne({ message: 'Hello MongoDB' })" | grep -E 'acknowledged|insertedId'

  sleep 2
done


