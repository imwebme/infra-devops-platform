import requests
import argparse
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# PagerDuty API 및 Slack 설정
PAGERDUTY_API_KEY = "PAGERDUTY API KEY를 입력하세요"
SLACK_BOT_TOKEN = "SLACK TOKEN을 입력하세요"

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

            oncall_users.append({
                "user": user,
                "schedule": schedule,
                "escalation_policy": escalation_policy,
                "start": start_time,
                "end": end_time
            })

        return oncall_users

    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching on-call users: {e}")
        return []

def send_slack_message(channel, oncall_users):
    """Slack 채널에 On-Call 정보를 메시지로 전송"""
    slack_client = WebClient(token=SLACK_BOT_TOKEN)

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
        response = slack_client.chat_postMessage(channel=channel, text=message)
        if response["ok"]:
            print(f"✅ Successfully sent On-Call message to {channel}")
        else:
            print(f"⚠️ Failed to send message: {response['error']}")

    except SlackApiError as e:
        print(f"❌ Slack API Error: {e.response['error']}")

def parse_arguments():
    """CLI 인자 파싱"""
    parser = argparse.ArgumentParser(description="Fetch PagerDuty On-Call users and notify Slack")
    parser.add_argument('-c', '--channel', required=True, help="Slack 채널 (예: #alerts)")
    return parser.parse_args()

def run():
    """메인 실행 함수"""
    args = parse_arguments()
    oncall_users = get_oncall_users()
    send_slack_message(args.channel, oncall_users)

if __name__ == "__main__":
    run()
