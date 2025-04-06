#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Flutter path - replace with yours if different
FLUTTER_PATH="/Users/majaostrowska/flutter/bin/flutter"

echo -e "${YELLOW}Capture App Integration Test Runner${NC}"
echo -e "===============================\n"

# Check if Flutter is available at the specified path
if [ ! -f "$FLUTTER_PATH" ]; then
    echo -e "${RED}Error: Flutter not found at $FLUTTER_PATH. Please edit this script with the correct path.${NC}"
    exit 1
fi

# List available devices
echo -e "${YELLOW}Available devices:${NC}"
$FLUTTER_PATH devices

echo

# Ask user which device to run tests on
echo -e "${YELLOW}Enter the device ID to run tests on (leave empty to use first available device):${NC}"
read DEVICE_ID

# If no device specified, use the first one
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$($FLUTTER_PATH devices | grep -v "No devices" | grep "•" | head -1 | awk '{print $1}')
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}No device found. Please connect a device or start an emulator.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Using device: $DEVICE_ID${NC}"
fi

# Ask which test to run
echo -e "\n${YELLOW}Select which test to run:${NC}"
echo "1. All tests"
echo "2. App initialization and login test"
echo "3. Jar content test"
echo "4. Jar creation test"
echo -e "${YELLOW}Enter your choice (1-4):${NC}"
read TEST_CHOICE

# Run the selected test
case $TEST_CHOICE in
    1)
        echo -e "\n${GREEN}Running all integration tests...${NC}"
        $FLUTTER_PATH test integration_test -d $DEVICE_ID
        ;;
    2)
        echo -e "\n${GREEN}Running app initialization and login test...${NC}"
        $FLUTTER_PATH test integration_test/app_test.dart -d $DEVICE_ID
        ;;
    3)
        echo -e "\n${GREEN}Running jar content test...${NC}"
        $FLUTTER_PATH test integration_test/jar_content_test.dart -d $DEVICE_ID
        ;;
    4)
        echo -e "\n${GREEN}Running jar creation test...${NC}"
        $FLUTTER_PATH test integration_test/jar_creation_test.dart -d $DEVICE_ID
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Test execution completed.${NC}" 