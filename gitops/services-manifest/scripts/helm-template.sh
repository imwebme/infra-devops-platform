#!/bin/bash

# 사용법 출력 함수
print_usage() {
    echo "Usage: $0 <chart-name> [values-file-path-or-url...]"
    echo "Example:"
    echo "  $0 workloads/base-cronjobs"
    echo "  $0 workloads/base-cronjobs values/dev/values.yaml"
    echo "  $0 workloads/base-cronjobs values/base.yaml values/dev/values.yaml"
    echo "  $0 workloads/base-cronjobs https://github.com/user/repo/blob/main/values.yaml values/override.yaml"
    exit 1
}

# 인자 체크
if [ $# -lt 1 ]; then
    print_usage
fi

# 스크립트가 demo-gitops-manifest 루트 디렉토리에서 실행되는지 확인
if [ ! -d "charts" ]; then
    echo "Error: This script must be run from the demo-gitops-manifest root directory"
    exit 1
fi

CHART_NAME=$1
CHART_PATH="charts/$CHART_NAME"

# 차트 경로 존재 확인
if [ ! -d "$CHART_PATH" ]; then
    echo "Error: Chart directory '$CHART_PATH' does not exist"
    exit 1
fi

# helm template 명령어 구성
HELM_CMD="helm template $CHART_PATH"

# values 파일들이 제공된 경우 처리
TEMP_FILES=()
shift # 첫 번째 인자(차트 이름) 제거

for VALUES_FILE in "$@"; do
    # URL인 경우 임시 파일로 다운로드
    if [[ "$VALUES_FILE" == http* ]]; then
        TEMP_VALUES_FILE=$(mktemp)
        TEMP_FILES+=("$TEMP_VALUES_FILE")
        
        # GitHub blob URL을 raw 콘텐츠 URL로 변환
        RAW_URL=$(echo "$VALUES_FILE" | sed 's/github.com/raw.githubusercontent.com/' | sed 's/\/blob\//\//')
        
        # GitHub 토큰이 환경변수로 설정되어 있는 경우 사용
        if [ -n "$GITHUB_TOKEN" ]; then
            curl -sfL -H "Authorization: token $GITHUB_TOKEN" "$RAW_URL" -o "$TEMP_VALUES_FILE"
        else
            curl -sfL "$RAW_URL" -o "$TEMP_VALUES_FILE"
        fi
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to download values file from '$VALUES_FILE'"
            # 임시 파일들 정리
            for temp_file in "${TEMP_FILES[@]}"; do
                rm -f "$temp_file"
            done
            exit 1
        fi
        HELM_CMD="$HELM_CMD -f $TEMP_VALUES_FILE"
    elif [ ! -f "$VALUES_FILE" ]; then
        echo "Error: Values file '$VALUES_FILE' does not exist"
        # 임시 파일들 정리
        for temp_file in "${TEMP_FILES[@]}"; do
            rm -f "$temp_file"
        done
        exit 1
    else
        HELM_CMD="$HELM_CMD -f $VALUES_FILE"
    fi
done

# helm template 실행
eval $HELM_CMD

# 임시 파일들 정리
for temp_file in "${TEMP_FILES[@]}"; do
    rm -f "$temp_file"
done