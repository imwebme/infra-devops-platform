import os
import requests
import pytz
from datetime import datetime
from slackbot import slack
from slack_sdk.errors import SlackApiError
from utils.config import configs

# PagerDuty API 및 Slack 설정
PAGERDUTY_API_KEY = configs['pagerdutyApiKey']
SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID', 'C07A8FBE2Q6')

# KST 시간대 설정
KST = pytz.timezone('Asia/Seoul')

# PagerDuty API 요청 헤더
HEADERS = {
    "Accept": "application/json",
    "Authorization": f"Token token={PAGERDUTY_API_KEY}",
    "Content-Type": "application/json"
}

def get_oncall_users():
    """PagerDuty에서 현재 On-Call 담당자 목록을 가져옴"""
    url = "https://api.pagerduty.com/oncalls"

    try:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()  # HTTP 오류 발생 시 예외 처리
        data = response.json()

        oncall_users = []
        for entry in data.get("oncalls", []):
            user = entry["user"]["summary"]
            schedule = entry["schedule"]["summary"]
            escalation_policy = entry["escalation_policy"]["summary"]
            start_time = entry["start"]
            end_time = entry["end"]
            
            # UTC -> KST 변환
            start_time_utc = datetime.strptime(start_time, "%Y-%m-%dT%H:%M:%SZ")
            end_time_utc = datetime.strptime(end_time, "%Y-%m-%dT%H:%M:%SZ")
            
            start_time_kst = pytz.utc.localize(start_time_utc).astimezone(KST).strftime("%Y-%m-%d %H:%M")
            end_time_kst = pytz.utc.localize(end_time_utc).astimezone(KST).strftime("%Y-%m-%d %H:%M")

            oncall_users.append({
                "user": user,
                "schedule": schedule,
                "escalation_policy": escalation_policy,
                "start": start_time_kst,
                "end": end_time_kst
            })

        return oncall_users

    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching on-call users: {e}")
        return []

def send_slack_message(channel, oncall_users):
    """Slack 채널에 On-Call 정보를 메시지로 전송"""

    if not oncall_users:
        message = "🚨 현재 On-Call 담당자가 없습니다."
    else:
        message = "*📢 현재 On-Call 담당자 목록:*\n"
        for user in oncall_users:
            message += f"👤 *{user['user']}*\n"
            message += f"📅 일정: {user['schedule']}\n"
            message += f"📢 에스컬레이션 정책: {user['escalation_policy']}\n"
            message += f"🕒 시간: {user['start']} ~ {user['end']}\n"
            message += "--------------------------------------\n"

    try:
        response = slack.post_message(channel_id=channel, text=message)
        if response["ok"]:
            print(f"✅ Successfully sent On-Call message to {channel}")
        else:
            print(f"❌ Failed to send message: {response['error']}")

    except SlackApiError as e:
        print(f"❌ Slack API Error: {e.response['error']}")

def run():
    """메인 실행 함수"""
    oncall_users = get_oncall_users()
    send_slack_message(SLACK_CHANNEL_ID, oncall_users)

run()