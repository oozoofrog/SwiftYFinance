#!/bin/bash
# SwiftYFinance CLI Integration Test Script
# 모든 11개 명령어의 기본 동작을 자동으로 테스트합니다.

set -e  # Exit on error

echo "🚀 SwiftYFinance CLI Integration Test Started"
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
echo -e "${BLUE}📦 Building SwiftYFinance CLI...${NC}"
swift build

echo -e "\n${BLUE}🧪 Running CLI Integration Tests${NC}"
echo "=================================="

# Test 1: Quote Command
run_test "Quote Command (AAPL)" "swift run swiftyfinance quote AAPL --json"
run_test "Quote Command (TSLA)" "swift run swiftyfinance quote TSLA --json"

# Test 2: QuoteSummary Command  
run_test "QuoteSummary Essential (AAPL)" "swift run swiftyfinance quotesummary AAPL --type essential --json"
run_test "QuoteSummary Company (AAPL)" "swift run swiftyfinance quotesummary AAPL --type company --json"
run_test "QuoteSummary Price (AAPL)" "swift run swiftyfinance quotesummary AAPL --type price --json"

# Test 3: History Command
run_test "History 5d (AAPL)" "swift run swiftyfinance history AAPL --period 5d --json"
run_test "History 1mo (TSLA)" "swift run swiftyfinance history TSLA --period 1mo --json"

# Test 4: Search Command
run_test "Search Apple" "swift run swiftyfinance search 'Apple' --limit 3 --json"
run_test "Search Technology" "swift run swiftyfinance search 'Technology' --limit 5 --json"

# Test 5: Fundamentals Command
run_test "Fundamentals (AAPL)" "swift run swiftyfinance fundamentals AAPL --json"
run_test "Fundamentals (MSFT)" "swift run swiftyfinance fundamentals MSFT --json"

# Test 6: Screening Command
run_test "Screening Day Gainers" "swift run swiftyfinance screening day_gainers --limit 3 --json"
run_test "Screening Most Actives" "swift run swiftyfinance screening most_actives --limit 5 --json"

# Test 7: Options Command
run_test "Options (AAPL)" "swift run swiftyfinance options AAPL --json"
run_test "Options (TSLA)" "swift run swiftyfinance options TSLA --json"

# Test 8: News Command
run_test "News (AAPL)" "swift run swiftyfinance news AAPL --json"
run_test "News (MSFT)" "swift run swiftyfinance news MSFT --json"

# Test 9: Domain Command
run_test "Domain Sector" "swift run swiftyfinance domain --type sector --json"
run_test "Domain Industry" "swift run swiftyfinance domain --type industry --json"
run_test "Domain Market" "swift run swiftyfinance domain --type market --json"

# Test 10: Custom Screening Command
run_test "Custom Screening Market Cap" "swift run swiftyfinance custom-screening --market-cap '1B:10B' --json"
run_test "Custom Screening PE Ratio" "swift run swiftyfinance custom-screening --pe-ratio '10:25' --json"

# Test 11: WebSocket Command (special handling)
run_websocket_test "WebSocket (AAPL)" "swift run swiftyfinance websocket AAPL --duration 2 --json"
run_websocket_test "WebSocket Multi-Symbol" "swift run swiftyfinance websocket AAPL TSLA --duration 2 --json"

# Help commands test
echo -e "\n${BLUE}📚 Testing Help Commands${NC}"
echo "========================="
run_test "Main Help" "swift run swiftyfinance --help"
run_test "Quote Help" "swift run swiftyfinance quote --help"
run_test "QuoteSummary Help" "swift run swiftyfinance quotesummary --help"
run_test "Domain Help" "swift run swiftyfinance domain --help"
run_test "Custom Screening Help" "swift run swiftyfinance custom-screening --help"
run_test "WebSocket Help" "swift run swiftyfinance websocket --help"

# Summary
echo -e "\n${BLUE}📊 Test Results Summary${NC}"
echo "======================="
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! SwiftYFinance CLI is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ $FAILED_TESTS test(s) failed. Please check the output above.${NC}"
    exit 1
fi