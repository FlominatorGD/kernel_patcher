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

# Function to execute MySQL commands with common options
run_mysql() {
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$@"
}

# Create the database if it doesn't exist
echo "Creating database $DB_NAME if it doesn't exist..."
run_mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Switch to the database
echo "Using database $DB_NAME..."
run_mysql -e "USE $DB_NAME;"

# Import SQL files in order
for i in {1..6}; do
    SQL_FILE=$(ls sql/"$i"*.sql 2>/dev/null)  # Find the SQL file starting with $i
    if [ -z "$SQL_FILE" ]; then
        echo "Error: SQL file for step $i not found!" >&2
        exit 1
    fi
    echo "Importing $SQL_FILE..."
    run_mysql "$DB_NAME" < "$SQL_FILE"
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

index_files() {
    local BRANCH_NAME="$1"
    local SQL_FILE="$ORIGINAL_DIR/files_inserts.sql"

    cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }

    git switch "$BRANCH_NAME" || { echo "Error: Failed to switch to base branch '$BRANCH_NAME'." >&2; exit 1; }

    # Fetch the branch_id for the given branch
    local BRANCH_ID=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "SELECT branch_id FROM branches WHERE branch_name='$BRANCH_NAME';")

    # Get a list of all files in the current branch
    local all_files=$(git ls-files)

    # Always create/empty the SQL file before writing to it
    > "$SQL_FILE"

    # Iterate over all files and create insert statements
    while IFS= read -r filename; do
        
        # Write the insert statement to the SQL file
        echo "INSERT INTO files (filename, branch_id) VALUES ('$filename', $BRANCH_ID);" >> "$SQL_FILE"
    done <<< "$all_files"

    # Import the SQL file into MySQL
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" < "$SQL_FILE"

    echo "Data inserted or updated for branch '$BRANCH_NAME'."

    cd "$ORIGINAL_DIR" || { echo "Error: Failed to navigate to previous directory." >&2; exit 1; }

    rm files_inserts.sql
}

index_files "$BASE_BRANCH"
index_files "$FEATURE_BRANCH"

# Fetch filenames for the base branch
filenames_base=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "
    SELECT f.filename
    FROM files f
    JOIN branches b ON f.branch_id = b.branch_id
    WHERE b.branch_name LIKE '$BASE_BRANCH'
" -s -N)

# Fetch filenames for the feature branch
filenames_feature=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "
    SELECT f.filename
    FROM files f
    JOIN branches b ON f.branch_id = b.branch_id
    WHERE b.branch_name LIKE '$FEATURE_BRANCH'
" -s -N)

# args for dirname can be too long
base_dirs=$(echo "$filenames_base" | xargs -n 250 dirname | sort | uniq)
feature_dirs=$(echo "$filenames_feature" | xargs -n 250 dirname | sort | uniq)

# Find uncommon directories for the base branch (directories in base but not in feature)
uncommon_base_dirs=$(comm -23 <(echo "$base_dirs" | sort) <(echo "$feature_dirs" | sort))

# Find uncommon directories for the feature branch (directories in feature but not in base)
uncommon_feature_dirs=$(comm -13 <(echo "$base_dirs" | sort) <(echo "$feature_dirs" | sort))

filter_top_level_dirs() {
    local dir parent skip
    local -a result=()
    local input="$1"

    # Process the list from the variable (preserving newlines)
    while IFS= read -r dir; do
        skip=0
        # Check if this directory is a subdirectory of any previously kept directory
        for parent in "${result[@]}"; do
            if [[ "${dir}" == "${parent}"/* ]]; then
                skip=1
                break
            fi
        done
        # If not a subdirectory, add to results
        (( skip )) || result+=("$dir")
    done <<< "$input"

    # Print the filtered results
    printf '%s\n' "${result[@]}"
}

need_import_feature=$(filter_top_level_dirs "$uncommon_base_dirs")
#echo "$need_import_feature"
filter_top_level_dirs "$uncommon_feature_dirs"
need_import_base=$(filter_top_level_dirs "$uncommon_fature_dirs")
#echo "$need_import_feature"


fetch_contibutors() {

    cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }
    local branches=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" \
        -B -N -e "SELECT branch_name FROM branches;")

    local SQL_FILE="$ORIGINAL_DIR/files_contibutors.sql"
    touch "$SQL_FILE"
    > "$SQL_FILE"

    for branch_name in $branches; do
        echo "Processing branch: $branch_name"

        # Checkout the branch
        git switch -f "$branch_name"
        if [ $? -ne 0 ]; then
            echo "Failed to checkout branch: $branch_name"
            continue
        fi
        
        git log --pretty=format:"INSERT IGNORE INTO contributors (contributor_name, contributor_email) VALUES (||%an||, ||%ae||);" >> "$SQL_FILE"
        git log --pretty=format:"INSERT IGNORE INTO contributors (contributor_name, contributor_email) VALUES (||%cn||, ||%ce||);" >> "$SQL_FILE"
    done

    sed -i 's/\x27//g' "$SQL_FILE"
    sed -i 's/\\//g' "$SQL_FILE"
    sed -i 's/||/\x27/g' "$SQL_FILE"

    # Import the SQL file into MySQL
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" < "$SQL_FILE"

    echo "Contributors Data inserted."
    cd "$ORIGINAL_DIR" || { echo "Error: Failed to navigate to previous directory." >&2; exit 1; }

    rm "$SQL_FILE"
}

fetch_contibutors


fetch_commits() {
    local BRANCH_NAME="$1"
    local SQL_FILE="$ORIGINAL_DIR/insert_commits.sql"

    cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }

    touch "$SQL_FILE"
    > "$SQL_FILE"

    # Get/Create branch ID
    git switch -f "$BRANCH_NAME"
    local BRANCH_ID=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" \
        -B -N -e "SELECT branch_id FROM branches WHERE branch_name = '$BRANCH_NAME';")

    # Generate SQL with safe delimiters
    git log --pretty=format:"INSERT INTO commits (commit_hash, branch_id, author_name, author_email, author_time, committer_name, committer_email, committer_time, summary) VALUES (|||%H|||, $BRANCH_ID, |||%an|||, |||%ae|||, FROM_UNIXTIME(%at), |||%cn|||, |||%ce|||, FROM_UNIXTIME(%ct), |||%s|||);" > "$SQL_FILE"

    # Convert delimiters to MySQL hex format
    #perl -i -pe 's/\|\|(.*?)\|\|/sprintf("0x%s", unpack("H*", $1))/ge' "$SQL_FILE"
    perl -i -pe 's/\|\|\|(.*?)\|\|\|/sprintf("0x%s", unpack("H*", $1))/ge' "$SQL_FILE"

    # fix any breakage
    perl -i -pe 's/\|//g' "$SQL_FILE"
    perl -i -pe 's/\||//g' "$SQL_FILE"
    perl -i -pe 's/\|||//g' "$SQL_FILE"

    perl -pi -e 's/0x,/NULL,/g' "$SQL_FILE"
    # 0x)
    perl -pi -e 's/0x\)/NULL\)/g' "$SQL_FILE"

    # Import to MySQL
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" < "$SQL_FILE"

    echo "Commit data inserted for branch '$BRANCH_NAME'."

    cd "$ORIGINAL_DIR" || { echo "Error: Failed to navigate to previous directory." >&2; exit 1; }

    rm "$SQL_FILE"
}

fetch_commits "$BASE_BRANCH"
fetch_commits "$FEATURE_BRANCH"

