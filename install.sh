#!/bin/bash
# swift-yf-tools 설치 스크립트
# curl -fsSL https://raw.githubusercontent.com/oozoofrog/swift-yf-tools/main/install.sh | bash
#
# 사용법:
#   bash install.sh [옵션]
#
# 옵션:
#   --dry-run      실제로 파일을 쓰지 않고 동작을 출력만 함
#   --no-path      PATH 등록 생략
#   --no-mcp       MCP 설치 안내 생략
#   --help         이 도움말 출력

set -e

# ---- 기본 설정 ----
REPO_URL="https://github.com/oozoofrog/swift-yf-tools.git"
INSTALL_DIR="$HOME/.local/share/swift-yf-tools"
BIN_DIR="$HOME/.local/bin"
BINARY_NAME="swift-yf-tools"
DRY_RUN=false
NO_PATH=false
NO_MCP=false

# ---- 색상 ----
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ---- 도움말 ----
usage() {
    cat <<EOF
swift-yf-tools 설치 스크립트

사용법: bash install.sh [옵션]

옵션:
  --dry-run      실제 파일 쓰기 없이 동작 미리 확인
  --no-path      PATH 등록 건너뜀
  --no-mcp       MCP 설치 안내 건너뜀
  --help         이 도움말 출력

설치 과정:
  1. 저장소 클론  → $INSTALL_DIR
  2. swift build -c release
  3. $BIN_DIR/$BINARY_NAME 심볼릭 링크 생성
  4. PATH 등록 안내 ($HOME/.zshrc 또는 $HOME/.bashrc)
  5. MCP 등록 안내

빠른 설치 (curl one-liner):
  curl -fsSL https://raw.githubusercontent.com/oozoofrog/swift-yf-tools/main/install.sh | bash

claude CLI로 원클릭 MCP 등록 (이미 swift-yf-tools가 PATH에 있는 경우):
  claude mcp add swift-yf-tools -- swift-yf-tools mcp serve

EOF
}

# ---- 옵션 파싱 ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)  DRY_RUN=true  ;;
        --no-path)  NO_PATH=true  ;;
        --no-mcp)   NO_MCP=true   ;;
        --help|-h)  usage; exit 0 ;;
        *)
            echo -e "${RED}알 수 없는 옵션: $1${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done

# ---- 유틸리티 ----
run_or_dry() {
    # dry-run이면 출력만, 아니면 실제 실행
    if $DRY_RUN; then
        echo -e "${YELLOW}[dry-run] $*${NC}"
    else
        eval "$@"
    fi
}

# ---- 전제조건 확인 ----
check_requirements() {
    echo -e "${BLUE}전제조건 확인...${NC}"

    if ! command -v swift &>/dev/null; then
        echo -e "${RED}오류: swift 명령을 찾을 수 없습니다.${NC}"
        echo "  Swift 6.2+ 설치 후 다시 시도하세요."
        echo "  설치 안내: https://www.swift.org/install/"
        exit 1
    fi

    local swift_version
    swift_version=$(swift --version 2>&1 | head -1)
    echo "  swift: $swift_version"

    if ! command -v git &>/dev/null; then
        echo -e "${RED}오류: git 명령을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    echo -e "${GREEN}전제조건 확인 완료${NC}"
}

# ---- 저장소 클론 ----
clone_repo() {
    echo -e "\n${BLUE}저장소 클론 중...${NC}"
    echo "  대상: $INSTALL_DIR"

    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "  이미 존재합니다. 최신 버전으로 업데이트합니다."
        run_or_dry "git -C \"$INSTALL_DIR\" pull --ff-only"
    else
        run_or_dry "git clone \"$REPO_URL\" \"$INSTALL_DIR\""
    fi
}

# ---- CLI 빌드 ----
build_cli() {
    echo -e "\n${BLUE}CLI 빌드 중 (release 모드)...${NC}"
    echo "  cd $INSTALL_DIR/CLI && swift build -c release --product $BINARY_NAME"

    if $DRY_RUN; then
        echo -e "${YELLOW}[dry-run] swift build -c release --product $BINARY_NAME${NC}"
    else
        (cd "$INSTALL_DIR/CLI" && swift build -c release --product "$BINARY_NAME")
    fi

    echo -e "${GREEN}빌드 완료${NC}"
}

