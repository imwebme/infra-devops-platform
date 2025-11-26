# # 1. Name 태그만 출력
# aws ec2 describe-instances \
#     --filters "Name=tag-key,Values=aws:elasticmapreduce:instance-group-role,aws:elasticmapreduce:job-flow-id" \
#     --query "Reservations[].Instances[].Tags[?Key=='Name'].Value[]" \
#     --output text

# # 2. InstanceId와 Name 함께 출력
# aws ec2 describe-instances \
#     --filters "Name=tag-key,Values=aws:elasticmapreduce:instance-group-role,aws:elasticmapreduce:job-flow-id" \
#     --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name'].Value[]]" \
#     --output table

# # 3. Name 태그가 없는 경우 처리
# aws ec2 describe-instances \
#     --filters "Name=tag-key,Values=aws:elasticmapreduce:instance-group-role,aws:elasticmapreduce:job-flow-id" \
#     --query "Reservations[].Instances[].[InstanceId, (Tags[?Key=='Name'].Value[] | [0]) || 'No Name']" \
#     --output table

for instance_id in $(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*AIRFLOW*" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text); do

  # 기존 태그 가져오기
  EXISTING_TAGS=$(aws ec2 describe-tags \
      --filters "Name=resource-id,Values=$instance_id" \
      --query "Tags[].[Key,Value]" \
      --output json)

  # Get Group value from existing tags
  GROUP_VALUE=$(echo $EXISTING_TAGS | jq -r '.[] | select(.[0]=="Group") | .[1] // "unknown"')
  
  # Create new tags using the extracted Group value for Service
  NEW_TAGS=$(echo $EXISTING_TAGS | jq -c --arg group "$GROUP_VALUE" '. += [["Env", "data-prod"], ["ManagedBy", "Minsub Yim"], ["Group", "mlops"], ["Service", $group], ["Workload", "data-prod"], ["Environment", "prod"], ["Team", "data"]]' | jq -c '[.[] | {"Key": .[0], "Value": .[1]}]')

  # 태그 업데이트
  aws ec2 create-tags \
      --resources $instance_id \
      --tags "$NEW_TAGS"

  echo "Updated tags for instance: $instance_id"
done

