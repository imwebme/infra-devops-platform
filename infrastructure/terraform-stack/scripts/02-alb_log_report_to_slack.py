import boto3
import requests
import json
from slackbot import slack

# AWS 클라이언트 초기화
ec2_client = boto3.client('ec2')

# Slack Bot OAuth token 
SLACK_OAUTH_TOKEN = '(Slack에서 발급받은 OAuth 토큰으로 교체하세요)'
SLACK_CHANNEL_ID = '{Slack 채널 ID}' 

# Slack API URL
SLACK_API_URL = 'https://slack.com/api/chat.postMessage'

# EBS 상태가 Available인 볼륨들 조회
def get_available_volumes():
    response = ec2_client.describe_volumes(
        Filters=[
            {'Name': 'status', 'Values': ['available']}
        ]
    )
    return response['Volumes']

# Slack으로 메시지 전송 (첫 번째 메시지)
def send_first_slack_message(message):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {SLACK_OAUTH_TOKEN}',
    }

    data = {
        'channel_id': SLACK_CHANNEL_ID,
        'text': 'EBS Volumes in Available State',
        'blocks': message,
    }

    response = requests.post(SLACK_API_URL, headers=headers, data=json.dumps(data))
    response_json = response.json()

    if response_json.get('ok'):
        return response_json['ts']  # 첫 번째 메시지의 ts 반환
    else:
        print(f"Error sending message: {response_json.get('error')}")
        return None

# Slack으로 쓰레드 메시지 전송
def send_threaded_message(thread_ts, thread_message):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {SLACK_OAUTH_TOKEN}',
    }

    thread_payload = {
        'channel': SLACK_CHANNEL_ID,
        'text': 'Threaded EBS Volume Information',
        'thread_ts': thread_ts,  # 첫 메시지의 ts를 사용해 쓰레드로 연결
        'blocks': thread_message,
    }

    response = requests.post(SLACK_API_URL, headers=headers, data=json.dumps(thread_payload))
    response_json = response.json()

    if response_json.get('ok'):
        print("Threaded message sent successfully")
    else:
        print(f"Error sending threaded message: {response_json.get('error')}")

# EBS 볼륨 상태가 Available인 볼륨 목록을 조회하고 Slack으로 전송
def main():
    volumes = get_available_volumes()
    
    if volumes:
        # 첫 메시지: 타이틀과 개수만 표시
        message = [
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*EBS Volumes in 'Available' State:*"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Total Volumes:* {len(volumes)}"
                    }
                ]
            },
            {
                "type": "divider"
            }
        ]
        
        # 첫 번째 메시지를 보낸 후 타임스탬프를 받아옴
        thread_ts = send_first_slack_message(message)
        
        if thread_ts:
            print("First message sent successfully.")
            # 이후, 각 볼륨의 상세 정보를 쓰레드로 전달
            thread_message = []
            for volume in volumes:
                volume_info = {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*{volume['VolumeId']}* / `{volume['Size']} GiB`"
                        }
                    ]
                }
                thread_message.append(volume_info)

            # 쓰레드에 각 볼륨을 추가
            send_threaded_message(thread_ts, thread_message)
    else:
        message = [
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*No EBS volumes are in 'Available' state.*"
                    }
                ]
            }
        ]
        send_first_slack_message(message)

if __name__ == "__main__":
    main()
