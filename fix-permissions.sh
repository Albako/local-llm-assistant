#!/bin/bash

# Script to fix permissions for all shell scripts in the project

echo "Fixing permissions for shell scripts..."

# Find all .sh files and make them executable
find . -name "*.sh" -type f -exec chmod +x {} \;

echo "Permissions fixed for the following files:"
find . -name "*.sh" -type f -exec ls -la {} \;

echo "Done!"
