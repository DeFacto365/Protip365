#!/bin/bash

# Fix deprecated LinearProgressIndicator and CircularProgressIndicator
# From: LinearProgressIndicator(progress, ...)
# To: LinearProgressIndicator(progress = { progress }, ...)

FILES=(
"/Users/jacquesbolduc/Github/ProTip365/ProTip365Android/app/src/main/java/com/protip365/app/presentation/achievements/AchievementsScreen.kt"
"/Users/jacquesbolduc/Github/ProTip365/ProTip365Android/app/src/main/java/com/protip365/app/presentation/auth/WelcomeSignUpScreen.kt"
"/Users/jacquesbolduc/Github/ProTip365/ProTip365Android/app/src/main/java/com/protip365/app/presentation/detail/DetailStatsSection.kt"
"/Users/jacquesbolduc/Github/ProTip365/ProTip365Android/app/src/main/java/com/protip365/app/presentation/onboarding/OnboardingScreen.kt"
"/Users/jacquesbolduc/Github/ProTip365/ProTip365Android/app/src/main/java/com/protip365/app/presentation/settings/SubscriptionSettingsSection.kt"
)

echo "🔄 Fixing LinearProgressIndicator deprecations..."

for file in "${FILES[@]}"; do
  # Pattern: LinearProgressIndicator(varName, 
  # Replace with: LinearProgressIndicator(progress = { varName },
  
  sed -i '' -E 's/LinearProgressIndicator\(([a-zA-Z0-9_]+),/LinearProgressIndicator(progress = { \1 },/g' "$file"
  sed -i '' -E 's/CircularProgressIndicator\(([a-zA-Z0-9_]+),/CircularProgressIndicator(progress = { \1 },/g' "$file"
  
  echo "✅ Fixed: $file"
done

echo "✅ All progress indicators fixed!"

