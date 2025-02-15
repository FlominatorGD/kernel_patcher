#!/bin/bash

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
BASE_BRANCH=$base_branch
FEATURE_BRANCH=$feature_branch
EOL

echo "Configuration saved to branch.config:"
cat branch.config
