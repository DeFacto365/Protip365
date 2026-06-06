#!/bin/bash

# Script to configure StoreKit in Xcode project
echo "🚀 Setting up StoreKit configuration..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed"
    exit 1
fi

# Store current directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# Check if project file exists
if [ ! -f "ProTip365.xcodeproj/project.pbxproj" ]; then
    echo "❌ ProTip365.xcodeproj not found"
    exit 1
fi

# Check if StoreKit file exists
if [ ! -f "ProTip365/Protip365.storekit" ]; then
    echo "❌ Protip365.storekit file not found"
    exit 1
fi

echo "✅ Found ProTip365 project and StoreKit file"

# Create a temporary scheme with StoreKit configuration
cat > ProTip365.xcodeproj/xcshareddata/xcschemes/ProTip365_StoreKit.xcscheme << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "9F1F3E2F2C8E4B9D00A0F1A5"
               BuildableName = "ProTip365.app"
               BlueprintName = "ProTip365"
               ReferencedContainer = "container:ProTip365.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "9F1F3E2F2C8E4B9D00A0F1A5"
            BuildableName = "ProTip365.app"
            BlueprintName = "ProTip365"
            ReferencedContainer = "container:ProTip365.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <StoreKitConfigurationFileReference
         identifier = "../ProTip365/Protip365.storekit">
      </StoreKitConfigurationFileReference>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "9F1F3E2F2C8E4B9D00A0F1A5"
            BuildableName = "ProTip365.app"
            BlueprintName = "ProTip365"
            ReferencedContainer = "container:ProTip365.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo "✅ Created scheme with StoreKit configuration"

# Instructions for the user
echo ""
echo "📱 AUTOMATIC STOREKIT SETUP COMPLETE!"
echo ""
echo "To use the StoreKit configuration:"
echo "1. Open ProTip365.xcodeproj in Xcode"
echo "2. In the scheme selector (top bar), select 'ProTip365_StoreKit'"
echo "3. Build and run the app"
echo ""
echo "The subscription products should now load properly!"
echo ""
echo "Alternative: You can still use the 'Continue Anyway' button in the app."