#!/bin/bash

BOT_LOG=bot_test_local.log

# 1. 서버를 백그라운드로 실행
nohup go run .. > "$BOT_LOG" 2>&1 &
BOT_PID=$!
sleep 2 # 서버가 뜰 때까지 대기

echo "🚀 Started bot (PID: $BOT_PID) with mock environment variables for local testing."
echo "Environment:"
echo "- SKIP_SLACK_VERIFICATION: $SKIP_SLACK_VERIFICATION"
echo "- SLACK_BOT_TOKEN: ${SLACK_BOT_TOKEN:0:10}..."
echo "- GITHUB_TOKEN: ${GITHUB_TOKEN:0:10}..."
echo "- PORT: $PORT"
echo "- GITHUB_ORG: $GITHUB_ORG"
echo ""

# 2. curl로 실제 요청을 보냄
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8080/slack/commands" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "command=/devops-action&text=alwayz-infrastructure ci-infra-terraform-cloud.yml workspace_name test-workspace-$(date +%s) working_directory terraform/infra/aws project_name Alwayz&user_id=U079GPPGB1P&channel_id=C08133K6144")

BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo ""
echo "📋 Test result:"

if [ "$HTTP_CODE" = "200" ]; then
  if [ -z "$BODY" ]; then
    echo "ℹ️  200 OK but no response body."
  elif echo "$BODY" | grep -q "success"; then
    echo "✅ Success: $BODY"
  elif echo "$BODY" | grep -qi "bad credentials"; then
    echo "⚠️  Mock environment (fake token): $BODY"
  else
    echo "ℹ️  200 OK but unexpected response: $BODY"
  fi
elif [ "$HTTP_CODE" = "401" ]; then
  echo "❌ Unauthorized: Check your GitHub token."
elif [ "$HTTP_CODE" = "404" ]; then
  echo "❌ Not Found: Check if the workflow file and repo are correct."
elif [ "$HTTP_CODE" = "000" ]; then
  echo "❌ Bot not running or connection refused."
else
  echo "❌ Unexpected error (HTTP $HTTP_CODE): $BODY"
fi

echo ""
echo "📝 Bot log (last 10 lines):"
tail -n 10 "$BOT_LOG"

# 3. 서버 프로세스 종료
kill $BOT_PID 2>/dev/null
wait $BOT_PID 2>/dev/null

echo ""
echo "🛑 Bot process (PID: $BOT_PID) terminated."