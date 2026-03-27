#!/bin/bash
# swift-yf-tools Setup Script
# 개발 환경 설정 및 최적화

set -e

echo "swift-yf-tools Setup"
echo "===================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Building swift-yf-tools...${NC}"
swift build -c release

echo -e "${GREEN}Release build completed!${NC}"

# Create convenient aliases
echo -e "\n${BLUE}Setting up convenient shortcuts...${NC}"

# Create a wrapper script for easier execution
cat > swift-yf-tools << 'EOF'
#!/bin/bash
# swift-yf-tools Wrapper
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
exec "$SCRIPT_DIR/.build/release/swift-yf-tools" "$@"
EOF

chmod +x swift-yf-tools

echo -e "${GREEN}Created ./swift-yf-tools wrapper script${NC}"

# Test the installation
echo -e "\n${BLUE}Testing CLI installation...${NC}"
./swift-yf-tools --version

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo
echo "Usage:"
echo "  ./swift-yf-tools <command>           # Use wrapper script"
echo "  .build/release/swift-yf-tools        # Direct binary"
echo "  ./integration_test.sh               # Run all tests"
echo "  ./benchmark.sh                      # Performance benchmark"
echo
echo "Examples:"
echo "  ./swift-yf-tools quote AAPL"
echo "  ./swift-yf-tools quotesummary AAPL --type essential"
echo "  ./swift-yf-tools websocket AAPL TSLA --duration 30"
echo
echo "MCP 설치:"
echo "  # Claude Desktop 자동 등록"
echo "  ./swift-yf-tools mcp install --client claude"
echo
echo "  # claude CLI로 원클릭 등록"
echo "  claude mcp add swift-yf-tools -- .build/release/swift-yf-tools mcp serve"
echo
echo "  # Cursor 프로젝트 설정 등록"
echo "  ./swift-yf-tools mcp install --client cursor"
echo
echo "자세한 사용법: https://github.com/oozoofrog/swift-yf-tools"
