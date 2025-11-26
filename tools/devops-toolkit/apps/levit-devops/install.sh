#!/bin/bash

# example-org-devops 설치 스크립트

set -e

echo "🚀 example-org-devops 설치를 시작합니다..."

# 플랫폼 지원 확인
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 현재 macOS만 지원됩니다. 다른 플랫폼은 수동 설치가 필요합니다."
    echo "📝 수동 설치 가이드: https://github.com/alwayz/devops-monorepo/blob/main/apps/example-org-devops/README.md"
    exit 1
fi

# 설치 디렉터리 설정
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# 로컬 빌드 바이너리 경로
BINARY_PATH="./bin/example-org-devops"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ 바이너리를 찾을 수 없습니다. 먼저 'make build'를 실행하세요."
    exit 1
fi

# 바이너리 복사
cp "$BINARY_PATH" "$INSTALL_DIR/example-org-devops"
chmod +x "$INSTALL_DIR/example-org-devops"

echo "✅ example-org-devops가 $INSTALL_DIR에 설치되었습니다"

# PATH에 추가 (macOS 기본 zsh 사용)
SHELL_RC="$HOME/.zshrc"

# PATH 추가 확인
if ! grep -q "$INSTALL_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# example-org-devops PATH" >> "$SHELL_RC"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
    echo "✅ PATH가 $SHELL_RC에 추가되었습니다"
    echo "새 터미널을 열거나 'source $SHELL_RC'를 실행하세요"
else
    echo "✅ PATH가 이미 설정되어 있습니다"
fi

# 필수 도구 설치 여부 확인
echo ""
echo "📦 필수 도구 설치 상태 확인..."

check_tool() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✅ $1: 설치됨"
    else
        echo "❌ $1: 설치되지 않음"
        echo "   설치: example-org-devops install tools $1"
    fi
}

check_tool "kubectl"
check_tool "k9s"
check_tool "helm"
check_tool "argocd"
check_tool "aws"
check_tool "popeye"
check_tool "krr"
check_tool "gonzo"

echo ""
echo "🎉 설치가 완료되었습니다!"
echo ""
echo "사용법:"
echo "  example-org-devops --help                    # 도움말"
echo "  example-org-devops install tools             # 필수 도구 설치"
echo "  example-org-devops gonzo version             # 로그 분석 도구"
echo "  example-org-devops list all                  # 전체 리소스 조회"
echo "  example-org-devops update check              # 버전 확인"
echo ""
echo "새 터미널을 열거나 다음 명령을 실행하세요:"
echo "  source ~/.zshrc"