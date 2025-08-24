#!/bin/bash
# SwiftYFinance CLI Setup Script
# 개발 환경 설정 및 최적화

set -e

echo "🚀 SwiftYFinance CLI Setup"
echo "========================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'  
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📦 Building SwiftYFinance CLI...${NC}"
swift build -c release

echo -e "${GREEN}✅ Release build completed!${NC}"

# Create convenient aliases
echo -e "\n${BLUE}🔧 Setting up convenient shortcuts...${NC}"

# Create a wrapper script for easier execution
cat > swiftyfinance << 'EOF'
#!/bin/bash
# SwiftYFinance CLI Wrapper
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
exec "$SCRIPT_DIR/.build/release/swiftyfinance" "$@"
EOF

chmod +x swiftyfinance

echo -e "${GREEN}✅ Created ./swiftyfinance wrapper script${NC}"

# Test the installation
echo -e "\n${BLUE}🧪 Testing CLI installation...${NC}"
./swiftyfinance --version

echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
echo
echo "Usage:"
echo "  ./swiftyfinance <command>           # Use wrapper script"
echo "  .build/release/swiftyfinance        # Direct binary"
echo "  ./integration_test.sh               # Run all tests"
echo "  ./benchmark.sh                      # Performance benchmark"
echo
echo "Examples:"
echo "  ./swiftyfinance quote AAPL"
echo "  ./swiftyfinance quotesummary AAPL --type essential"
echo "  ./swiftyfinance websocket AAPL TSLA --duration 30"