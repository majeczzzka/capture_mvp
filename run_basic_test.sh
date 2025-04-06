#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Path to Flutter SDK
FLUTTER_PATH="/Users/majaostrowska/flutter/bin/flutter"

echo -e "${GREEN}Running all integration tests...${NC}"

# 1. Bare minimum test
echo -e "\n${BLUE}Running bare minimum test...${NC}"
$FLUTTER_PATH test integration_test/bare_minimum_test.dart

if [ $? -ne 0 ]; then
  echo -e "${RED}Bare minimum test failed${NC}"
  exit 1
else
  echo -e "${GREEN}Bare minimum test completed successfully${NC}"
fi

# 2. Video thumbnail test
echo -e "\n${BLUE}Running video thumbnail basic test...${NC}"
$FLUTTER_PATH test integration_test/video_thumbnail_basic_test.dart

if [ $? -ne 0 ]; then
  echo -e "${RED}Video thumbnail basic test failed${NC}"
  exit 1
else
  echo -e "${GREEN}Video thumbnail basic test completed successfully${NC}"
fi

# 3. Form validation test
echo -e "\n${BLUE}Running form validation test...${NC}"
$FLUTTER_PATH test integration_test/form_validation_test.dart

if [ $? -ne 0 ]; then
  echo -e "${RED}Form validation test failed${NC}"
  exit 1
else
  echo -e "${GREEN}Form validation test completed successfully${NC}"
fi

# 4. Navigation test
echo -e "\n${BLUE}Running navigation test...${NC}"
$FLUTTER_PATH test integration_test/navigation_test.dart

if [ $? -ne 0 ]; then
  echo -e "${RED}Navigation test failed${NC}"
  exit 1
else
  echo -e "${GREEN}Navigation test completed successfully${NC}"
fi

echo -e "\n${GREEN}🎉 All tests completed successfully! 🎉${NC}" 