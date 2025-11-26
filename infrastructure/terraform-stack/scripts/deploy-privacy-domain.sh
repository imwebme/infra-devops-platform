#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WORKSPACE="demo-aws-prod-infra"
TERRAFORM_DIR="/Users/example-org/workspace/infra/demo-infrastructure/terraform/infra/aws"

echo -e "${GREEN}🚀 Updating privacy.iexample-org.com domain configuration${NC}"

cd "$TERRAFORM_DIR"

echo -e "${YELLOW}🔧 Selecting workspace: $WORKSPACE${NC}"
terraform workspace select "$WORKSPACE"

echo -e "${YELLOW}📋 Planning changes...${NC}"
terraform plan

echo -e "${YELLOW}❓ Apply changes? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 1
fi

echo -e "${YELLOW}🚀 Applying changes...${NC}"
terraform apply -auto-approve

echo -e "${GREEN}✅ Complete! privacy.iexample-org.com is now configured${NC}"
