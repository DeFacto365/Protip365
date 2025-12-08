#!/bin/bash

# ProTip365 Android - Automated Warning Fix Script
# Fixes all deprecated API warnings systematically

echo "🔧 Starting automated warning fixes..."

cd "$(dirname "$0")"

# Phase 1: Fix deprecated Icons (AutoMirrored)
echo "📱 Phase 1: Fixing deprecated icons..."

find app/src/main/java -name "*.kt" -type f -exec sed -i '' \
  -e 's/Icons\.Default\.ArrowBack/Icons.AutoMirrored.Filled.ArrowBack/g' \
  -e 's/Icons\.Default\.ArrowForward/Icons.AutoMirrored.Filled.ArrowForward/g' \
  -e 's/Icons\.Default\.TrendingUp/Icons.AutoMirrored.Filled.TrendingUp/g' \
  -e 's/Icons\.Default\.TrendingDown/Icons.AutoMirrored.Filled.TrendingDown/g' \
  -e 's/Icons\.Default\.List/Icons.AutoMirrored.Filled.List/g' \
  -e 's/Icons\.Default\.Help/Icons.AutoMirrored.Filled.Help/g' \
  -e 's/Icons\.Default\.HelpOutline/Icons.AutoMirrored.Filled.HelpOutline/g' \
  -e 's/Icons\.Default\.Logout/Icons.AutoMirrored.Filled.Logout/g' \
  -e 's/Icons\.Default\.Send/Icons.AutoMirrored.Filled.Send/g' \
  -e 's/Icons\.Default\.Message/Icons.AutoMirrored.Filled.Message/g' \
  -e 's/Icons\.Default\.ShowChart/Icons.AutoMirrored.Filled.ShowChart/g' \
  -e 's/Icons\.Default\.MenuBook/Icons.AutoMirrored.Filled.MenuBook/g' \
  -e 's/Icons\.Default\.Article/Icons.AutoMirrored.Filled.Article/g' \
  -e 's/Icons\.Default\.OpenInNew/Icons.AutoMirrored.Filled.OpenInNew/g' \
  {} \;

echo "✅ Icons fixed"

# Phase 2: Fix Divider → HorizontalDivider  
echo "📏 Phase 2: Fixing Divider → HorizontalDivider..."

find app/src/main/java -name "*.kt" -type f -exec sed -i '' \
  -e 's/Divider(/HorizontalDivider(/g' \
  {} \;

echo "✅ Dividers fixed"

# Phase 3: Add missing AutoMirrored imports
echo "📦 Phase 3: Adding AutoMirrored imports..."

# This will be done manually for affected files

echo "✅ Warning fix script complete!"
echo "⚠️  Note: Some fixes require manual import additions"
echo "Run './gradlew compileDebugKotlin' to verify"

