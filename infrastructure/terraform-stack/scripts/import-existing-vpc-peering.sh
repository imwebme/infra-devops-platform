#!/bin/bash

echo "=== VPC Peering Import 스크립트 ==="
echo "이 스크립트는 기존 환경의 VPC peering을 Terraform state로 import합니다."

# 환경 확인
VALID_WORKSPACES="alwayz-aws-prod-infra|aws-data-prod-infra|security-aws-prod-infra|alwayz-aws-staging-infra|alwayz-aws-dev-infra|aws-data-dev-infra"
if [[ ! "$1" =~ ^($VALID_WORKSPACES)$ ]]; then
    echo "❌ 사용법: $0 [workspace]"
    echo "지원되는 workspace:"
    echo "  - alwayz-aws-prod-infra"
    echo "  - aws-data-prod-infra" 
    echo "  - security-aws-prod-infra"
    echo "  - alwayz-aws-staging-infra"
    echo "  - alwayz-aws-dev-infra"
    echo "  - aws-data-dev-infra"
    exit 1
fi

WORKSPACE=$1
echo "🔧 Workspace: $WORKSPACE"

# Terraform workspace 설정
terraform workspace select $WORKSPACE
if [ $? -ne 0 ]; then
    echo "❌ Workspace $WORKSPACE 선택 실패"
    exit 1
fi

# VPC ID 가져오기
VPC_ID=$(terraform show -json | jq -r '.values.root_module.child_modules[] | select(.address == "module.vpc") | .resources[] | select(.type == "aws_vpc") | .values.id')
if [ -z "$VPC_ID" ]; then
    echo "❌ VPC ID를 찾을 수 없습니다"
    exit 1
fi
echo "📍 Current VPC ID: $VPC_ID"

# 현재 VPC CIDR 가져오기
CURRENT_VPC_CIDR=$(terraform show -json | jq -r '.values.root_module.child_modules[] | select(.address == "module.vpc") | .resources[] | select(.type == "aws_vpc") | .values.cidr_block')
echo "🌐 Current VPC CIDR: $CURRENT_VPC_CIDR"

# Route Table ID들 가져오기
PRIVATE_RT_IDS=$(terraform show -json | jq -r '.values.root_module.child_modules[] | select(.address == "module.vpc") | .resources[] | select(.type == "aws_route_table" and (.values.tags.Name | contains("private"))) | .values.id')

echo "📋 설정에서 peering 목록 확인 중..."

# Terraform plan을 실행해서 설정된 peering 목록 확인
terraform plan -out=temp.tfplan > /dev/null 2>&1
PLANNED_PEERINGS=$(terraform show -json temp.tfplan | jq -r '.planned_values.root_module.resources[] | select(.type == "aws_vpc_peering_connection") | .name + "[\"" + .index + "\"]"' 2>/dev/null || echo "")
rm -f temp.tfplan

if [ -z "$PLANNED_PEERINGS" ]; then
    echo "⚠️  설정된 VPC peering이 없습니다."
    exit 0
fi

echo "🔗 설정된 peering 목록:"
echo "$PLANNED_PEERINGS"