# ---- PATH 등록 ----
add_to_path() {
    if $NO_PATH; then
        return
    fi

    local bin_path="$INSTALL_DIR/CLI/.build/release/$BINARY_NAME"

    echo -e "\n${BLUE}PATH 등록...${NC}"
    echo "  바이너리: $bin_path"
    echo "  링크 대상: $BIN_DIR/$BINARY_NAME"

    run_or_dry "mkdir -p \"$BIN_DIR\""
    run_or_dry "ln -sf \"$bin_path\" \"$BIN_DIR/$BINARY_NAME\""

    # 셸 설정 파일 자동 감지
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [ -n "$shell_rc" ]; then
        local path_line='export PATH="$HOME/.local/bin:$PATH"'
        if $DRY_RUN; then
            echo -e "${YELLOW}[dry-run] $shell_rc 에 PATH 추가: $path_line${NC}"
        else
            if ! grep -qF '.local/bin' "$shell_rc" 2>/dev/null; then
                echo "" >> "$shell_rc"
                echo "# swift-yf-tools" >> "$shell_rc"
                echo "$path_line" >> "$shell_rc"
                echo -e "${GREEN}$shell_rc 에 PATH 등록 완료${NC}"
            else
                echo "  $shell_rc 에 이미 .local/bin 경로가 있습니다."
            fi
        fi
        echo -e "${YELLOW}  새 터미널을 열거나 'source $shell_rc' 를 실행하세요.${NC}"
    else
        echo -e "${YELLOW}  셸 설정 파일을 자동으로 찾지 못했습니다."
        echo "  아래 줄을 셸 설정 파일에 직접 추가하세요:"
        echo '  export PATH="$HOME/.local/bin:$PATH"'${NC}
    fi
}

# ---- MCP 설치 안내 ----
install_mcp() {
    if $NO_MCP; then
        return
    fi

    local bin_path="$BIN_DIR/$BINARY_NAME"

    echo -e "\n${BLUE}MCP 설치 안내${NC}"
    echo "=============================="
    echo
    echo "swift-yf-tools는 MCP(Model Context Protocol) 서버를 내장합니다."
    echo
    echo "방법 1 — claude CLI로 원클릭 등록 (권장):"
    echo
    echo "  claude mcp add swift-yf-tools -- $bin_path mcp serve"
    echo
    echo "방법 2 — 내장 mcp install 명령 사용:"
    echo
    echo "  $bin_path mcp install --client claude"
    echo "  $bin_path mcp install --client cursor"
    echo "  $bin_path mcp install --client local"
    echo
    echo "방법 3 — 설정 파일 수동 편집:"
    echo
    echo "  Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json"
    cat <<JSONEOF
  {
    "mcpServers": {
      "swift-yf-tools": {
        "command": "$bin_path",
        "args": ["mcp", "serve"]
      }
    }
  }
JSONEOF
    echo
    echo "  설정 적용 후 Claude Desktop을 재시작하세요."
    echo
    echo "제공하는 MCP 도구 (12개):"
    echo "  quote, multi-quote, chart, search, news, options,"
    echo "  screening, customScreener, quoteSummary, domain,"
    echo "  fundamentals, websocket-snapshot"
}

# ---- 완료 안내 ----
print_success() {
    echo
    echo -e "${GREEN}설치 완료!${NC}"
    echo
    echo "다음 명령으로 시작하세요:"
    echo
    echo "  $BINARY_NAME quote AAPL"
    echo "  $BINARY_NAME history AAPL --period 1mo"
    echo "  $BINARY_NAME --help"
    echo
    echo "자세한 사용법: https://github.com/oozoofrog/swift-yf-tools/blob/main/USAGE.md"
}

# ---- 메인 ----
main() {
    echo "swift-yf-tools 설치 스크립트"
    echo "=============================="
    if $DRY_RUN; then
        echo -e "${YELLOW}[dry-run 모드] 실제 파일을 쓰지 않습니다.${NC}"
    fi
    echo

    check_requirements
    clone_repo
    build_cli
    add_to_path
    install_mcp

    if ! $DRY_RUN; then
        print_success
    else
        echo -e "\n${YELLOW}[dry-run 완료] 실제 설치를 하려면 --dry-run 없이 실행하세요.${NC}"
    fi
}

main "$@"
