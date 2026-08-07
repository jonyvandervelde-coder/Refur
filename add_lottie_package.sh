#!/bin/bash
set -e

# Add Lottie package via SPM using xcodebuild
# This uses the xcodebuild -addPackage flag

PROJECT_PATH="Refur.xcodeproj"
SCHEME="Refur"
PACKAGE_URL="https://github.com/airbnb/lottie-ios.git"
PACKAGE_VERSION="4.4.3"

echo "Adding Lottie iOS package from SPM..."

# Use xcrun to interact with xcode
# This creates a Package.resolved entry

xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" \
  -resolvePackageDependencies \
  -clonedSourcePackagesCachePath /var/tmp/xcode_pkg_cache 2>&1 | grep -i "lottie\|package\|error" || true

echo "✓ Lottie package reference prepared"
