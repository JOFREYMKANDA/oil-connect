#!/bin/bash

# Oil Connect iOS Build Script (Enhanced Version)
# This script builds a release iOS app with comprehensive error handling and troubleshooting

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    # Check if we're in the correct directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "❌ Error: pubspec.yaml not found. Please run this script from the Flutter project root directory."
        exit 1
    fi
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "❌ Error: Flutter is not installed or not in PATH"
        print_error "Please install Flutter and add it to your PATH"
        print_error "Visit: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # Check Flutter version
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_status "📱 Flutter version: $FLUTTER_VERSION"
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "❌ Error: Xcode is not installed or not in PATH"
        print_error "Please install Xcode from the Mac App Store"
        print_error "Also install Xcode Command Line Tools: xcode-select --install"
        exit 1
    fi
    
    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_status "🍎 Xcode version: $XCODE_VERSION"
    
    # Check if CocoaPods is installed
    if ! command -v pod &> /dev/null; then
        print_error "❌ Error: CocoaPods is not installed"
        print_error "Please install CocoaPods: sudo gem install cocoapods"
        exit 1
    fi
    
    # Check CocoaPods version
    POD_VERSION=$(pod --version)
    print_status "📦 CocoaPods version: $POD_VERSION"
    
    # Check iOS deployment target
    if [ -f "ios/Podfile" ]; then
        IOS_VERSION=$(grep "platform :ios" ios/Podfile | sed "s/platform :ios, '//" | sed "s/'//")
        print_status "📱 iOS deployment target: $IOS_VERSION"
    fi
    
    print_success "✅ Prerequisites check completed"
}

# Function to clean and prepare
clean_and_prepare() {
    print_status "🧹 Cleaning previous builds..."
    flutter clean
    
    print_status "📦 Getting dependencies..."
    if ! flutter pub get; then
        print_error "❌ Error: Failed to get dependencies"
        print_error "Try running: flutter pub cache repair"
        exit 1
    fi
    
    # Check for any analysis issues
    print_status "🔍 Running Flutter analyze..."
    if ! flutter analyze --no-fatal-infos; then
        print_warning "⚠️  Warning: Flutter analyze found issues, but continuing with build..."
    fi
}

# Function to install pods
install_pods() {
    print_status "🍎 Installing iOS pods..."
    cd ios
    
    # Check if Podfile exists
    if [ ! -f "Podfile" ]; then
        print_error "❌ Error: Podfile not found in ios directory"
        exit 1
    fi
    
    # Clean pods if needed
    if [ -d "Pods" ]; then
        print_status "🧹 Cleaning existing pods..."
        pod deintegrate || true
    fi
    
    # Install pods
    print_status "📦 Installing pods..."
    if ! pod install --repo-update; then
        print_error "❌ Error: Pod install failed"
        print_error ""
        print_error "Common solutions:"
        print_error "1. Update CocoaPods: sudo gem update cocoapods"
        print_error "2. Clean and reinstall: pod deintegrate && pod install"
        print_error "3. Check your internet connection"
        print_error "4. Clear CocoaPods cache: pod cache clean --all"
        exit 1
    fi
    
    cd ..
    print_success "✅ Pods installed successfully"
}

# Function to build iOS app
build_ios_app() {
    print_status "🔨 Building iOS app..."
    
    # Check iOS simulator availability
    print_status "📱 Checking iOS simulator availability..."
    if ! xcrun simctl list devices | grep -q "iPhone"; then
        print_warning "⚠️  No iPhone simulators found, but continuing with build..."
    fi
    
    # Build the iOS app
    print_status "🚀 Starting iOS build process..."
    if ! flutter build ios --release --no-codesign; then
        print_error "❌ Error: Flutter iOS build failed"
        print_error ""
        print_error "Common solutions:"
        print_error "1. Check your iOS development setup: flutter doctor"
        print_error "2. Ensure you have a valid Apple Developer account"
        print_error "3. Check your signing configuration in Xcode"
        print_error "4. Verify all dependencies are properly installed"
        print_error "5. Try cleaning: flutter clean && flutter pub get"
        print_error "6. Check iOS deployment target compatibility"
        print_error "7. Ensure Xcode is properly installed and updated"
        exit 1
    fi
    
    print_success "✅ iOS build completed successfully"
}

# Function to handle app output
handle_app_output() {
    # Create ios_releases directory if it doesn't exist
    mkdir -p ios_releases
    
    # Get version info from pubspec.yaml
    VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
    VERSION_NAME=$(echo $VERSION | cut -d'+' -f1)
    BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
    
    # Generate timestamp for unique naming
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Define source and destination paths
    SOURCE_APP="build/ios/iphoneos/Runner.app"
    DEST_APP="ios_releases/oil_connect_v${VERSION_NAME}_build${BUILD_NUMBER}_${TIMESTAMP}.app"
    
    # Check if source app exists
    if [ ! -d "$SOURCE_APP" ]; then
        print_error "❌ Error: iOS app not found at $SOURCE_APP"
        print_error "Build may have failed. Check the output above for errors."
        print_error ""
        print_error "Troubleshooting steps:"
        print_error "1. Check if the build completed successfully"
        print_error "2. Verify your iOS development setup"
        print_error "3. Check signing configuration in Xcode"
        print_error "4. Ensure you have sufficient disk space"
        print_error "5. Check for any Xcode build issues"
        exit 1
    fi
    
    # Copy app to releases folder
    print_status "📋 Copying iOS app to releases folder..."
    cp -R "$SOURCE_APP" "$DEST_APP"
    
    # Verify the copy was successful
    if [ -d "$DEST_APP" ]; then
        print_success "✅ Success! iOS app built and copied to: $DEST_APP"
        print_success "📱 App Details:"
        print_success "   - App Name: Oil Connect"
        print_success "   - Version: $VERSION_NAME"
        print_success "   - Build: $BUILD_NUMBER"
        print_success "   - Size: $(du -sh "$DEST_APP" | cut -f1)"
        print_success "   - Location: $(pwd)/$DEST_APP"
        print_success "   - Bundle ID: com.mkanda.projectx"
        print_success ""
        print_success "🎉 Build completed successfully!"
        print_success ""
        print_success "Next steps:"
        print_success "1. Open ios/Runner.xcworkspace in Xcode"
        print_success "2. Configure signing and provisioning profiles"
        print_success "3. Archive and upload to App Store Connect"
        print_success "4. Test on a physical device"
        print_success "5. Keep the app file for future reference"
        
        # Show app info
        print_status "📊 App Information:"
        if [ -f "$DEST_APP/Info.plist" ]; then
            print_status "   - Display Name: $(plutil -p "$DEST_APP/Info.plist" | grep "CFBundleDisplayName" | cut -d'"' -f4)"
            print_status "   - Bundle Version: $(plutil -p "$DEST_APP/Info.plist" | grep "CFBundleVersion" | cut -d'"' -f4)"
            print_status "   - Short Version: $(plutil -p "$DEST_APP/Info.plist" | grep "CFBundleShortVersionString" | cut -d'"' -f4)"
        fi
    else
        print_error "❌ Error: Failed to copy iOS app to releases folder"
        exit 1
    fi
}

# Main execution
main() {
    print_status "🚀 Building Oil Connect iOS Release..."
    print_status "=========================================="
    
    check_prerequisites
    clean_and_prepare
    install_pods
    build_ios_app
    handle_app_output
    
    print_success "=========================================="
    print_success "🎉 iOS build process completed successfully!"
}

# Run main function
main "$@"
