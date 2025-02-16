#!/bin/bash

#---------------------------------------------------Basic Setup Template Start--------------------------------------------#
## Load repo configuration
#if [ ! -f "repo.config" ]; then
#    echo "Error: repo.config file not found!" >&2
#    exit 1
#fi
#source ./repo.config
#
## Validate repo configuration
#if [ -z "$REPO_PATH" ]; then
#    echo "Error: Missing repo configuration in repo.config!" >&2
#    exit 1
#fi
#
## Load branch configuration
#if [ ! -f "branch.config" ]; then
#    echo "Error: branch.config file not found!" >&2
#    exit 1
#fi
#source ./branch.config
#
## Validate branch configuration
#if [ -z "$BASE_BRANCH" ] || [ -z "$FEATURE_BRANCH" ]; then
#    echo "Error: Missing branch configuration in branch.config!" >&2
#    exit 1
#fi
#
## Load database configuration
#if [ ! -f "db.config" ]; then
#    echo "Error: db.config file not found!" >&2
#    exit 1
#fi
#source ./db.config
#
## Validate database configuration
#if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_HOST" ]; then
#    echo "Error: Missing database configuration in db.config!" >&2
#    exit 1
#fi
#
#---------------------------------------------------Basic Setup Template End--------------------------------------------#

#---------------------------------------------------Basic Setup Start---------------------------------------------------#
# Load repo configuration
if [ ! -f "repo.config" ]; then
    echo "Error: repo.config file not found!" >&2
    exit 1
fi
source ./repo.config

# Validate repo configuration
if [ -z "$REPO_PATH" ]; then
    echo "Error: Missing repo configuration in repo.config!" >&2
    exit 1
fi

echo "Repo Configuration:"
echo "Path: $REPO_PATH"
echo

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
echo
#---------------------------------------------------Basic Setup End---------------------------------------------------#

#---------------------------------------------------SQL Setup Start---------------------------------------------------#
# Create the database if it doesn't exist
echo "Creating database $DB_NAME if it doesn't exist..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Switch to the database
echo "Using database $DB_NAME..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;"

# Import SQL files in order
for i in {1..6}; do
    SQL_FILE=$(ls sql/"$i"*.sql 2>/dev/null)  # Find the SQL file starting with $i
    if [ -z "$SQL_FILE" ]; then
        echo "Error: SQL file for step $i not found!" >&2
        exit 1
    fi
    echo "Importing $SQL_FILE..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE"
done
#---------------------------------------------------SQL Setup End------------------------------------------------------#
