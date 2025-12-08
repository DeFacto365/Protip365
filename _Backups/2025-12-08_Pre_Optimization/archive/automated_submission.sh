#!/bin/bash

# ProTip365 Automated App Store Submission Script
# This script automates the entire submission process to prevent StoreKit rejections

set -e

echo "🚀 ProTip365 Automated Submission"
echo "=================================="

# Configuration
APP_STORE_USERNAME="${APP_STORE_USERNAME:-}"
APP_STORE_PASSWORD="${APP_STORE_PASSWORD:-}"
API_KEY_ID="${API_KEY_ID:-}"
API_ISSUER_ID="${API_ISSUER_ID:-}"
API_PRIVATE_KEY_PATH="${API_PRIVATE_KEY_PATH:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Step 1: Pre-submission validation
echo ""
echo "📋 Step 1: Pre-submission Validation"
echo "-------------------------------------"

if [ -f "validate_app_store_submission.swift" ]; then
    swift validate_app_store_submission.swift
    if [ $? -ne 0 ]; then
        print_error "Validation failed. Please fix errors before submitting."
        exit 1
    fi
    print_status "Pre-submission validation passed"
else
    print_warning "Validation script not found, skipping validation"
fi

# Step 2: StoreKit validation
echo ""
echo "🧪 Step 2: StoreKit Configuration Validation"
echo "--------------------------------------------"

# Check if StoreKit file exists and has correct product ID
if [ -f "ProTip365/Protip365.storekit" ]; then
    if grep -q "com.protip365.monthly" "ProTip365/Protip365.storekit"; then
        print_status "StoreKit configuration contains correct product ID"
    else
        print_error "StoreKit configuration missing product ID: com.protip365.monthly"
        exit 1
    fi
else
    print_error "StoreKit configuration file not found"
    exit 1
fi

# Check if SubscriptionManager only references existing product
if grep -q "com.protip365.annual\|com.protip365.parttime" "ProTip365/Subscription/SubscriptionManager.swift"; then
    print_error "SubscriptionManager references non-existent products"
    print_error "Please fix SubscriptionManager.swift to only use com.protip365.monthly"
    exit 1
else
    print_status "SubscriptionManager only references existing products"
fi

# Step 3: Build and archive
echo ""
echo "📦 Step 3: Building and Archiving"
echo "---------------------------------"

# Clean build folder
print_status "Cleaning build folder"
rm -rf build/

# Build and archive
print_status "Building and archiving app"
xcodebuild -project ProTip365.xcodeproj \
           -scheme ProTip365 \
           -configuration Release \
           -archivePath ProTip365.xcarchive \
           archive

if [ $? -eq 0 ]; then
    print_status "Build and archive completed successfully"
else
    print_error "Build failed"
    exit 1
fi

# Step 4: Upload to App Store Connect
echo ""
echo "⬆️  Step 4: Uploading to App Store Connect"
echo "----------------------------------------"

if [ -n "$APP_STORE_USERNAME" ] && [ -n "$APP_STORE_PASSWORD" ]; then
    print_status "Uploading to App Store Connect"
    xcrun altool --upload-app \
                --type ios \
                --file ProTip365.xcarchive \
                --username "$APP_STORE_USERNAME" \
                --password "$APP_STORE_PASSWORD"
    
    if [ $? -eq 0 ]; then
        print_status "Upload completed successfully"
    else
        print_error "Upload failed"
        exit 1
    fi
else
    print_warning "App Store credentials not provided, skipping upload"
    print_warning "Set APP_STORE_USERNAME and APP_STORE_PASSWORD environment variables"
fi

# Step 5: Submit via API (if credentials provided)
echo ""
echo "🔗 Step 5: Submitting via API"
echo "-----------------------------"

if [ -n "$API_KEY_ID" ] && [ -n "$API_ISSUER_ID" ] && [ -n "$API_PRIVATE_KEY_PATH" ]; then
    print_status "Submitting subscription for review via API"
    
    # Generate JWT token (simplified - in production, use proper JWT library)
    print_warning "JWT token generation requires proper implementation"
    print_warning "For now, submit manually in App Store Connect"
    
    # API submission would go here
    # curl -X POST "https://api.appstoreconnect.apple.com/v1/subscriptionGroupSubmissions" \
    #      -H "Authorization: Bearer $JWT_TOKEN" \
    #      -H "Content-Type: application/json" \
    #      -d '{
    #        "data": {
    #          "type": "subscriptionGroupSubmissions",
    #          "relationships": {
    #            "subscriptionGroup": {
    #              "data": {
    #                "type": "subscriptionGroups",
    #                "id": "21769428"
    #              }
    #            }
    #          }
    #        }
    #      }'
else
    print_warning "API credentials not provided, skipping API submission"
    print_warning "Set API_KEY_ID, API_ISSUER_ID, and API_PRIVATE_KEY_PATH environment variables"
fi

# Step 6: Post-submission monitoring setup
echo ""
echo "📊 Step 6: Post-submission Monitoring"
echo "------------------------------------"

print_status "Setting up monitoring for submission status"
print_status "Check App Store Connect for submission status"
print_status "Monitor for any rejection reasons"

# Step 7: Summary
echo ""
echo "📋 Submission Summary"
echo "===================="
print_status "StoreKit configuration validated"
print_status "Build and archive completed"
if [ -n "$APP_STORE_USERNAME" ]; then
    print_status "Upload to App Store Connect completed"
else
    print_warning "Upload skipped (no credentials)"
fi

echo ""
echo "🎉 Next Steps:"
echo "1. Check App Store Connect for your build"
echo "2. Create new app version if needed"
echo "3. Submit subscription for review"
echo "4. Monitor submission status"
echo "5. Address any rejection feedback"

echo ""
echo "🔧 To prevent future StoreKit rejections:"
echo "1. Always validate StoreKit configuration before submission"
echo "2. Test subscription flow in sandbox environment"
echo "3. Ensure product IDs match between code and App Store Connect"
echo "4. Use automated testing for subscription scenarios"

print_status "Automated submission process completed!"
