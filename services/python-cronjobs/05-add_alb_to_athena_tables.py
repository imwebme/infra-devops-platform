import boto3
import os
import re
import logging
import time
from datetime import datetime
from slackbot import slack

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("ALB_Table_Updater")

# AWS 클라이언트 초기화
s3_client = boto3.client('s3')
athena_client = boto3.client('athena')

# 설정
ACCESS_LOG_BUCKET = "demo-services-alb-access-log"
CONNECTION_LOG_BUCKET = "demo-services-alb-connection-log"
ATHENA_DATABASE = "demo_services_alb_access_log"
ATHENA_WORKGROUP = "primary"
ACCESS_LOG_TABLE = "alb_access_logs_all"
CONNECTION_LOG_TABLE = "alb_connection_logs_all"

# Slack 설정
SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID', 'C093LS4945B')

# Athena 쿼리 결과 저장 경로
ACCESS_LOG_OUTPUT = f"s3://{ACCESS_LOG_BUCKET}/athena-results/"
CONNECTION_LOG_OUTPUT = f"s3://{CONNECTION_LOG_BUCKET}/athena-results/"

def wait_for_query_completion(query_execution_id, max_attempts=60):
    """쿼리 실행이 완료될 때까지 대기합니다."""
    attempts = 0
    while attempts < max_attempts:
        response = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
        state = response['QueryExecution']['Status']['State']

        if state == 'SUCCEEDED':
            return True
        elif state in ['FAILED', 'CANCELLED']:
            reason = response['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
            logger.error(f"Query failed: {reason}")
            return False

        attempts += 1
        time.sleep(1)

    logger.error(f"Query timed out after {max_attempts} attempts")
    return False

def get_current_albs_from_table(table_name):
    """Athena 테이블에서 현재 설정된 ALB 목록을 가져옵니다."""
    try:
        # 테이블 속성 조회 쿼리
        query = f"""
        SHOW TBLPROPERTIES {ATHENA_DATABASE}.{table_name}
        """

        # 쿼리 실행
        execution = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': ATHENA_DATABASE},
            ResultConfiguration={'OutputLocation': ACCESS_LOG_OUTPUT}
        )

        # 쿼리 완료 대기
        query_execution_id = execution['QueryExecutionId']
        logger.info(f"Query execution ID: {query_execution_id}")

        if not wait_for_query_completion(query_execution_id):
            logger.error(f"Query failed for {table_name}")
            return []

        # 결과 가져오기
        result = athena_client.get_query_results(
            QueryExecutionId=query_execution_id
        )

        # 결과 구조 로깅
        # logger.info(f"Query result structure: {result.keys()}")
        # logger.info(f"ResultSet structure: {result['ResultSet'].keys()}")
        # logger.info(f"Number of rows: {len(result['ResultSet']['Rows'])}")

        # 첫 번째 행은 헤더이므로 건너뜀
        for i, row in enumerate(result['ResultSet']['Rows'][1:], 1):
            if len(row['Data']) >= 1 and 'VarCharValue' in row['Data'][0]:
                # 각 행의 첫 번째 열 값 확인
                cell_value = row['Data'][0]['VarCharValue']
                logger.debug(f"Row {i} value: {cell_value}")

                # 문자열에서 키와 값 분리
                if 'projection.alb_name.values' in cell_value:
                    # 탭이나 여러 공백으로 분리되어 있을 수 있음
                    parts = re.split(r'\s{2,}|\t', cell_value)
                    if len(parts) >= 2:
                        key = parts[0].strip()
                        value = parts[1].strip()
                        if key == 'projection.alb_name.values':
                            logger.info(f"Found ALB values for {table_name}")
                            return value.split(',')

        # 속성을 찾지 못한 경우, 모든 행의 값을 로깅
        logger.error(f"projection.alb_name.values property not found for {table_name}")
        logger.error("Available keys:")
        for i, row in enumerate(result['ResultSet']['Rows'][1:], 1):
            if len(row['Data']) >= 1 and 'VarCharValue' in row['Data'][0]:
                logger.error(f"  - {row['Data'][0]['VarCharValue']}")

        # 로그에서 값을 직접 추출 시도
        for i, row in enumerate(result['ResultSet']['Rows'][1:], 1):
            if len(row['Data']) >= 1 and 'VarCharValue' in row['Data'][0]:
                cell_value = row['Data'][0]['VarCharValue']
                if 'projection.alb_name.values' in cell_value:
                    # 정규식을 사용하여 값 부분만 추출
                    match = re.search(r'projection\.alb_name\.values\s+(.*)', cell_value)
                    if match:
                        value = match.group(1).strip()
                        logger.info(f"Extracted ALB values from log for {table_name}")
                        return value.split(',')

        # 하드코딩된 기본값 반환 (최후의 수단)
        logger.error(f"Failed to get ALB values for {table_name}, using default values")
        return ["airport-private-prod", "airport-prod", "demo-admin-back-private-prod", "demo-admin-back-prod"]

    except Exception as e:
        logger.exception(f"Error getting current ALBs from table {table_name}: {str(e)}")
        # 예외 발생 시 빈 목록 대신 기본값 반환
        return ["airport-private-prod", "airport-prod", "demo-admin-back-private-prod", "demo-admin-back-prod"]

