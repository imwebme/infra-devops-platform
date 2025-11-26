#!/usr/bin/env python3

import json
import sys
import os
import urllib.request

def get_slack_channel_name(channel_id, slack_token):
    """Slack 채널 ID로 채널 이름을 가져옵니다."""
    url = "https://slack.com/api/conversations.list?exclude_archived=true&limit=1000"
    
    # HTTP 요청 준비
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {slack_token}")
    req.add_header("Content-Type", "application/json")
    
    try:
        # HTTP 요청 실행
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
        
        if not data.get("ok"):
            return {"error": f"Slack API error: {data.get('error', 'Unknown error')}"}
        
        channels = data.get("channels", [])
        for channel in channels:
            if channel.get("id") == channel_id:
                return {"channel_name": channel.get("name")}
        
        return {"error": f"Channel ID '{channel_id}' not found"}
        
    except Exception as e:
        return {"error": f"Failed to get channel name: {str(e)}"}

def main():
    # stdin에서 JSON 입력을 읽습니다
    input_data = json.loads(sys.stdin.read())
    
    # 입력에서 채널 ID를 가져옵니다
    channel_id = input_data.get("channel_id")
    
    slack_token = os.environ.get("SLACK_TOKEN")
    
    if not channel_id:
        result = {"error": "channel_id is required"}
    elif not slack_token:
        result = {"error": "SLACK_TOKEN environment variable is required"}
    else:
        result = get_slack_channel_name(channel_id, slack_token)
    
    # 결과를 stdout에 JSON으로 출력합니다
    print(json.dumps(result))

if __name__ == "__main__":
    main() 