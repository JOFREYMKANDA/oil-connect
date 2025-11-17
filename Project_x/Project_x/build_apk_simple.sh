#!/bin/bash

# Oil Connect APK Build Script
# This script builds a release APK and copies it to the apk_releases folder

set -e  # Exit on any error

echo "🚀 Building Oil Connect Release APK..."

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the Flutter project root directory."
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

# Check if key files exist
if [ ! -f "android/key.properties" ]; then
    echo "❌ Error: android/key.properties not found"
    echo "Please ensure your signing configuration is properly set up"
    exit 1
fi

if [ ! -f "android/key.jks" ]; then
    echo "❌ Error: android/key.jks not found"
    echo "Please ensure your keystore file exists"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any analysis issues
echo "🔍 Running Flutter analyze..."
if ! flutter analyze --no-fatal-infos; then
    echo "⚠️  Warning: Flutter analyze found issues, but continuing with build..."
fi

# Build release APK using Gradle directly
echo "🔨 Building release APK using Gradle..."
cd android

# Check if gradlew is executable
if [ ! -x "./gradlew" ]; then
    echo "🔧 Making gradlew executable..."
    chmod +x ./gradlew
fi

# Build the APK
if ! ./gradlew assembleRelease; then
    echo "❌ Error: Gradle build failed"
    echo "Common solutions:"
    echo "1. Check your Android SDK installation"
    echo "2. Verify your signing configuration in android/key.properties"
    echo "3. Ensure all dependencies are properly installed"
    echo "4. Check if you have enough disk space"
    exit 1
fi

cd ..

# Create apk_releases directory if it doesn't exist
mkdir -p apk_releases

# Get version info from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo $VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)

# Generate timestamp for unique naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Define source and destination paths
SOURCE_APK="android/app/build/outputs/apk/release/app-release.apk"
DEST_APK="apk_releases/oil_connect_v${VERSION_NAME}_build${BUILD_NUMBER}_${TIMESTAMP}.apk"

# Check if source APK exists
if [ ! -f "$SOURCE_APK" ]; then
    echo "❌ Error: APK not found at $SOURCE_APK"
    echo "Build may have failed. Check the output above for errors."
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if the build completed successfully"
    echo "2. Verify your signing configuration"
    echo "3. Check Android SDK and build tools installation"
    echo "4. Ensure you have sufficient disk space"
    exit 1
fi

# Copy APK to releases folder
echo "📋 Copying APK to releases folder..."
cp "$SOURCE_APK" "$DEST_APK"

# Verify the copy was successful
if [ -f "$DEST_APK" ]; then
    echo "✅ Success! APK built and copied to: $DEST_APK"
    echo "📱 APK Details:"
    echo "   - App Name: Oil Connect"
    echo "   - Version: $VERSION_NAME"
    echo "   - Build: $BUILD_NUMBER"
    echo "   - Size: $(du -h "$DEST_APK" | cut -f1)"
    echo "   - Location: $(pwd)/$DEST_APK"
    echo "   - Package: com.africom.oil_connect"
    echo ""
    echo "🎉 Build completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Test the APK on a device or emulator"
    echo "2. Upload to Google Play Store or distribute as needed"
    echo "3. Keep the APK file for future reference"
else
    echo "❌ Error: Failed to copy APK to releases folder"
    exit 1
fi
