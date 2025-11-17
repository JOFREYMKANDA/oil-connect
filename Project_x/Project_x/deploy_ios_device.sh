#!/bin/bash

# Oil Connect iOS Device Deployment Script
# This script helps deploy the iOS app to a physical device

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "📱 Oil Connect iOS Device Deployment"
echo "===================================="

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "❌ Error: pubspec.yaml not found. Please run this script from the Flutter project root directory."
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "❌ Error: Xcode is not installed or not in PATH"
    print_error "Please install Xcode from the Mac App Store"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

print_status "🔍 Checking connected devices..."

# List connected devices
DEVICES=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | wc -l)
if [ "$DEVICES" -gt 0 ]; then
    print_success "✅ Found $DEVICES iOS simulator(s)"
    print_status "Available simulators:"
    xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -n 3 | sed 's/^/   /'
else
    print_warning "⚠️  No iOS simulators found"
fi

# Check for physical devices
print_status "🔍 Checking for physical devices..."
if command -v idevice_id &> /dev/null; then
    PHYSICAL_DEVICES=$(idevice_id -l 2>/dev/null | wc -l)
    if [ "$PHYSICAL_DEVICES" -gt 0 ]; then
        print_success "✅ Found $PHYSICAL_DEVICES physical device(s)"
        print_status "Connected devices:"
        idevice_id -l | sed 's/^/   /'
    else
        print_warning "⚠️  No physical devices found"
        print_warning "   Make sure your iPhone is connected via USB and trusted"
    fi
else
    print_warning "⚠️  idevice tools not found - cannot detect physical devices"
    print_warning "   Install with: brew install libimobiledevice"
fi

print_status ""
print_status "📋 Deployment Options:"
print_status "======================"
print_status ""
print_status "1. 🚀 Deploy to Physical Device (Recommended)"
print_status "   - Requires Apple Developer account"
print_status "   - Configure signing in Xcode"
print_status "   - Build and install directly"
print_status ""
print_status "2. 📱 Deploy to iOS Simulator"
print_status "   - No signing required"
print_status "   - Good for testing"
print_status "   - Limited functionality"
print_status ""
print_status "3. 📦 Create Signed Build for Distribution"
print_status "   - Requires Apple Developer account"
print_status "   - Create .ipa file"
print_status "   - Can be shared via TestFlight or Ad Hoc"
print_status ""

# Ask user what they want to do
echo -n "What would you like to do? (1/2/3): "
read -r choice

case $choice in
    1)
        print_status "🚀 Deploying to Physical Device..."
        print_status "=================================="
        
        print_warning "⚠️  Important: You need to configure code signing first!"
        print_status ""
        print_status "Steps to configure signing:"
        print_status "1. Open ios/Runner.xcworkspace in Xcode"
        print_status "2. Select the Runner project in the navigator"
        print_status "3. Go to 'Signing & Capabilities' tab"
        print_status "4. Select your development team"
        print_status "5. Ensure 'Automatically manage signing' is checked"
        print_status "6. Select your device as the destination"
        print_status ""
        
        echo -n "Have you configured signing in Xcode? (y/n): "
        read -r signed
        
        if [ "$signed" = "y" ] || [ "$signed" = "Y" ]; then
            print_status "🔨 Building and deploying to device..."
            
            # Clean and get dependencies
            flutter clean
            flutter pub get
            
            # Install pods
            cd ios
            pod install
            cd ..
            
            # Build and run on device
            if flutter run --release --device-id=$(idevice_id -l | head -n 1); then
                print_success "✅ Successfully deployed to device!"
            else
                print_error "❌ Failed to deploy to device"
                print_error "Make sure:"
                print_error "1. Device is connected and trusted"
                print_error "2. Signing is properly configured"
                print_error "3. Device is selected as destination in Xcode"
            fi
        else
            print_warning "⚠️  Please configure signing in Xcode first, then run this script again"
            print_status "Opening Xcode workspace..."
            open ios/Runner.xcworkspace
        fi
        ;;
        
    2)
        print_status "📱 Deploying to iOS Simulator..."
        print_status "================================="
        
        # Clean and get dependencies
        flutter clean
        flutter pub get
        
        # Install pods
        cd ios
        pod install
        cd ..
        
        # List available simulators
        print_status "Available simulators:"
        xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | nl
        
        echo -n "Enter simulator number (or press Enter for first one): "
        read -r sim_choice
        
        if [ -z "$sim_choice" ]; then
            sim_choice=1
        fi
        
        # Get simulator ID
        SIM_ID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | sed -n "${sim_choice}p" | grep -o '([^)]*' | tr -d '(')
        
        if [ -z "$SIM_ID" ]; then
            print_error "❌ Invalid simulator selection"
            exit 1
        fi
        
        print_status "🔨 Building and deploying to simulator..."
        
        if flutter run --release --device-id="$SIM_ID"; then
            print_success "✅ Successfully deployed to simulator!"
        else
            print_error "❌ Failed to deploy to simulator"
        fi
        ;;
        
    3)
        print_status "📦 Creating Signed Build for Distribution..."
        print_status "============================================="
        
        print_warning "⚠️  This requires an Apple Developer account and proper signing setup!"
        print_status ""
        print_status "Steps to create signed build:"
        print_status "1. Open ios/Runner.xcworkspace in Xcode"
        print_status "2. Select 'Any iOS Device (arm64)' as destination"
        print_status "3. Configure signing with your Apple Developer account"
        print_status "4. Go to Product > Archive"
        print_status "5. Follow the archive process"
        print_status "6. Distribute via App Store Connect or Ad Hoc"
        print_status ""
        
        echo -n "Do you want to open Xcode workspace? (y/n): "
        read -r open_xcode
        
        if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
            print_status "Opening Xcode workspace..."
            open ios/Runner.xcworkspace
        fi
        ;;
        
    *)
        print_error "❌ Invalid choice. Please run the script again and select 1, 2, or 3."
        exit 1
        ;;
esac

print_status ""
print_success "🎉 Deployment process completed!"
print_status ""
print_status "Next steps:"
print_status "• Test the app on your device/simulator"
print_status "• Check for any runtime issues"
print_status "• Configure app settings if needed"
print_status "• Consider creating a TestFlight build for wider testing"
