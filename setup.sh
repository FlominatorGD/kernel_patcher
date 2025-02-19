#!/bin/bash

# Check for git
echo -n "Checking for git... "
if dpkg -s git &> /dev/null; then
    echo "Installed"
else
    echo "Not installed"
    echo "  Recommendation: Install git with: sudo apt install git"
    echo "  Note: You'll need to configure git during installation"
fi

# Check for MariaDB
echo -n "Checking for MariaDB... "
if dpkg -s mariadb-server &> /dev/null; then
    echo "Installed"
else
    echo "Not installed"
    echo "  Recommendation: Install MariaDB with: sudo apt install mariadb-server"
fi

# Check for phpMyAdmin
echo -n "Checking for phpMyAdmin... "
if dpkg -s phpmyadmin &> /dev/null; then
    echo "Installed"
else
    echo "Not installed"
    echo "  Recommendation: Install phpMyAdmin with: sudo apt install phpmyadmin"
    echo "  Note: You'll need to configure web server (Apache2/Nginx) and database during installation"
fi

# Set default path for kernel
default_path="../kernel"

# Check for command-line argument
if [ -n "$1" ]; then
  repo_path="$1"
else
  # Prompt user (with default shown)
  read -p "Enter repository path of your kernel [default: $default_path]: " input
  repo_path="${input:-$default_path}"
fi

# Write to repo.config (quotes handle spaces)
echo "REPO_PATH=\"$repo_path\"" > repo.config

echo "Creating branch configuration..."
echo "Please enter the following branch details:"

# Prompt for base branch
read -p "Base branch (e.g. main/master): " base_branch
while [[ -z "$base_branch" ]]; do
    echo "Error: Base branch cannot be empty!"
    read -p "Base branch (e.g. main/master): " base_branch
done

# Prompt for feature branch
read -p "Feature branch name: " feature_branch
while [[ -z "$feature_branch" ]]; do
    echo "Error: Feature branch cannot be empty!"
    read -p "Feature branch name: " feature_branch
done

# Create configuration file
cat > branch.config <<EOL
BASE_BRANCH="$base_branch"
FEATURE_BRANCH="$feature_branch"
EOL

echo "Configuration saved to branch.config:"
cat branch.config


# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    read -p "${prompt} [${default}]: " input
    echo "${input:-$default}"
}

# Set Database Name (default: kernel)
DB_NAME=${DB_NAME:-"kernel"}
DB_NAME=$(prompt_with_default "Enter database name" "$DB_NAME")

# Set Database User (default: root)
DB_USER=${DB_USER:-"root"}
DB_USER=$(prompt_with_default "Enter database user" "$DB_USER")

# Set Database Password securely
if [ -z "$DB_PASS" ]; then
    read -s -p "Enter database password: " DB_PASS
    echo
fi

# Set Database Host (default: localhost)
DB_HOST=${DB_HOST:-"localhost"}
DB_HOST=$(prompt_with_default "Enter database host" "$DB_HOST")

# Generate db.config file
cat > db.config <<EOF
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_HOST="$DB_HOST"
EOF

echo "Database configuration saved to db.config"
