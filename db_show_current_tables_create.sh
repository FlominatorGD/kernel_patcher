#!/bin/bash

# Store the current directory
ORIGINAL_DIR=$(pwd)

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

# Output SQL file
OUTPUT_FILE="table_definitions.sql"

# Clear the output file (if it exists) or create a new one
> "$OUTPUT_FILE"

# Get a list of all tables in the database
TABLES=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SHOW TABLES;" -s)

# Check if the database has any tables
if [ -z "$TABLES" ]; then
    echo "No tables found in the database '$DB_NAME'."
    exit 0
fi

# Loop through each table and run SHOW CREATE TABLE
for TABLE in $TABLES; do
    # Get the CREATE TABLE statement and clean up the output
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SHOW CREATE TABLE $TABLE\G" | \
        awk -v table="$TABLE" '
        BEGIN {
            print "-- Table: " table;
            found = 0;
        }
        /^Create Table:/ {
            found = 1;
            sub(/^Create Table: /, "");
            print;
            next;
        }
        found {
            # Remove the "***************************" lines
            if ($0 !~ /^\*/) {
                print;
            }
        }
        ' >> "$OUTPUT_FILE"
    # Ensure the last line is properly terminated with a semicolon
    sed -i '$ s/$/;/' "$OUTPUT_FILE"
    echo -e "\n" >> "$OUTPUT_FILE"
done

echo "Table definitions have been saved to $OUTPUT_FILE."

cat "$OUTPUT_FILE"