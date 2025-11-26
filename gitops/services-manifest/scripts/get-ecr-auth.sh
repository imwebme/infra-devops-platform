#!/bin/sh
CACHE_FILE="/tmp/ecr_auth_token"
CACHE_DURATION=60  # 캐싱 시간(초)

# 현재 타임스탬프를 얻는 함수 (macOS 및 Linux 호환)
get_current_timestamp() {
  date +%s
}

# 파일의 마지막 수정 시간을 얻는 함수 (macOS 및 Linux 호환)
get_file_timestamp() {
  if stat -f "%m" "$1" >/dev/null 2>&1; then
    # macOS
    stat -f "%m" "$1"
  else
    # Linux
    stat -c "%Y" "$1"
  fi
}

# 캐싱된 파일이 유효한지 확인
if [ -f "$CACHE_FILE" ]; then
  FILE_TIMESTAMP=$(get_file_timestamp "$CACHE_FILE")
  CURRENT_TIMESTAMP=$(get_current_timestamp)
  if [ $((CURRENT_TIMESTAMP - FILE_TIMESTAMP)) -lt $CACHE_DURATION ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# 새 인증 토큰 생성 및 캐싱
aws ecr --region ap-northeast-2 get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d > "$CACHE_FILE"
cat "$CACHE_FILE"