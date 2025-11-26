import boto3
import time
import pandas as pd
import pytz
from datetime import datetime
from slackbot import slack
from tabulate import tabulate


# AWS 및 Slack 클라이언트 설정
athena_client = boto3.client('athena')
s3_client = boto3.client('s3')
s3_bucket = 'alwayz-services-alb-access-log'
database = 'alwayz_services_alb_access_log'  # 사용할 Athena 데이터베이스
slack_channel = 'C07BV72HKEG'  # Slack 채널 이

# 현재 시간
kst = pytz.timezone('Asia/Seoul')
now = datetime.now(kst)
year = now.year
month = now.month
day = now.day - 1  # 어제 날짜

print(f"Running ALB-related DTO cost analysis report for {year}-{month}-{day}")

# Athena 쿼리
query = f"""
WITH api_usage AS (
    SELECT alb_name,
           SPLIT_PART(request_url, '?', 1) AS request_path, 
           request_verb AS method,
           COUNT(*) AS request_count, 
           SUM(sent_bytes) AS total_sent_bytes
      FROM alb_access_logs_2024 
      WHERE year = {year}
        AND month = {month}
        AND day = {day}
      GROUP BY request_verb, alb_name, SPLIT_PART(request_url, '?', 1)
      ORDER BY total_sent_bytes DESC
      LIMIT 50
)
SELECT alb_name,
       request_path,
       method,
       request_count,
       total_sent_bytes,
       total_sent_bytes / request_count AS avg_sent_bytes_per_request
  FROM api_usage
"""

# 쿼리 실행 시간 기록
start_time = datetime.now()

# Athena 쿼리 실행
response = athena_client.start_query_execution(
    QueryString=query,
    QueryExecutionContext={'Database': database},
    ResultConfiguration={'OutputLocation': f's3://{s3_bucket}/'}
)

query_execution_id = response['QueryExecutionId']

# 쿼리 결과가 완료될 때까지 대기
while True:
    query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
    status = query_status['QueryExecution']['Status']['State']
    
    if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
        break
    time.sleep(5)

end_time = datetime.now()

if status == 'SUCCEEDED':
    # 쿼리 결과 가져오기
    result = athena_client.get_query_results(QueryExecutionId=query_execution_id)
    
    # 결과를 데이터프레임으로 변환
    rows = result['ResultSet']['Rows']
    header = [col['VarCharValue'] for col in rows[0]['Data']]
    data = [[col.get('VarCharValue', None) for col in row['Data']] for row in rows[1:]]
    df = pd.DataFrame(data, columns=header)

    # 데이터프레임을 테이블 형식의 문자열로 변환
    report = tabulate(df, headers='keys', tablefmt='grid')
    
    # Slack에 스니펫으로 업로드
    slack.files_upload_v2(slack_channel, report, f"{year}-{month}-{day}-alb_access_log_report.txt", "*ALB Access Log Report*", (
        f"*Query Start Time:* {start_time}\n"
        f"*Query End Time:* {end_time}"
    ))
else:
    # Athena 쿼리 실패 시 상태와 이유를 출력
    query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
    reason = query_status['QueryExecution']['Status'].get('StateChangeReason', 'No reason provided')
    print(f"Athena query failed or was cancelled. Reason: {reason}")