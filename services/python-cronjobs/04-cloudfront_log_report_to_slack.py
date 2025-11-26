import os
import boto3
import time
import pandas as pd
import pytz
from datetime import datetime
from slackbot import slack
from tabulate import tabulate

# AWS 및 Slack 설정
athena_client = boto3.client('athena')
s3_bucket = 'demo-cloudfront-logs'
database = 'demo_cloudfront_logs'
table_name = 'cloudfront_logs'  # Partition Projection을 사용하는 테이블 이름
SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID', 'C07A8FBE2Q6')

# 현재 시간 (KST 기준 어제 날짜)
kst = pytz.timezone('Asia/Seoul')
now = datetime.now(kst)
year = now.year
month = f"{now.month:02d}"
# day = f"{now.day - 1:02d}"  # 어제
day = f"{now.day-1:02d}"  # 어제

print(f"Running CloudFront usage report for {year}-{month}-{day}")

# Athena 쿼리 정의
query = f"""
SELECT 
  service, 
  cs_uri_stem, 
  cs_referer, 
  cs_host, 
  CONCAT(cs_host, cs_uri_stem) AS full_url,
  COUNT(*) AS request_count,
  ROUND(SUM(CAST(sc_bytes AS BIGINT)) * 1.0 / COUNT(*), 2) AS avg_bytes_per_request,
  SUM(CAST(sc_bytes AS BIGINT)) AS total_bytes
FROM {table_name}
WHERE year = '{year}'
  AND month = '{month}'
  AND day = '{day}'
GROUP BY cs_uri_stem, cs_referer, cs_host, service
ORDER BY total_bytes DESC
LIMIT 50
"""

# Athena 쿼리 실행
start_time = datetime.now()

response = athena_client.start_query_execution(
    QueryString=query,
    QueryExecutionContext={'Database': database},
    ResultConfiguration={'OutputLocation': f's3://{s3_bucket}/athena-results/'}
)

query_execution_id = response['QueryExecutionId']

# 쿼리 완료 대기
while True:
    query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
    status = query_status['QueryExecution']['Status']['State']
    if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
        break
    time.sleep(5)

end_time = datetime.now()

if status == 'SUCCEEDED':
    # 결과 받아오기
    result = athena_client.get_query_results(QueryExecutionId=query_execution_id)
    rows = result['ResultSet']['Rows']
    header = [col['VarCharValue'] for col in rows[0]['Data']]
    data = [[col.get('VarCharValue', None) for col in row['Data']] for row in rows[1:]]
    df = pd.DataFrame(data, columns=header)

    # 표로 변환
    report = tabulate(df, headers='keys', tablefmt='grid')

    # Slack 전송
    slack.files_upload_v2(
        SLACK_CHANNEL_ID,
        report,
        f"{year}-{month}-{day}-cloudfront_report.txt",
        "*CloudFront Usage Report*",
        (
            f"*Query Start Time:* {start_time}\n"
            f"*Query End Time:* {end_time}"
        )
    )
else:
    reason = query_status['QueryExecution']['Status'].get('StateChangeReason', 'No reason provided')
    print(f"Athena query failed or was cancelled. Reason: {reason}")
