#!/bin/bash

# 사용법:
#   1. 환경변수를 사용하는 방법:
#      export REDIS_HOST="your-redis-host"
#      export REDIS_PORT="6379"
#      export REDIS_KEY_PATTERN="user:*"
#      ./redis-memory-usage.sh
#
#   2. 커맨드 라인 인자를 사용하는 방법:
#      ./redis-memory-usage.sh -h your-redis-host -p 6379 -k "user:*"
#
#   3. 기본값을 사용하는 방법 (localhost:6379, pattern: almart_key*):
#      ./redis-memory-usage.sh
#
# 설명:
#   Redis 클러스터에서 특정 패턴의 키들이 사용하는 메모리 용량을 계산합니다.
#   전체 메모리 대비 해당 키들의 메모리 사용 비율도 함께 보여줍니다.

# 사용법 출력 함수
usage() {
    echo "Usage: $0 [-h HOST] [-p PORT] [-k KEY_PATTERN]"
    echo "  -h : Redis host (또는 REDIS_HOST 환경변수 사용)"
    echo "  -p : Redis port (또는 REDIS_PORT 환경변수 사용)"
    echo "  -k : Key pattern (또는 REDIS_KEY_PATTERN 환경변수 사용)"
    exit 1
}

# 환경변수나 기본값으로 초기화
REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-6379}
KEY_PATTERN=${REDIS_KEY_PATTERN:-"almart_key*"}

# 커맨드 라인 인자 처리
while getopts "h:p:k:" opt; do
    case $opt in
        h) REDIS_HOST="$OPTARG" ;;
        p) REDIS_PORT="$OPTARG" ;;
        k) KEY_PATTERN="$OPTARG" ;;
        ?) usage ;;
    esac
done

# Redis 연결 테스트
if ! redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    echo "Error: Redis 연결 실패. HOST와 PORT를 확인해주세요."
    exit 1
fi

# Get all primary node IPs (excluding replicas)
PRIMARY_NODES=$(redis-cli -c -h "$REDIS_HOST" -p "$REDIS_PORT" cluster nodes | grep master | grep -v fail | awk '{print $2}' | cut -d@ -f1)
if [ -z "$PRIMARY_NODES" ]; then
    echo "Error: Primary nodes를 찾을 수 없습니다."
    exit 1
fi

total_sum=0

for node in $PRIMARY_NODES; do
    host=$(echo "$node" | cut -d: -f1)
    port=$(echo "$node" | cut -d: -f2)
    echo "Checking node $node ..."
    
    # 키 스캔 및 메모리 사용량 계산
    while read -r key; do
        if [ ! -z "$key" ]; then
            usage=$(redis-cli -c -h "$host" -p "$port" MEMORY USAGE "$key")
            if [ ! -z "$usage" ] && [ "$usage" -eq "$usage" ] 2>/dev/null; then
                total_sum=$((total_sum + usage))
            fi
        fi
    done < <(redis-cli -c -h "$host" -p "$port" --scan --pattern "$KEY_PATTERN")
done

# Get total Redis memory
total_mem=0
for node in $PRIMARY_NODES; do
    host=$(echo "$node" | cut -d: -f1)
    port=$(echo "$node" | cut -d: -f2)
    mem=$(redis-cli -c -h "$host" -p "$port" INFO MEMORY | grep used_memory: | cut -d':' -f2)
    if [ ! -z "$mem" ] && [ "$mem" -eq "$mem" ] 2>/dev/null; then
        total_mem=$((total_mem + mem))
    fi
done

if [ "$total_mem" -eq 0 ]; then
    echo "Error: 총 메모리 계산 실패"
    exit 1
fi

percent=$(echo "scale=2; $total_sum / $total_mem * 100" | bc)

echo ""
echo "Key pattern: $KEY_PATTERN"
echo "Total memory used by $KEY_PATTERN = $total_sum bytes"
echo "Total Redis cluster memory = $total_mem bytes"
echo "사용 비율: $percent%"