# 각 설정된 peering에 대해 기존 연결 확인 및 import
while IFS= read -r peering_resource; do
    if [ -z "$peering_resource" ]; then
        continue
    fi
    
    echo ""
    echo "🔍 처리 중: $peering_resource"
    
    # 리소스 이름에서 connection name 추출
    CONN_NAME=$(echo "$peering_resource" | sed 's/.*\["\(.*\)"\].*/\1/')
    echo "  Connection: $CONN_NAME"
    
    # 설정에서 해당 connection의 peer VPC ID 찾기
    PEER_VPC_ID=$(terraform console <<< "local.config.vpc_peering.connections" | jq -r --arg name "$CONN_NAME" '.[] | select(.name == $name) | .peer_vpc_id' 2>/dev/null || echo "")
    
    if [ -z "$PEER_VPC_ID" ] || [ "$PEER_VPC_ID" = "null" ]; then
        echo "  ⚠️  설정에서 peer VPC ID를 찾을 수 없습니다."
        continue
    fi
    
    echo "  Peer VPC ID: $PEER_VPC_ID"
    
    # 기존 peering connection 찾기
    PEERING_ID=$(aws ec2 describe-vpc-peering-connections \
        --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" \
                  "Name=accepter-vpc-info.vpc-id,Values=$PEER_VPC_ID" \
                  "Name=status-code,Values=active" \
        --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
        --output text)

    if [ "$PEERING_ID" = "None" ] || [ -z "$PEERING_ID" ]; then
        # 반대 방향도 확인
        PEERING_ID=$(aws ec2 describe-vpc-peering-connections \
            --filters "Name=requester-vpc-info.vpc-id,Values=$PEER_VPC_ID" \
                      "Name=accepter-vpc-info.vpc-id,Values=$VPC_ID" \
                      "Name=status-code,Values=active" \
            --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
            --output text)
    fi

    if [ "$PEERING_ID" = "None" ] || [ -z "$PEERING_ID" ]; then
        echo "  ⚠️  기존 peering connection을 찾을 수 없습니다. 새로 생성됩니다."
        continue
    fi
    
    echo "  🔗 기존 Peering ID: $PEERING_ID"
    
    # VPC Peering Connection import
    echo "  📥 VPC Peering Connection import 중..."
    terraform import "aws_vpc_peering_connection.this[\"$CONN_NAME\"]" "$PEERING_ID"
    
    # 라우팅 규칙 import (peer CIDR 필요)
    PEER_CIDR=$(terraform console <<< "local.config.vpc_peering.connections" | jq -r --arg name "$CONN_NAME" '.[] | select(.name == $name) | .peer_cidr' 2>/dev/null || echo "")
    
    if [ -n "$PEER_CIDR" ] && [ "$PEER_CIDR" != "null" ]; then
        echo "  🛣️  라우팅 규칙 import 중... (CIDR: $PEER_CIDR)"
        
        # Current VPC -> Peer VPC 라우팅 규칙들 import
        for RT_ID in $PRIVATE_RT_IDS; do
            echo "    Route Table: $RT_ID"
            terraform import "aws_route.to_peer[\"${CONN_NAME}-${RT_ID}\"]" "${RT_ID}_${PEER_CIDR}" 2>/dev/null || echo "    ⚠️  라우팅 규칙이 없거나 이미 import됨"
        done
        
        # Cross-region (us-east-1)인 경우 반대 방향 라우팅도 import
        PEER_REGION=$(terraform console <<< "local.config.vpc_peering.connections" | jq -r --arg name "$CONN_NAME" '.[] | select(.name == $name) | .peer_region' 2>/dev/null || echo "")
        
        if [ "$PEER_REGION" = "us-east-1" ]; then
            echo "    Datadog VPC -> Current VPC 라우팅 규칙 import 중..."
            DATADOG_MAIN_RT=$(aws ec2 describe-route-tables \
                --filters "Name=vpc-id,Values=$PEER_VPC_ID" \
                          "Name=association.main,Values=true" \
                --region us-east-1 \
                --query 'RouteTables[0].RouteTableId' \
                --output text)
                
            if [ "$DATADOG_MAIN_RT" != "None" ] && [ -n "$DATADOG_MAIN_RT" ]; then
                terraform import "aws_route.from_virginia[\"$CONN_NAME\"]" "${DATADOG_MAIN_RT}_${CURRENT_VPC_CIDR}" 2>/dev/null || echo "    ⚠️  Datadog 라우팅 규칙이 없거나 이미 import됨"
            fi
        fi
    fi
    
done <<< "$PLANNED_PEERINGS"

echo ""
echo "✅ Import 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. terraform plan으로 변경사항 확인"
echo "2. terraform apply로 나머지 리소스 생성"
echo ""
echo "🔍 확인 명령어:"
echo "terraform state list | grep -E '(peering|route)'" 