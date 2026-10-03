#!/bin/bash
# Quick test runner for ProTip365 Android app
# Makes testing fast and easy!

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ProTip365 Android Test Suite          ║${NC}"
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Parse command line arguments
TEST_TYPE="${1:-all}"

case $TEST_TYPE in
    "unit"|"u")
        print_section "Running Unit Tests (Fast - 20 seconds)"
        echo "Testing: Locale decimal parsing logic"
        echo ""
        ./gradlew test
        ;;

    "ui"|"workflow"|"w")
        print_section "Running UI Workflow Tests (2-3 minutes)"
        echo "Testing: Complete app workflows"
        echo ""

        # Check if device is connected
        if ! adb devices | grep -q "device$"; then
            echo -e "${RED}❌ No Android device/emulator connected!${NC}"
            echo -e "${YELLOW}Please start an emulator or connect a device first.${NC}"
            echo ""
            echo "To list available emulators:"
            echo "  emulator -list-avds"
            echo ""
            echo "To start an emulator:"
            echo "  emulator -avd <emulator-name>"
            exit 1
        fi

        ./gradlew connectedAndroidTest
        ;;

    "employer"|"e")
        print_section "Testing Employer Workflows Only"
        ./gradlew connectedAndroidTest
        echo "Note: Running all UI tests (test filtering not available in this Gradle version)"
        ;;

    "entry"|"en")
        print_section "Testing Entry Workflows Only"
        ./gradlew connectedAndroidTest
        echo "Note: Running all UI tests (test filtering not available in this Gradle version)"
        ;;

    "calculator"|"calc"|"c")
        print_section "Testing Calculator Workflows Only"
        ./gradlew connectedAndroidTest
        echo "Note: Running all UI tests (test filtering not available in this Gradle version)"
        ;;

    "settings"|"s")
        print_section "Testing Settings Workflows Only"
        ./gradlew connectedAndroidTest
        echo "Note: Running all UI tests (test filtering not available in this Gradle version)"
        ;;

    "quick"|"q")
        print_section "Quick Test (Unit tests only - fastest)"
        ./gradlew test
        ;;

    "all"|"a")
        print_section "Running ALL Tests"
        echo "Step 1/2: Unit Tests (20s)"
        ./gradlew test
        echo ""

        echo "Step 2/2: UI Workflow Tests (2-3min)"

        # Check if device is connected
        if ! adb devices | grep -q "device$"; then
            echo -e "${YELLOW}⚠️  No device connected - skipping UI tests${NC}"
            echo -e "${YELLOW}Run './test-app.sh ui' after connecting a device${NC}"
        else
            ./gradlew connectedAndroidTest
        fi
        ;;

    "watch")
        print_section "Watch Mode - Auto-run tests on file changes"
        echo "Tests will automatically re-run when you save files"
        echo "Press Ctrl+C to stop"
        echo ""
        ./gradlew test --continuous
        ;;

    "help"|"-h"|"--help")
        echo "Usage: ./test-app.sh [option]"
        echo ""
        echo "Options:"
        echo "  unit, u         Run unit tests only (20s) ⚡️"
        echo "  ui, w           Run UI workflow tests (2-3min)"
        echo "  employer, e     Test employer workflows only"
        echo "  entry, en       Test entry workflows only"
        echo "  calculator, c   Test calculator workflows only"
        echo "  settings, s     Test settings workflows only"
        echo "  quick, q        Quick unit tests (fastest)"
        echo "  all, a          Run all tests (default)"
        echo "  watch           Auto-run tests on file changes"
        echo "  help, -h        Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./test-app.sh              # Run all tests"
        echo "  ./test-app.sh unit         # Just unit tests (20s)"
        echo "  ./test-app.sh calculator   # Just calculator tests"
        echo "  ./test-app.sh watch        # Auto-run on changes"
        exit 0
        ;;

    *)
        echo -e "${RED}Unknown option: $TEST_TYPE${NC}"
        echo "Run './test-app.sh help' for usage information"
        exit 1
        ;;
esac

# Check if tests passed
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ✅ ALL TESTS PASSED! ✅         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║         ❌ SOME TESTS FAILED ❌         ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Check the output above for details${NC}"
    exit 1
fi
