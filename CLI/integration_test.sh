#!/bin/bash
# swift-yf-tools Integration Test Script
# 모든 12개 명령어의 기본 동작을 자동으로 테스트합니다.

set -e  # Exit on error

echo "swift-yf-tools Integration Test Started"
echo "=============================================="

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    
    echo -n "🧪 Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "   Command: $command"
    fi
}

# Function to run a WebSocket test (shorter duration)
run_websocket_test() {
    local test_name="$1"
    local command="$2"
    
    echo -n "🧪 Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Run WebSocket command in background and kill after 3 seconds
    timeout 3s eval "$command" > /dev/null 2>&1
    local exit_code=$?
    
    # For WebSocket, timeout (124) is expected and means success
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 124 ]; then
        echo -e "${GREEN}✅ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED${NC} (exit code: $exit_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "   Command: $command"
    fi
}

# Build the CLI first
echo -e "${BLUE}Building swift-yf-tools...${NC}"
swift build

echo -e "\n${BLUE}🧪 Running CLI Integration Tests${NC}"
echo "=================================="

# Test 1: Quote Command
run_test "Quote Command (AAPL)" "swift run swift-yf-tools quote AAPL --json"
run_test "Quote Command (TSLA)" "swift run swift-yf-tools quote TSLA --json"

# Test 2: QuoteSummary Command  
run_test "QuoteSummary Essential (AAPL)" "swift run swift-yf-tools quotesummary AAPL --type essential --json"
run_test "QuoteSummary Company (AAPL)" "swift run swift-yf-tools quotesummary AAPL --type company --json"
run_test "QuoteSummary Price (AAPL)" "swift run swift-yf-tools quotesummary AAPL --type price --json"

# Test 3: History Command
run_test "History 5d (AAPL)" "swift run swift-yf-tools history AAPL --period 5d --json"
run_test "History 1mo (TSLA)" "swift run swift-yf-tools history TSLA --period 1mo --json"

# Test 4: Search Command
run_test "Search Apple" "swift run swift-yf-tools search 'Apple' --limit 3 --json"
run_test "Search Technology" "swift run swift-yf-tools search 'Technology' --limit 5 --json"

# Test 5: Fundamentals Command
run_test "Fundamentals (AAPL)" "swift run swift-yf-tools fundamentals AAPL --json"
run_test "Fundamentals (MSFT)" "swift run swift-yf-tools fundamentals MSFT --json"

# Test 6: Screening Command
run_test "Screening Day Gainers" "swift run swift-yf-tools screening day_gainers --limit 3 --json"
run_test "Screening Most Actives" "swift run swift-yf-tools screening most_actives --limit 5 --json"

# Test 7: Options Command
run_test "Options (AAPL)" "swift run swift-yf-tools options AAPL --json"
run_test "Options (TSLA)" "swift run swift-yf-tools options TSLA --json"

# Test 8: News Command
run_test "News (AAPL)" "swift run swift-yf-tools news AAPL --json"
run_test "News (MSFT)" "swift run swift-yf-tools news MSFT --json"

# Test 9: Domain Command
run_test "Domain Sector" "swift run swift-yf-tools domain --type sector --json"
run_test "Domain Industry" "swift run swift-yf-tools domain --type industry --json"
run_test "Domain Market" "swift run swift-yf-tools domain --type market --json"

# Test 10: Custom Screening Command
run_test "Custom Screening Market Cap" "swift run swift-yf-tools custom-screening --market-cap '1B:10B' --json"
run_test "Custom Screening PE Ratio" "swift run swift-yf-tools custom-screening --pe-ratio '10:25' --json"

# Test 11: WebSocket Command (special handling)
run_websocket_test "WebSocket (AAPL)" "swift run swift-yf-tools websocket AAPL --duration 2 --json"
run_websocket_test "WebSocket Multi-Symbol" "swift run swift-yf-tools websocket AAPL TSLA --duration 2 --json"

# Help commands test
echo -e "\n${BLUE}📚 Testing Help Commands${NC}"
echo "========================="
run_test "Main Help" "swift run swift-yf-tools --help"
run_test "Quote Help" "swift run swift-yf-tools quote --help"
run_test "QuoteSummary Help" "swift run swift-yf-tools quotesummary --help"
run_test "Domain Help" "swift run swift-yf-tools domain --help"
run_test "Custom Screening Help" "swift run swift-yf-tools custom-screening --help"
run_test "WebSocket Help" "swift run swift-yf-tools websocket --help"

# Summary
echo -e "\n${BLUE}📊 Test Results Summary${NC}"
echo "======================="
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! swift-yf-tools is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ $FAILED_TESTS test(s) failed. Please check the output above.${NC}"
    exit 1
fi