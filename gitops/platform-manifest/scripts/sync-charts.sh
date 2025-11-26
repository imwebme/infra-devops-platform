#!/bin/bash

# Helm 차트 동기화 스크립트
set -e

# 소스와 타겟 저장소 설정
SOURCE_REPO="alwayz-gitops"
SOURCE_URL="https://wetripod.github.io/alwayz-gitops-manifest"
TARGET_BRANCH="gh-pages"

# 동기화할 차트 목록
CHART_NAMES=(
    "base-helm"
    "base-cronjobs" 
    "base-scraper"
    "cw-summary"
    "db-pgbouncer"
    "go-chive"
    "pg-job"
    "pg-partition"
)

echo "🔄 Helm 차트 동기화 시작..."

# 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 현재 브랜치: $CURRENT_BRANCH"

# main 브랜치 보호
if [[ "$CURRENT_BRANCH" == "main" ]]; then
    echo "⚠️  main 브랜치에서 실행 중입니다. main 브랜치는 안전하게 보호됩니다."
fi

# 동기화할 차트 선택
echo ""
echo "📋 사용 가능한 차트 목록:"
for i in "${!CHART_NAMES[@]}"; do
    echo "  $((i+1))) ${CHART_NAMES[$i]}"
done
echo "  a) 모든 차트"
echo ""
read -p "동기화할 차트를 선택하세요 (번호 또는 'a'): " selection

# 선택에 따른 차트 목록 결정
SELECTED_CHARTS=()
if [[ "$selection" == "a" || "$selection" == "A" ]]; then
    SELECTED_CHARTS=("${CHART_NAMES[@]}")
    echo "✅ 모든 차트를 동기화합니다."
elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#CHART_NAMES[@]}" ]; then
    SELECTED_CHARTS=("${CHART_NAMES[$((selection-1))]}")
    echo "✅ ${CHART_NAMES[$((selection-1))]} 차트를 동기화합니다."
else
    echo "❌ 잘못된 선택입니다. 종료합니다."
    exit 1
fi

# 1. Helm 저장소 추가
echo "📦 Helm 저장소 추가 중..."
helm repo add $SOURCE_REPO $SOURCE_URL 2>/dev/null || echo "저장소가 이미 존재합니다."
helm repo update

# 2. 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR
echo "📁 작업 디렉토리: $TEMP_DIR"

# 3. 선택된 차트들 처리
ALL_VERSIONS=""
TOTAL_CHARTS=0

for CHART_NAME in "${SELECTED_CHARTS[@]}"; do
    echo ""
    echo "🔍 $CHART_NAME 차트 처리 중..."
    
    # 해당 차트의 버전 목록 가져오기
    VERSIONS=$(helm search repo $SOURCE_REPO/$CHART_NAME --versions --output json 2>/dev/null | jq -r '.[].version' 2>/dev/null || echo "")
    
    if [ -z "$VERSIONS" ]; then
        echo "⚠️  $CHART_NAME 차트를 찾을 수 없습니다. 건너뜁니다."
        continue
    fi
    
    echo "📋 $CHART_NAME 버전들: $(echo $VERSIONS | tr '\n' ', ' | sed 's/, $//')"
    
    # 차트 다운로드
    echo "⬇️  $CHART_NAME 차트 다운로드 중..."
    for version in $VERSIONS; do
        echo "  - $CHART_NAME:$version 다운로드 중..."
        if helm pull $SOURCE_REPO/$CHART_NAME --version $version 2>/dev/null; then
            ((TOTAL_CHARTS++))
        else
            echo "    ⚠️  $CHART_NAME:$version 다운로드 실패"
        fi
    done
    
    ALL_VERSIONS="$ALL_VERSIONS\n$CHART_NAME: $(echo $VERSIONS | tr '\n' ', ' | sed 's/, $//')"
done

# 4. index.yaml 생성
echo ""
echo "📝 Helm 인덱스 생성 중..."
helm repo index . --url https://wetripod.github.io/devops-gitops-manifest

echo "✅ 동기화 완료!"
echo "📦 다운로드된 차트 파일들 ($TOTAL_CHARTS개):"
ls -la *.tgz 2>/dev/null | wc -l | xargs echo "  총" && echo "개 파일"
echo "📝 index.yaml 생성됨"

# gh-pages 브랜치에 자동 업로드 여부 묻기
echo ""
echo "🚀 다음 단계 옵션:"
echo "  1) 수동: 파일들을 직접 확인하고 수동으로 gh-pages에 업로드"
echo "  2) 자동: gh-pages 브랜치에 자동으로 커밋 및 푸시 (권장)"
echo ""
read -p "자동으로 gh-pages에 업로드하시겠습니까? (y/N): " auto_upload

