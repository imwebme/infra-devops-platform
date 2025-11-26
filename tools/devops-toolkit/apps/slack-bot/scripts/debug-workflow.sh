#!/bin/bash

# Debug script to check GitHub workflows
# Usage: ./debug-workflow.sh [your-github-token]

GITHUB_TOKEN=${1:-$GITHUB_TOKEN}

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Please provide GitHub token:"
    echo "   ./debug-workflow.sh YOUR_GITHUB_TOKEN"
    echo "   or set GITHUB_TOKEN environment variable"
    exit 1
fi

echo "🔍 Checking wetripod/alwayz-infrastructure workflows..."
echo ""

# List all workflows
echo "📋 Available workflows:"
curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/wetripod/alwayz-infrastructure/actions/workflows | \
    jq -r '.workflows[] | "- Name: \(.name)\n  Path: \(.path)\n  ID: \(.id)\n"' 2>/dev/null

echo ""
echo "🎯 Testing workflow dispatch..."

# Test workflow dispatch for the terraform cloud workflow
echo "Testing: ci-infra-terraform-cloud.yml"
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/workflow_response.txt \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/wetripod/alwayz-infrastructure/actions/workflows/ci-infra-terraform-cloud.yml/dispatches \
    -d '{
        "ref": "main",
        "inputs": {
            "workspace_name": "test-debug",
            "working_directory": "terraform/infra/aws",
            "project_name": "Alwayz"
        }
    }')

HTTP_CODE=${RESPONSE: -3}
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Workflow dispatch successful!"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ Workflow not found. Check workflow path."
    echo "   Try: '.github/workflows/ci-infra-terraform-cloud.yml'"
elif [ "$HTTP_CODE" = "422" ]; then
    echo "⚠️  Workflow found but dispatch failed. Response:"
    cat /tmp/workflow_response.txt
else
    echo "❌ Unexpected error. Response:"
    cat /tmp/workflow_response.txt
fi

rm -f /tmp/workflow_response.txt 