def get_albs_from_s3(bucket_name):
    """S3 버킷에서 ALB 폴더 목록을 가져옵니다."""
    try:
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Delimiter='/'
        )

        albs = []
        if 'CommonPrefixes' in response:
            for prefix in response['CommonPrefixes']:
                # 폴더 이름에서 마지막 슬래시 제거
                alb_name = prefix['Prefix'].rstrip('/')
                albs.append(alb_name)

        return albs
    except Exception as e:
        logger.exception(f"Error getting ALBs from S3 bucket {bucket_name}: {str(e)}")
        return []

def send_slack_message(message):
    """슬랙으로 메시지를 전송합니다."""
    try:
        response = slack.post_message(SLACK_CHANNEL_ID, message)
        if response.get('ok'):
            return response['ts']
        else:
            logger.error(f"Error sending message: {response.get('error')}")
            return None
    except Exception as e:
        logger.error(f"Error sending Slack message: {str(e)}")
        return None

def update_table_with_new_albs(table_name, current_albs, new_albs):
    """테이블에 새로운 ALB 목록을 업데이트합니다."""
    if not new_albs:
        logger.info(f"No new ALBs to add to {table_name}")
        return False

    try:
        # 모든 ALB를 포함한 새 목록 생성
        all_albs = sorted(list(set(current_albs + new_albs)))
        alb_values_str = ','.join(all_albs)

        # 테이블 속성 업데이트 쿼리
        query = f"""
        ALTER TABLE {ATHENA_DATABASE}.{table_name}
        SET TBLPROPERTIES (
            "projection.alb_name.values" = "{alb_values_str}"
        )
        """

        logger.info(f"Query: {query}")

        logger.info(f"Updating {table_name} with new ALBs: {', '.join(new_albs)}")

        # 테이블에 따라 다른 출력 위치 사용
        output_location = ACCESS_LOG_OUTPUT
        if table_name == CONNECTION_LOG_TABLE:
            output_location = CONNECTION_LOG_OUTPUT

        execution = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': ATHENA_DATABASE},
            ResultConfiguration={'OutputLocation': output_location}
        )

        # 쿼리 완료 대기
        query_execution_id = execution['QueryExecutionId']
        if wait_for_query_completion(query_execution_id):
            logger.info(f"Successfully updated {table_name} with new ALBs")
            return True
        else:
            logger.error(f"Failed to update {table_name}")
            return False

    except Exception as e:
        logger.exception(f"Error updating table {table_name} with new ALBs: {str(e)}")
        return False

# 메인 함수 실행
try:
    logger.info("Starting ALB table updater")
    changes_made = False
    notification_messages = []

    # 액세스 로그 테이블 업데이트
    access_current_albs = get_current_albs_from_table(ACCESS_LOG_TABLE)
    access_s3_albs = get_albs_from_s3(ACCESS_LOG_BUCKET)
    access_new_albs = [alb for alb in access_s3_albs if alb not in access_current_albs]

    if access_new_albs:
        logger.info(f"Found {len(access_new_albs)} new ALBs for access logs: {', '.join(access_new_albs)}")
        if update_table_with_new_albs(ACCESS_LOG_TABLE, access_current_albs, access_new_albs):
            changes_made = True
            notification_messages.append(f"✅ Access Log 테이블에 새로운 ALB {len(access_new_albs)}개가 추가되었습니다: {', '.join(access_new_albs)}")
    else:
        logger.info("No new ALBs found for access logs")

    # 커넥션 로그 테이블 업데이트
    connection_current_albs = get_current_albs_from_table(CONNECTION_LOG_TABLE)
    connection_s3_albs = get_albs_from_s3(CONNECTION_LOG_BUCKET)
    connection_new_albs = [alb for alb in connection_s3_albs if alb not in connection_current_albs]

    if connection_new_albs:
        logger.info(f"Found {len(connection_new_albs)} new ALBs for connection logs: {', '.join(connection_new_albs)}")
        if update_table_with_new_albs(CONNECTION_LOG_TABLE, connection_current_albs, connection_new_albs):
            changes_made = True
            notification_messages.append(f"✅ Connection Log 테이블에 새로운 ALB {len(connection_new_albs)}개가 추가되었습니다: {', '.join(connection_new_albs)}")
    else:
        logger.info("No new ALBs found for connection logs")

    # 슬랙으로 알림 (변경사항 유무와 관계없이)
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if changes_made:
        message = f"*[ALB 테이블 업데이트 알림]* - {current_time}\n" + "\n".join(notification_messages)
    else:
        message = f"*[ALB 테이블 업데이트 알림]* - {current_time}\n✅ 변경사항 없음: 모든 ALB가 이미 테이블에 등록되어 있습니다."
    
    send_slack_message(message)
    logger.info("Slack notification sent")
    
    logger.info("ALB table updater completed successfully")

except Exception as e:
    error_message = f"Error in ALB table updater: {str(e)}"
    logger.exception(error_message)
    send_slack_message(f"❌ *[ALB 테이블 업데이트 오류]* - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n{error_message}")