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

# Import SQL file

SQL_FILE="sql/kernel.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "Error: SQL file $SQL_FILE not found!" >&2
    exit 1
fi

echo "Importing $SQL_FILE..."
run_mysql "$DB_NAME" < "$SQL_FILE"

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

fetch_porcelain() {
    local BRANCH_NAME_A="$1"
    local file="$2"
    local count_file_nr="$3"
    local db_host="$4"
    local db_user="$5"
    local db_pass="$6"
    local db_name="$7"
    local original_dir="$8"
    local COMBINED_SQL_FILE="$original_dir/$count_file_nr-combined.sql"

    # Helper function with NULL handling
    to_hex() {
        local input="$1"
        if [ -z "$input" ]; then
            echo "NULL"
        else
            printf "0x%s" "$(printf "%s" "$input" | xxd -p -c 0 | tr -d '\n')"
        fi
    }

    # SQL escaping function
    #escape_sql() {
    #    echo "$1" | sed "s/'/''/g"
    #}

    echo "Processing $file (count: $count_file_nr)"
    echo "$BRANCH_NAME_A"

    # Get branch_id
    local branch_id=$(mysql -h "$db_host" -u "$db_user" -p"$db_pass" -D "$db_name" \
        -B -N -e "SELECT branch_id FROM branches WHERE branch_name = '$BRANCH_NAME_A';")

    # Initialize SQL file with transaction
    echo "START TRANSACTION;" > "$COMBINED_SQL_FILE"

    git blame --line-porcelain "$file" | {
        local current_sha="" current_author_name="" current_author_email="" current_author_time=""
        local current_committer_name="" current_committer_email="" current_committer_time=""
        local current_summary="" current_filename="" current_code=""
        local line_nr=0

        while IFS= read -r line; do
            if [[ $line =~ ^([0-9a-f]{40}) ]]; then
                current_sha="${BASH_REMATCH[1]}"
            elif [[ $line == "author "* ]]; then
                current_author_name="${line#author }"
            elif [[ $line == "author-mail "* ]]; then
                current_author_email="${line#author-mail <}"
                current_author_email="${current_author_email%>}"
            elif [[ $line == "author-time "* ]]; then
                current_author_time="${line#author-time }"
            elif [[ $line == "committer "* ]]; then
                current_committer_name="${line#committer }"
            elif [[ $line == "committer-mail "* ]]; then
                current_committer_email="${line#committer-mail <}"
                current_committer_email="${current_committer_email%>}"
            elif [[ $line == "committer-time "* ]]; then
                current_committer_time="${line#committer-time }"
            elif [[ $line == "summary "* ]]; then
                current_summary="${line#summary }"
            elif [[ $line == "filename "* ]]; then
                current_filename="${line#filename }"
            elif [[ $line == $'\t'* ]]; then
                current_code="${line#   }"
                ((line_nr++))
                
                # Escape filename and handle NULL values
                local escaped_filename=$($current_filename)
                local author_name_hex=$(to_hex "$current_author_name")
                local author_email_hex=$(to_hex "$current_author_email")
                local committer_name_hex=$(to_hex "$current_committer_name")
                local committer_email_hex=$(to_hex "$current_committer_email")
                local summary_hex=$(to_hex "$current_summary")
                local code_hex=$(to_hex "$current_code")

                # Generate SQL directly to combined file
                cat <<SQL >> "$COMBINED_SQL_FILE"
                -- User inserts
                INSERT INTO users (name, email) VALUES ($author_name_hex, $author_email_hex)
                ON DUPLICATE KEY UPDATE name = name, email = email;
                
                INSERT INTO users (name, email) VALUES ($committer_name_hex, $committer_email_hex)
                ON DUPLICATE KEY UPDATE name = name, email = email;
                
                -- File insert
                INSERT INTO files (filename) VALUES ('$escaped_filename')
                ON DUPLICATE KEY UPDATE filename = filename;
                
                -- Commit insert
                INSERT INTO commits (commit_hash, author_id, committer_id, author_time, committer_time, summary)
                VALUES (
                    '$current_sha',
                    (SELECT user_id FROM users WHERE name = $author_name_hex AND email = $author_email_hex),
                    (SELECT user_id FROM users WHERE name = $committer_name_hex AND email = $committer_email_hex),
                    FROM_UNIXTIME($current_author_time),
                    FROM_UNIXTIME($current_committer_time),
                    $summary_hex
                ) ON DUPLICATE KEY UPDATE commit_hash = commit_hash;
                
                -- Commit line
                INSERT INTO commit_lines (commit_hash, file_id, line_nr, code)
                VALUES (
                    '$current_sha',
                    (SELECT file_id FROM files WHERE filename = '$escaped_filename'),
                    $line_nr,
                    $code_hex
                ) ON DUPLICATE KEY UPDATE commit_hash = commit_hash, file_id = file_id, line_nr = line_nr;
                
                -- Blame line
                INSERT INTO blame_lines (branch_id, file_id, line_nr, commit_hash, commit_line_nr)
                VALUES (
                    $branch_id,
                    (SELECT file_id FROM files WHERE filename = '$escaped_filename'),
                    $line_nr,
                    '$current_sha',
                    $line_nr
                ) ON DUPLICATE KEY UPDATE branch_id = branch_id, file_id = file_id, line_nr = line_nr;
SQL

                # Reset for next iteration
                current_sha=""
                current_author_name=""
                current_author_email=""
                current_author_time=""
                current_committer_name=""
                current_committer_email=""
                current_committer_time=""
                current_summary=""
                current_filename=""
                current_code=""
            fi
        done

        echo "COMMIT;" >> "$COMBINED_SQL_FILE"
    }

    # Execute combined SQL
    # mysql -h "$db_host" -u "$db_user" -p"$db_pass" -D "$db_name" < "$COMBINED_SQL_FILE"
}

