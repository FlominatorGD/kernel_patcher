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
#---------------------------------------------------SQL Setup End-------------------------------------------------------#

#---------------------------------------------------Repo Setup Start----------------------------------------------------#
# Check if the repo directory exists and is not empty
if [ ! -d "$REPO_PATH" ] || [ -z "$(ls -A $REPO_PATH)" ]; then
    echo "The repository directory is either missing or empty."
    read -p "Would you like to clone the repository? (yes/no): " CLONE_CHOICE

    if [ "$CLONE_CHOICE" = "yes" ]; then
        read -p "Enter the Git repository URL to clone: " REPO_URL
        git clone "$REPO_URL" "$REPO_PATH"
        if [ $? -eq 0 ]; then
            echo "Repository cloned successfully."
        else
            echo "Error: Failed to clone the repository." >&2
            exit 1
        fi
    else
        echo "Repository setup aborted." >&2
        exit 1
    fi
else
    echo "Repository directory is valid and not empty."
fi

# Navigate to the repository directory
cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }

# Fetch all branches from the remote
echo "Fetching all branches from the remote..."
git fetch --all || { echo "Error: Failed to fetch branches from the remote." >&2; exit 1; }

# Verify that the base branch is fetchable and can be switched to
if ! git show-ref --quiet refs/remotes/origin/"$BASE_BRANCH"; then
    echo "Error: Base branch '$BASE_BRANCH' does not exist on the remote." >&2
    exit 1
fi

echo "Switching to base branch '$BASE_BRANCH'..."
git switch "$BASE_BRANCH" || { echo "Error: Failed to switch to base branch '$BASE_BRANCH'." >&2; exit 1; }
echo "Successfully switched to base branch '$BASE_BRANCH'."

# Verify that the feature branch is fetchable and can be switched to
if ! git show-ref --quiet refs/remotes/origin/"$FEATURE_BRANCH"; then
    echo "Feature branch '$FEATURE_BRANCH' does not exist on the remote."
    read -p "Would you like to create it from '$BASE_BRANCH'? (yes/no): " CREATE_FEATURE_CHOICE

    if [ "$CREATE_FEATURE_CHOICE" = "yes" ]; then
        git switch -b "$FEATURE_BRANCH" || { echo "Error: Failed to create feature branch '$FEATURE_BRANCH'." >&2; exit 1; }
        echo "Feature branch '$FEATURE_BRANCH' created successfully."
    else
        echo "Feature branch setup aborted." >&2
        exit 1
    fi
else
    echo "Switching to feature branch '$FEATURE_BRANCH'..."
    git switch "$FEATURE_BRANCH" || { echo "Error: Failed to switch to feature branch '$FEATURE_BRANCH'." >&2; exit 1; }
    echo "Successfully switched to feature branch '$FEATURE_BRANCH'."
fi

git switch "$BASE_BRANCH" || { echo "Error: Failed to switch to base branch '$BASE_BRANCH'." >&2; exit 1; }
cd "$ORIGINAL_DIR" || { echo "Error: Failed to navigate to previous directory." >&2; exit 1; }
#---------------------------------------------------Repo Setup End------------------------------------------------------#


#---------------------------------------------------main----------------------------------------------------------------#
echo "INSERT INTO branches (branch_name) VALUES ('$BASE_BRANCH');\
      INSERT INTO branches (branch_name) VALUES ('$FEATURE_BRANCH');" | \
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
