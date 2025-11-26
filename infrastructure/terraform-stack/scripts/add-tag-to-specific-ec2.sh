for instance_id in $(aws ec2 describe-instances \
    --filters "Name=tag:engine,Values=mongodb" "Name=tag:Environment,Values=prod" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text); do

  # 기존 태그 가져오기
  EXISTING_TAGS=$(aws ec2 describe-tags \
      --filters "Name=resource-id,Values=$instance_id" \
      --query "Tags[].[Key,Value]" \
      --output json)

  # 새 태그 추가
  NEW_TAGS=$(echo $EXISTING_TAGS | jq -c '. += [["Env", "demo-prod"], ["ManagedBy", "Lim Jong Eun"], ["Group", "mongodb"], ["Team", "devops"]]' | jq -c '[.[] | {"Key": .[0], "Value": .[1]}]')

  # 태그 업데이트
  aws ec2 create-tags \
      --resources $instance_id \
      --tags "$NEW_TAGS"

  echo "Updated tags for instance: $instance_id"
done