# Navigate to repository
cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }

# Fetch commit history and switch to branch
git switch -f "$BASE_BRANCH" || { echo "Error: Failed to switch to branch '$BASE_BRANCH'." >&2; exit 1; }
all_files=$(git ls-files)

# Compare file differences between two branches and categorize them
# Usage: compare_branch_files <base_branch> <feature_branch>
# Sets five global variables:
#   files_in_both - Modified files existing in both branches
#   files_in_base_only - Files deleted in feature branch (exist only in base)
#   files_in_feature_only - Added files only in feature branch
#   files_in_both_and_base_only - Modified files + files only in base
#   files_in_both_and_feature_only - Modified files + files only in feature
compare_branch_files() {
    local BASE_BRANCH=$1
    local FEATURE_BRANCH=$2
    
    # Get all changed files between branches
    local all_changed_files=$(git diff --name-only "$BASE_BRANCH" "$FEATURE_BRANCH")

    # Declare associative arrays to track file presence
    local -A base_files feature_files

    # Populate base branch files
    while IFS= read -r file; do
        base_files["$file"]=1
    done < <(git ls-tree -r --name-only "$BASE_BRANCH")

    # Populate feature branch files
    while IFS= read -r file; do
        feature_files["$file"]=1
    done < <(git ls-tree -r --name-only "$FEATURE_BRANCH")

    # Initialize result arrays
    local files_in_both=()
    local files_in_base_only=()
    local files_in_feature_only=()

    # Categorize each changed file
    while IFS= read -r file; do
        local in_base=${base_files["$file"]:-0}
        local in_feature=${feature_files["$file"]:-0}

        if (( in_base && in_feature )); then
            files_in_both+=("$file")     # Modified in feature branch
        elif (( in_base )); then
            files_in_base_only+=("$file") # Deleted in feature branch
        else
            files_in_feature_only+=("$file") # Added in feature branch
        fi
    done <<< "$all_changed_files"

    # Convert arrays to newline-delimited strings and set global variables
    declare -g files_in_both=$(printf "%s\n" "${files_in_both[@]}")
    declare -g files_in_base_only=$(printf "%s\n" "${files_in_base_only[@]}")
    declare -g files_in_feature_only=$(printf "%s\n" "${files_in_feature_only[@]}")

    # Create combined variables
    declare -g files_in_both_and_base_only=$(printf "%s\n" "${files_in_both[@]}" "${files_in_base_only[@]}")
    declare -g files_in_both_and_feature_only=$(printf "%s\n" "${files_in_both[@]}" "${files_in_feature_only[@]}")
}


# Example usage:
compare_branch_files "$BASE_BRANCH" "$FEATURE_BRANCH"
echo "Modified files: $files_in_both"
echo "Base-only files: $files_in_base_only"
echo "Feature-only files: $files_in_feature_only"
echo "Modified + Base-only files: $files_in_both_and_base_only"
echo "Modified + Feature-only files: $files_in_both_and_feature_only"


