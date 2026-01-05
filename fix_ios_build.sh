#!/bin/bash

# Comprehensive fix for iOS code signing issues with extended attributes
# Run this script before building your iOS app

set -e

echo "🔧 Fixing iOS build issues..."

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="${PROJECT_DIR}/ios"

# Clean Flutter build artifacts
echo "📦 Cleaning Flutter build..."
cd "${PROJECT_DIR}"
flutter clean

# Clean Xcode derived data
echo "🗑️  Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true

# Remove extended attributes from iOS directory
echo "🧹 Removing extended attributes..."
find "${IOS_DIR}" -type f -exec xattr -c {} \; 2>/dev/null || true
find "${IOS_DIR}" -type d -exec xattr -rc {} \; 2>/dev/null || true

# Clean CocoaPods
echo "🍫 Cleaning CocoaPods..."
cd "${IOS_DIR}"
rm -rf Pods Podfile.lock .symlinks 2>/dev/null || true

# Reinstall pods
echo "📥 Reinstalling CocoaPods..."
pod install --repo-update

# Remove extended attributes from installed pods
echo "🧹 Cleaning extended attributes from Pods..."
find "${IOS_DIR}/Pods" -type f -exec xattr -c {} \; 2>/dev/null || true
find "${IOS_DIR}/Pods" -type d -exec xattr -rc {} \; 2>/dev/null || true

echo "✅ Build fix completed! You can now build your iOS app."
echo ""
echo "To build, run:"
echo "  flutter build ios --release"
echo "  or"
echo "  flutter build ipa"
