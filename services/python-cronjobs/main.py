import sys
import logging
import colorlog
import argparse
import traceback
import requests
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
from utils.config import configs

ENABLE_SLACK = configs['enableSlack']

# 인자 파서 설정
parser = argparse.ArgumentParser()
parser.add_argument('--level', help='Set log level', default='INFO')
parser.add_argument('--name', help='Set job name', required=True)
parser.add_argument('--files', nargs='+', help='Python files to execute', required=True)
args = parser.parse_args()

# class SlackHandler(logging.Handler):
#     def __init__(self, channel, token):
#         logging.Handler.__init__(self)
#         self.channel = channel
#         self.token = token

#     def emit(self, record):
#         log_entry = self.format(record)
#         client = WebClient(token=self.token)
#         try:
#             response = client.chat_postMessage(
#                 channel=self.channel,
#                 text=log_entry
#             )
#         except SlackApiError as e:
#             print(f"Error sending message to Slack: {e.response['error']}")

class SlackHandler(logging.Handler):
    def __init__(self, webhook_url):
        logging.Handler.__init__(self)
        self.webhook_url = webhook_url

    def emit(self, record):
        log_entry = self.format(record)
        headers = {'Content-type': 'application/json'}
        data = {"text": log_entry}
        try:
            response = requests.post(self.webhook_url, headers=headers, json=data)
            response.raise_for_status()
        except requests.exceptions.HTTPError as err:
            print(f"Error sending message to Slack: {err}")

# 로그 설정
log_level = getattr(logging, args.level.upper(), None)
if not isinstance(log_level, int):
  raise ValueError(f'Invalid log level: {args.level}')

job_name = args.name


logger = logging.getLogger(__name__)
logger.setLevel(log_level)
stream_handler = logging.StreamHandler(stream=sys.stdout)

stream_fmt = colorlog.ColoredFormatter(
    f"[%(asctime)s] | [%(levelname)s] | [⏰] Python기반 CronJob 실행({job_name})\n%(message)s",
    datefmt="%m/%d/%Y, %I:%M:%S %p"
)

slack_fmt = logging.Formatter(
    f"*[%(asctime)s]* | *[%(levelname)s]* | *[⏰] Python기반 CronJob 실행({job_name})*\n[❌] %(message)s",
    datefmt="%m/%d/%Y, %I:%M:%S %p"
)

stream_handler.setFormatter(stream_fmt)
logger.addHandler(stream_handler)

# Slack 핸들러 추가
# slack_handler = SlackHandler(channel='C07A8FBE2Q6', token=configs['slackToken'])
if ENABLE_SLACK:
  slack_handler = SlackHandler(webhook_url=configs['slackWebhookUrl'])
  slack_handler.setFormatter(slack_fmt)
  slack_handler.setLevel(logging.ERROR)
  logger.addHandler(slack_handler)

# Slack 클라이언트 설정
slack_token = configs['slackToken']
client = WebClient(token=slack_token)

# 실행할 파이썬 파일들
python_files = args.files

for file in python_files:
  try:
    # 파이썬 파일 실행
    exec(open(file).read())
    logger.info(f'{file} executed successfully')
  except Exception as e:
    # 스택 추적 캡처
    stack_trace = traceback.format_exc()
    logger.error(f'Error executing {file}: {e}\n{stack_trace}')