NUM_THREADS=128
count_file_nr=0

#mkdir -p  "$ORIGINAL_DIR/out_base"
#echo "0" > "$ORIGINAL_DIR/out_base/counter.txt"
#touch "$ORIGINAL_DIR/out_base/counter.lock"

increment_counter() {
    local original_dir="$1"
    (
      flock 200  # Lock the file descriptor tied to counter.lock
      read -r count < "$original_dir/counter.txt"
      ((count++))
      echo "$count" > "$original_dir/counter.txt"
      echo "$count"  # Return the new value
    ) 200>"counter.lock"  # Associate FD 200 with the lock file
}

export -f fetch_porcelain increment_counter fetch_unactive_commits
export DB_HOST DB_USER DB_PASS DB_NAME ORIGINAL_DIR BASE_BRANCH FEATURE_BRANCH


#Use xargs to run fetch_porcelain in parallel
#printf "%s\n" "${files_in_both[@]}" | awk '!seen[$0]++' | xargs -n 1 -P $NUM_THREADS -I {} bash -c '
#    filename={}
#    count_file_nr=$(increment_counter "$ORIGINAL_DIR/out_base")
#    echo "Processing $filename (count: $count_file_nr)"
#    fetch_porcelain "$BASE_BRANCH" "$filename" "$count_file_nr" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME" "$ORIGINAL_DIR/out_base"
#'


#mkdir -p  "$ORIGINAL_DIR/out_feature_b"
#echo "0" > "$ORIGINAL_DIR/out_feature_b/counter.txt"
#touch "$ORIGINAL_DIR/out_feature_b/counter.lock"
#
#printf "%s\n" "${files_in_both[@]}" | awk '!seen[$0]++' | xargs -n 1 -P $NUM_THREADS -I {} bash -c '
#     filename={}
#     count_file_nr=$(increment_counter "$ORIGINAL_DIR/out_feature_b")
#     echo "Processing $filename (count: $count_file_nr)"
#     fetch_unactive_commits "$BASE_BRANCH" "$filename" "$count_file_nr" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME" "$ORIGINAL_DIR/out_feature_b"
#'

for file in $(ls "$ORIGINAL_DIR/out_feature_b"/*-combined.sql | sort -n); do mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file"; done

# Fetch commit history and switch to branch
git switch -f "$FEATURE_BRANCH" || { echo "Error: Failed to switch to branch '$BASE_BRANCH'." >&2; exit 1; }

#mkdir -p  "$ORIGINAL_DIR/out_feature"
#echo "0" > "$ORIGINAL_DIR/out_feature/counter.txt"
#touch "$ORIGINAL_DIR/out_feature/counter.lock"

#printf "%s\n" "${files_in_both[@]}" | awk '!seen[$0]++' | xargs -n 1 -P $NUM_THREADS -I {} bash -c '
#    filename={}
#    count_file_nr=$(increment_counter "$ORIGINAL_DIR/out_feature")
#    echo "Processing $filename (count: $count_file_nr)"
#    fetch_porcelain "$FEATURE_BRANCH" "$filename" "$count_file_nr" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME" "$ORIGINAL_DIR/out_feature"
#'
#
#for file in $(ls "$ORIGINAL_DIR/out_feature"/*-combined.sql | sort -n); do mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file"; done

#mkdir -p  "$ORIGINAL_DIR/out_feature_c"
#echo "0" > "$ORIGINAL_DIR/out_feature_c/counter.txt"
#touch "$ORIGINAL_DIR/out_feature_c/counter.lock"
#
#printf "%s\n" "${files_in_both[@]}" | awk '!seen[$0]++' | xargs -n 1 -P $NUM_THREADS -I {} bash -c '
#     filename={}
#     count_file_nr=$(increment_counter "$ORIGINAL_DIR/out_feature_c")
#     echo "Processing $filename (count: $count_file_nr)"
#     fetch_unactive_commits "$FEATURE_BRANCH" "$filename" "$count_file_nr" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME" "$ORIGINAL_DIR/out_feature_c"
#'

for file in $(ls "$ORIGINAL_DIR/out_feature_c"/*-combined.sql | sort -n); do mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file"; done

# Navigate to repository
cd "$REPO_PATH" || { echo "Error: Failed to navigate to repository directory." >&2; exit 1; }
