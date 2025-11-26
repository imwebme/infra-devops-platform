#!/bin/bash
# redis-cli -c -h demo-prod-demo-back-valkey8.quw73o.clustercfg.apn2.cache.amazonaws.com:6379 cluster slots > redis-slots.txt
# redis-cli --cluster call 10.2.195.185:6379 CLUSTER GETKEYSINSLOT 50 10 > redis-report-key.txt
REDIS_HOST="demo-prod-demo-back-valkey8.quw73o.clustercfg.apn2.cache.amazonaws.com"

echo "Checking Redis keys without TTL and their memory usage..."
echo "FORMAT: Key | Memory Size | Type"
echo "----------------------------------------"

redis-cli -h $REDIS_HOST -c --scan | while read key; do
  ttl=$(redis-cli -h $REDIS_HOST -c TTL "$key")
  # 숫자만 추출하여 비교
  ttl_num=$(echo "$ttl" | grep -E '^-?[0-9]+$')
  
  if [[ ! -z "$ttl_num" ]] && [[ $ttl_num -eq -1 ]]; then
    # Get memory usage for the key
    memory=$(redis-cli -h $REDIS_HOST -c MEMORY USAGE "$key")
    # Get key type
    type=$(redis-cli -h $REDIS_HOST -c TYPE "$key")
    # Convert bytes to human readable format
    if [ $memory -ge 1048576 ]; then
      memory_readable=$(echo "scale=2; $memory/1048576" | bc)" MB"
    elif [ $memory -ge 1024 ]; then
      memory_readable=$(echo "scale=2; $memory/1024" | bc)" KB"
    else
      memory_readable="$memory B"
    fi
    echo "$key | $memory_readable | $type"
  fi
done | head -n 50

echo "----------------------------------------"
echo "Note: Showing only first 50 results"