#!/bin/bash

#---------------------------------------------------Basic Setup Start---------------------------------------------------#
# Load branch configuration
if [ ! -f "branch.config" ]; then
    echo "Error: branch.config file not found!" >&2
    exit 1
fi
source ./branch.config

# Validate branch configuration
if [ -z "$BASE_BRANCH" ] || [ -z "$FEATURE_BRANCH" ]; then
    echo "Error: Missing branch configuration in branch.config!" >&2
    exit 1
fi

echo "Branch Configuration:"
echo "Base:    $BASE_BRANCH"
echo "Feature: $FEATURE_BRANCH"
echo

# Load database configuration
if [ ! -f "db.config" ]; then
    echo "Error: db.config file not found!" >&2
    exit 1
fi
source ./db.config

# Validate database configuration
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_HOST" ]; then
    echo "Error: Missing database configuration in db.config!" >&2
    exit 1
fi

echo "Database Configuration:"
echo "Name: $DB_NAME"
echo "User: $DB_USER"
echo "Pass: ***"  # Never display actual passwords
echo "Host: $DB_HOST"
#---------------------------------------------------Basic Setup End---------------------------------------------------#