if [[ $auto_upload =~ ^[Yy]$ ]]; then
    echo "🔄 gh-pages 브랜치로 자동 업로드 중..."
    
    # 현재 저장소 디렉토리로 돌아가기
    ORIGINAL_DIR="/Users/example-org/workspace/alwayz/devops/devops-gitops-manifest"
    cd $ORIGINAL_DIR
    
    # 현재 브랜치 저장
    ORIGINAL_BRANCH=$(git branch --show-current)
    echo "📍 현재 브랜치 저장: $ORIGINAL_BRANCH"
    
    # 작업 중인 변경사항 확인
    if ! git diff --quiet || ! git diff --staged --quiet; then
        echo "⚠️  현재 브랜치에 커밋되지 않은 변경사항이 있습니다."
        echo "💾 변경사항을 스태시에 저장합니다..."
        git stash push -m "Auto-stash before helm chart sync - $(date)"
        STASHED=true
    else
        STASHED=false
    fi
    
    # gh-pages 브랜치 체크아웃 (없으면 생성)
    if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
        echo "🌿 기존 gh-pages 브랜치 체크아웃..."
        git checkout $TARGET_BRANCH
    elif git show-ref --verify --quiet refs/remotes/origin/$TARGET_BRANCH; then
        echo "🌿 원격 gh-pages 브랜치 체크아웃..."
        git checkout -b $TARGET_BRANCH origin/$TARGET_BRANCH
    else
        echo "🌱 새로운 gh-pages 브랜치 생성..."
        git checkout --orphan $TARGET_BRANCH
        git rm -rf . 2>/dev/null || true
    fi
    
    # 기존 차트 파일들 제거 (index.yaml 제외하고 백업)
    if [ -f "index.yaml" ]; then
        cp index.yaml index.yaml.backup
    fi
    rm -f *.tgz 2>/dev/null || true
    
    # 새 파일들 복사
    echo "📋 새 차트 파일들 복사 중..."
    cp $TEMP_DIR/*.tgz . 2>/dev/null || true
    cp $TEMP_DIR/index.yaml .
    
    # Git 커밋
    git add .
    
    if git diff --staged --quiet; then
        echo "ℹ️  변경사항이 없습니다. 커밋하지 않습니다."
    else
        echo "💾 변경사항 커밋 중..."
        
        # 커밋 메시지 생성
        if [ ${#SELECTED_CHARTS[@]} -eq 1 ]; then
            COMMIT_MSG="chore: sync ${SELECTED_CHARTS[0]} helm chart from alwayz-gitops-manifest"
        else
            COMMIT_MSG="chore: sync multiple helm charts from alwayz-gitops-manifest

- 동기화된 차트들: $(printf '%s, ' "${SELECTED_CHARTS[@]}" | sed 's/, $//')"
        fi
        
        git commit -m "$COMMIT_MSG

- 총 차트 파일: $TOTAL_CHARTS개
- 동기화 시각: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        
        echo "🚀 gh-pages 브랜치에 푸시 중..."
        git push origin $TARGET_BRANCH
        
        echo "✅ 성공적으로 업로드되었습니다!"
        echo "🔗 Helm 저장소 URL: https://wetripod.github.io/devops-gitops-manifest"
    fi
    
    # 원래 브랜치로 돌아가기
    echo "🔙 원래 브랜치($ORIGINAL_BRANCH)로 돌아가는 중..."
    git checkout $ORIGINAL_BRANCH
    
    # 스태시된 변경사항 복원
    if [ "$STASHED" = true ]; then
        echo "📤 스태시된 변경사항 복원 중..."
        git stash pop
    fi
    
else
    echo "📁 파일 위치: $TEMP_DIR"
    echo "💡 수동 업로드 방법:"
    echo "   1. git checkout gh-pages"
    echo "   2. cp $TEMP_DIR/*.tgz ."
    echo "   3. cp $TEMP_DIR/index.yaml ."
    echo "   4. git add . && git commit -m 'Update helm charts'"
    echo "   5. git push origin gh-pages"
    echo "   6. git checkout main  # 원래 브랜치로 돌아가기"
fi

# 정리 여부 묻기
echo ""
read -p "임시 디렉토리를 정리하시겠습니까? (y/N): " cleanup
if [[ $cleanup =~ ^[Yy]$ ]]; then
    rm -rf $TEMP_DIR
    echo "🧹 정리 완료"
else
    echo "📁 임시 디렉토리 유지: $TEMP_DIR"
fi

echo ""
echo "🎉 동기화 작업 완료!"
echo "📊 요약:"
echo "  - 처리된 차트: $(printf '%s, ' "${SELECTED_CHARTS[@]}" | sed 's/, $//')"
echo "  - 총 파일 수: $TOTAL_CHARTS개"