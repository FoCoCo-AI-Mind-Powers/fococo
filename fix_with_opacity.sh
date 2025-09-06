#!/bin/bash

# Fix all deprecated withOpacity calls to withValues(alpha: x)

echo "Fixing deprecated withOpacity calls..."

# Find all dart files and replace withOpacity with withValues
find lib -name "*.dart" -type f -exec sed -i.bak 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' {} \;

# Remove backup files
find lib -name "*.dart.bak" -type f -delete

echo "Completed fixing withOpacity deprecations"
