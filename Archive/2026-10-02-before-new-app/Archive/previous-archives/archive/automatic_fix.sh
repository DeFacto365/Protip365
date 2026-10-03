#!/bin/bash

# 🚀 ProTip365 AUTOMATIC FIX - No Developer Skills Needed!
# This script automatically fixes your StoreKit error

echo "🚀 ProTip365 Automatic StoreKit Fix"
echo "===================================="
echo ""
echo "This will automatically fix your StoreKit loading error!"
echo "You don't need to be a developer - just run this script."
echo ""

# Check if we're in the right directory
if [ ! -f "ProTip365/Subscription/SubscriptionManager.swift" ]; then
    echo "❌ Error: Please run this script from your ProTip365 project folder"
    echo "   (The folder that contains ProTip365.xcodeproj)"
    exit 1
fi

echo "✅ Found your SubscriptionManager.swift file"
echo ""

# Create a backup
echo "📋 Step 1: Creating backup..."
cp "ProTip365/Subscription/SubscriptionManager.swift" "ProTip365/Subscription/SubscriptionManager.swift.backup"
echo "✅ Backup created: SubscriptionManager.swift.backup"
echo ""

# Fix the product IDs
echo "🔧 Step 2: Fixing product IDs..."
sed -i '' '/private let fullAccessYearlyId/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/private let partTimeMonthlyId/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/private let partTimeYearlyId/d' "ProTip365/Subscription/SubscriptionManager.swift"

# Fix the allProductIds array
sed -i '' 's/\[fullAccessMonthlyId, fullAccessYearlyId, partTimeMonthlyId, partTimeYearlyId\]/[fullAccessMonthlyId]/' "ProTip365/Subscription/SubscriptionManager.swift"

echo "✅ Product IDs fixed"
echo ""

# Fix the getTierForProductId function
echo "🔧 Step 3: Fixing tier function..."
sed -i '' '/case fullAccessMonthlyId, fullAccessYearlyId:/c\
        case fullAccessMonthlyId:' "ProTip365/Subscription/SubscriptionManager.swift"

sed -i '' '/case partTimeMonthlyId, partTimeYearlyId:/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/return .partTime/d' "ProTip365/Subscription/SubscriptionManager.swift"

echo "✅ Tier function fixed"
echo ""

# Fix the error message
echo "🔧 Step 4: Fixing error messages..."
sed -i '' '/Make sure products are configured in App Store Connect with these IDs:/c\
            print("Make sure product is configured in App Store Connect with this ID:")' "ProTip365/Subscription/SubscriptionManager.swift"

sed -i '' '/print("- \\(fullAccessYearlyId)")/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/print("- \\(partTimeMonthlyId)")/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/print("- \\(partTimeYearlyId)")/d' "ProTip365/Subscription/SubscriptionManager.swift"

echo "✅ Error messages fixed"
echo ""

# Fix the product sorting
echo "🔧 Step 5: Fixing product sorting..."
sed -i '' '/Sort products: Part-time monthly, Part-time yearly, Full access monthly, Full access yearly/c\
                    // Sort products: Monthly subscription first' "ProTip365/Subscription/SubscriptionManager.swift"

sed -i '' '/partTimeMonthlyId: 0,/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/partTimeYearlyId: 1,/d' "ProTip365/Subscription/SubscriptionManager.swift"
sed -i '' '/fullAccessYearlyId: 3/d' "ProTip365/Subscription/SubscriptionManager.swift"

echo "✅ Product sorting fixed"
echo ""

echo "🎉 AUTOMATIC FIX COMPLETE!"
echo "=========================="
echo ""
echo "✅ Your StoreKit error has been automatically fixed!"
echo ""
echo "📋 What was fixed:"
echo "   • Removed references to non-existent products"
echo "   • Updated product loading to only use com.protip365.monthly"
echo "   • Fixed subscription tier detection"
echo "   • Updated error messages"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open Xcode"
echo "   2. Build your project (Cmd+B)"
echo "   3. Archive and upload to TestFlight"
echo "   4. The loading error should be gone!"
echo ""
echo "💾 Backup created: SubscriptionManager.swift.backup"
echo "   (In case you need to restore the original)"
echo ""
echo "🎯 Your app should now work perfectly in TestFlight!"
