#!/bin/bash

# S3 버킷 이름
BUCKET_NAME="demo-services-alb-connection-log"

# S3 버킷 비우기
echo "Starting to empty bucket: $BUCKET_NAME"
aws s3 rm s3://$BUCKET_NAME --recursive --quiet

if [ $? -eq 0 ]; then
  echo "Successfully emptied bucket: $BUCKET_NAME"
else
  echo "Failed to empty bucket: $BUCKET_NAME"
fi
