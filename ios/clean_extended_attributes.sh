#!/bin/bash

# Script to remove extended attributes from Flutter build artifacts
# This fixes code signing issues caused by resource forks and Finder metadata

set -e

echo "Cleaning extended attributes from Flutter build artifacts..."

# Find and remove extended attributes from App.framework
find "${BUILT_PRODUCTS_DIR}" -name "App.framework" -type d -exec xattr -rc {} \; 2>/dev/null || true
find "${BUILT_PRODUCTS_DIR}" -name "App" -type f -exec xattr -c {} \; 2>/dev/null || true

# Remove extended attributes from all frameworks
find "${BUILT_PRODUCTS_DIR}" -name "*.framework" -type d -exec xattr -rc {} \; 2>/dev/null || true

# Remove extended attributes from all executables
find "${BUILT_PRODUCTS_DIR}" -type f -perm +111 -exec xattr -c {} \; 2>/dev/null || true

echo "Extended attributes cleaned successfully."
