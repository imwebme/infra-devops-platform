# =============================================================================
# AWS COST REPORT CRON JOB (ARCHIVED)
# =============================================================================
# This cron job has been archived and is currently disabled.
# 
# ARCHIVE REASON: Slack notifications disabled, cron execution paused
# ARCHIVE DATE: Current session
# 
# TO RESTORE:
# 1. Uncomment the main() function execution code
# 2. Remove the early return guard in main()
# 3. Optionally restore Slack functionality from archived sections
# 4. Update your cron scheduler to re-enable execution
#
# =============================================================================

import boto3
import os
# ARCHIVED: Slack functionality temporarily disabled
# from slackbot import slack
import pandas as pd
from tabulate import tabulate
import pytz
from datetime import datetime, timedelta
import time
import math

# AWS 클라이언트 초기화
athena_client = boto3.client('athena')

# 환경 변수 설정
# ARCHIVED: Slack channel ID temporarily disabled
# SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID', 'C07A8FBE2Q6')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'vpc_flow_logs_db')
ATHENA_OUTPUT_LOCATION = os.getenv('ATHENA_OUTPUT_LOCATION', 's3://example-org-devops/report/')

def execute_athena_query(query, database):
    try:
        print("\nExecuting query:")
        print(query)  # 실제 실행되는 쿼리 출력
        
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': database},
            ResultConfiguration={'OutputLocation': ATHENA_OUTPUT_LOCATION}
        )
        
        query_execution_id = response['QueryExecutionId']
        print(f"Query execution ID: {query_execution_id}")
        
        # 쿼리 완료 대기 (최대 300초로 증가)
        for _ in range(300):  # 120초에서 300초로 증가
            response = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
            state = response['QueryExecution']['Status']['State']
            
            if state == 'FAILED':
                error_details = response['QueryExecution']['Status'].get('StateChangeReason', 'No error details available')
                print(f"Query failed. Error details: {error_details}")
                return pd.DataFrame()
                
            if state == 'SUCCEEDED':
                print("Query completed successfully")
                response = athena_client.get_query_results(QueryExecutionId=query_execution_id)
                # 결과를 DataFrame으로 변환
                columns = [col['Label'] for col in response['ResultSet']['ResultSetMetadata']['ColumnInfo']]
                data = []
                for row in response['ResultSet']['Rows'][1:]:  # Skip header
                    data.append([field.get('VarCharValue', '') for field in row['Data']])
                df = pd.DataFrame(data, columns=columns)
                print(f"\nQuery results shape: {df.shape}")  # 결과 크기 출력
                return df
            
            if state == 'CANCELLED':
                print("Query was cancelled")
                return pd.DataFrame()
                
            print(f"Query state: {state}, waiting... (Attempt {_+1}/300)")
            time.sleep(1)
        
        print("Query timed out after 300 seconds")
        return pd.DataFrame()
        
    except Exception as e:
        print(f"Error executing Athena query: {str(e)}")
        print(f"Full error details: {e.__dict__}")
        return pd.DataFrame()

def format_bytes(bytes_value):
    """바이트 값을 적절한 단위(MB, GB, TB)로 변환"""
    try:
        bytes_value = float(bytes_value)
        if bytes_value == 0:
            return "0 B"
        units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
        k = 1024.0
        i = int(math.floor(math.log(bytes_value, k)))
        if i >= len(units):
            i = len(units) - 1
        return f"{bytes_value / (k**i):.2f} {units[i]}"
    except (ValueError, TypeError):
        return "0 B"

def get_data_transfer_metrics():
    kst = pytz.timezone('Asia/Seoul')
    today = datetime.now(kst)
    yesterday = today - timedelta(days=1)
    
    query_params = {
        'year': today.year,
        'month': today.month,
        'day': today.day,
        'prev_year': yesterday.year,
        'prev_month': yesterday.month,
        'prev_day': yesterday.day
    }

    print(f"Querying for dates: Today={today.date()}, Yesterday={yesterday.date()}")

    # 전일 대비 총 트래픽 변화량 쿼리
    traffic_comparison_query = """
    WITH today AS (
        SELECT 
            CAST(SUM(bytes) AS DOUBLE) / POWER(1024, 3) as total_gb,
            COUNT(DISTINCT srcaddr) as unique_sources,
            COUNT(DISTINCT dstaddr) as unique_destinations
        FROM vpc_flow_logs
        WHERE year = {year} AND month = {month} AND day = {prev_day}
    ),
    yesterday AS (
        SELECT 
            CAST(SUM(bytes) AS DOUBLE) / POWER(1024, 3) as total_gb,
            COUNT(DISTINCT srcaddr) as unique_sources,
            COUNT(DISTINCT dstaddr) as unique_destinations
        FROM vpc_flow_logs
        WHERE year = {prev_year} AND month = {prev_month} AND day = {prev_day}
    )
    SELECT 
        today.total_gb as today_gb,
        yesterday.total_gb as yesterday_gb,
        ((today.total_gb - yesterday.total_gb) / NULLIF(yesterday.total_gb, 0) * 100) as change_percentage,
        today.unique_sources as today_unique_sources,
        today.unique_destinations as today_unique_destinations
    FROM today, yesterday
    """.format(**query_params)
    
    traffic_comparison_df = execute_athena_query(traffic_comparison_query, DATABASE_NAME)
    print("\nQuery results:")
    print(traffic_comparison_df)
    
    if traffic_comparison_df.empty:
        print("Warning: No results returned from traffic comparison query")
    else:
        print("\nTraffic comparison details:")
        print(f"Today's GB: {traffic_comparison_df['today_gb'].iloc[0]}")
        print(f"Yesterday's GB: {traffic_comparison_df['yesterday_gb'].iloc[0]}")
        print(f"Change percentage: {traffic_comparison_df['change_percentage'].iloc[0]}%")

    # 소스 IP별 송신 트래픽
    source_ips_query = """
    SELECT 
        srcaddr AS ip,
        CAST(SUM(bytes) AS DOUBLE) as total_bytes_sent,
        COUNT(*) as request_count
    FROM vpc_flow_logs
    WHERE year = {year} AND month = {month} AND day = {prev_day}
    GROUP BY srcaddr
    ORDER BY total_bytes_sent DESC
    LIMIT 10
    """.format(**query_params)

    # 대상 IP별 수신 트래픽
    dest_ips_query = """
    SELECT 
        dstaddr AS ip,
        CAST(SUM(bytes) AS DOUBLE) as total_bytes_received,
        COUNT(*) as request_count
    FROM vpc_flow_logs
    WHERE year = {year} AND month = {month} AND day = {prev_day}
    GROUP BY dstaddr
    ORDER BY total_bytes_received DESC
    LIMIT 10
    """.format(**query_params)

    # 인스턴스별 트래픽
    instance_traffic_query = """
    SELECT 
        instance_id,
        srcaddr,
        CAST(SUM(bytes) AS DOUBLE) as total_bytes,
        SUM(packets) as total_packets
    FROM vpc_flow_logs
    WHERE year = {year} 
        AND month = {month} 
        AND day = {prev_day}
        AND instance_id <> '-'
    GROUP BY instance_id, srcaddr
    ORDER BY total_bytes DESC
    LIMIT 20
    """.format(**query_params)

    # 인스턴스별 인바운드/아웃바운드 트래픽 쿼리 추가
    instance_direction_query = """
    SELECT 
        instance_id,
        flow_direction,
        CAST(SUM(bytes) AS DOUBLE) as total_bytes,
        COUNT(*) as connection_count
    FROM vpc_flow_logs
    WHERE year = {year} 
        AND month = {month} 
        AND day = {prev_day}
        AND instance_id <> '-'
    GROUP BY instance_id, flow_direction
    ORDER BY instance_id, flow_direction
    """.format(**query_params)

    # IP 쌍별 트래픽 쿼리 추가
    ip_pairs_query = """
    SELECT
        action,
        interface_id,
        instance_id,
        flow_direction,
        log_status,
        srcaddr,
        srcport,  
        dstaddr,
        dstport,
        protocol,
        CAST(SUM(bytes) AS DOUBLE) AS total_bytes
    FROM vpc_flow_logs
    WHERE year = {year}
        AND month = {month}
        AND day = {prev_day}
        AND instance_id <> '-'
    GROUP BY action, interface_id, instance_id, flow_direction, log_status, 
             srcaddr, srcport, dstaddr, dstport, protocol
    ORDER BY total_bytes DESC
    LIMIT 50
    """.format(**query_params)

    results = {
        'traffic_comparison': traffic_comparison_df,
        'top_source_ips': execute_athena_query(source_ips_query, DATABASE_NAME),
        'top_dest_ips': execute_athena_query(dest_ips_query, DATABASE_NAME),
        'instance_traffic': execute_athena_query(instance_traffic_query, DATABASE_NAME),
        'instance_direction': execute_athena_query(instance_direction_query, DATABASE_NAME),
        'ip_pairs': execute_athena_query(ip_pairs_query, DATABASE_NAME)
    }

    # 바이트 형식 변환 적용
    for df_name in ['top_source_ips', 'top_dest_ips', 'instance_traffic', 
                   'instance_direction', 'ip_pairs']:
        if not results[df_name].empty:
            byte_columns = [col for col in results[df_name].columns if 'bytes' in col.lower()]
            for col in byte_columns:
                results[df_name][col] = results[df_name][col].apply(format_bytes)

    return results

def calculate_data_transfer_cost(gb_amount):
    """
    AWS 데이터 전송 비용 계산 (ap-northeast-2 리전 기준)
    - 처음 10TB(=10240GB): $0.126/GB
    - 다음 40TB(=40960GB): $0.122/GB
    - 다음 100TB(=102400GB): $0.117/GB
    - 150TB 초과: $0.108/GB
    (100GB 무료 구간은 무시)
    """
    if gb_amount <= 10240:  # 10TB 이하
        return gb_amount * 0.126
    elif gb_amount <= 51200:  # 10TB-50TB
        return (10240 * 0.126) + ((gb_amount - 10240) * 0.122)
    elif gb_amount <= 153600:  # 50TB-150TB
        return (10240 * 0.126) + (40960 * 0.122) + ((gb_amount - 51200) * 0.117)
    else:  # 150TB 초과
        return (10240 * 0.126) + (40960 * 0.122) + (102400 * 0.117) + ((gb_amount - 153600) * 0.108)

def format_slack_message(metrics):
    try:
        kst = pytz.timezone('Asia/Seoul')
        yesterday = (datetime.now(kst) - timedelta(days=1)).strftime('%Y-%m-%d')
        
        if metrics['traffic_comparison'].empty:
            message = [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": f"📊 AWS 비용 리포트 ({yesterday} 기준)"
                    }
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "⚠️ *데이터를 가져오는데 실패했습니다.*"
                    }
                }
            ]
            return message

        message = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"📊 AWS 비용 리포트 ({yesterday} 기준)"
                }
            },
            {
                "type": "divider"
            },
            # 1. 전체 비용 요약
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*💰 전체 비용 요약*"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*직전달 총비용*\n_데이터 수집 예정_"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*직전일 총비용*\n_데이터 수집 예정_"
                    }
                ]
            },
            {
                "type": "divider"
            },
            # 2. 주간 비용 분석
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*📅 주간 비용 분석*"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*2주 전 평균*\n_데이터 수집 예정_"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*지난주 평균*\n_데이터 수집 예정_"
                    }
                ]
            },
            {
                "type": "divider"
            },
            # 3. Top 10 지출 카테고리
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*🏆 상위 지출 카테고리 TOP 10*\n" +
                           "1️⃣ EC2: _데이터 수집 예정_\n" +
                           "2️⃣ CloudFront: _데이터 수집 예정_\n" +
                           "3️⃣ DataTransfer: _데이터 수집 예정_"
                }
            },
            {
                "type": "divider"
            },
            # 4. 비용 이상 현상
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*⚠️ 비용 이상 감지*"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "_데이터 수집 예정_"
                }
            },
            {
                "type": "divider"
            },
            # 5. DataTransfer 상세 분석
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*🌐 DataTransfer 상세 분석*"
                }
            }
        ]

        # 현재 보유한 VPC Flow Logs 데이터 추가
        traffic_comp = metrics['traffic_comparison'].iloc[0]
        today_gb = float(traffic_comp['today_gb'])
        today_size = f"{today_gb/1024:.2f} TB" if today_gb > 1024 else f"{today_gb:.2f} GB"
        change_pct = float(traffic_comp['change_percentage'])
        estimated_cost = calculate_data_transfer_cost(today_gb)
        unique_sources = int(traffic_comp['today_unique_sources'])
        unique_destinations = int(traffic_comp['today_unique_destinations'])
        unique_sources_str = f"{unique_sources:,}개"
        unique_destinations_str = f"{unique_destinations:,}개"

        # 비용 증감률 계산
        yesterday_gb = float(traffic_comp['yesterday_gb'])
        estimated_cost_yesterday = calculate_data_transfer_cost(yesterday_gb)
        if estimated_cost_yesterday == 0:
            cost_change_pct = 0.0
        else:
            cost_change_pct = ((estimated_cost - estimated_cost_yesterday) / estimated_cost_yesterday) * 100
        cost_change_icon = '📈' if cost_change_pct > 0 else '📉'
        cost_change_pct_str = f"{'+' if cost_change_pct > 0 else ''}{cost_change_pct:.1f}%"
        cost_change_bracket = f"({cost_change_icon} {cost_change_pct_str})"

        change_pct_icon = '📈' if change_pct > 0 else '📉'
        change_pct_str = f"{'+' if change_pct > 0 else ''}{change_pct:.1f}%"
        change_pct_bracket = f"({change_pct_icon} {change_pct_str})"

        message.extend([
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*VPC Flow Logs 전송량*\n" +
                               f"{today_size} {change_pct_bracket}\n" +
                               f"예상 비용: ${estimated_cost:.2f} {cost_change_bracket}\n" +
                               f"고유 소스 IP: {unique_sources_str}\n" +
                               f"고유 대상 IP: {unique_destinations_str}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*CloudFront 전송량*\n_데이터 수집 예정_"
                    }
                ]
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*S3 전송량*\n_데이터 수집 예정_"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*기타 전송량*\n_데이터 수집 예정_"
                    }
                ]
            }
        ])

        # 경고 메시지 (필요한 경우)
        if change_pct > 30:
            message.append({
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": "⚠️ *VPC Flow Logs 트래픽이 전일 대비 30% 이상 증가했습니다!*"
                    }
                ]
            })

        return message
        
    except Exception as e:
        print(f"Error formatting slack message: {str(e)}")
        return [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"📊 AWS 비용 리포트 ({yesterday} 기준)"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"⚠️ *데이터 처리 중 오류가 발생했습니다.*\n```{str(e)}```"
                }
            }
        ]

def format_detail_message(metrics):
    detail_message = []
    
    # 송신 트래픽 TOP 10
    detail_message.append("📊 *데이터 전송 상세 분석*\n")
    detail_message.append("🔹 *송신 트래픽 TOP 10 (Source IP)*")
    if not metrics['top_source_ips'].empty:
        detail_message.append(tabulate(
            metrics['top_source_ips'],
            headers=['IP', '전송량', '요청 수'],
            tablefmt='grid'
        ))
    
    # 수신 트래픽 TOP 10
    detail_message.append("\n🔹 *수신 트래픽 TOP 10 (Destination IP)*")
    if not metrics['top_dest_ips'].empty:
        detail_message.append(tabulate(
            metrics['top_dest_ips'],
            headers=['IP', '수신량', '요청 수'],
            tablefmt='grid'
        ))
    
    # 인스턴스별 트래픽
    detail_message.append("\n🔹 *인스턴스별 트래픽*")
    if not metrics['instance_traffic'].empty:
        detail_message.append(tabulate(
            metrics['instance_traffic'],
            headers=['Instance ID', 'Source IP', '총 전송량', '패킷 수'],
            tablefmt='grid'
        ))
    
    # 인스턴스별 인바운드/아웃바운드 트래픽
    detail_message.append("\n🔹 *인스턴스별 인바운드/아웃바운드 트래픽*")
    if not metrics['instance_direction'].empty:
        detail_message.append(tabulate(
            metrics['instance_direction'],
            headers=['Instance ID', '방향', '전송량', '연결 수'],
            tablefmt='grid'
        ))
    
    # IP 쌍별 트래픽 TOP 50
    detail_message.append("\n🔹 *IP 쌍별 트래픽 TOP 50*")
    if not metrics['ip_pairs'].empty:
        detail_message.append(tabulate(
            metrics['ip_pairs'],
            headers=['Action', 'Interface ID', 'Instance ID', '방향', 'Status', 
                    'Source IP', 'Source Port', 'Dest IP', 'Dest Port', 
                    'Protocol', '전송량'],
            tablefmt='grid'
        ))
    
    return "\n".join(detail_message)

# =============================================================================
# CONSOLE OUTPUT FUNCTIONS (Active)
# =============================================================================

def print_console_report(message):
    """콘솔에 리포트 출력"""
    print("\n" + "="*80)
    print("AWS 비용 리포트")
    print("="*80)
    
    # 메시지 구조를 콘솔 출력으로 변환
    for block in message:
        if block.get('type') == 'header':
            print(f"\n{block['text']['text']}")
            print("-" * len(block['text']['text']))
        elif block.get('type') == 'section':
            if 'text' in block and 'text' in block['text']:
                print(f"\n{block['text']['text']}")
            elif 'fields' in block:
                for field in block['fields']:
                    print(f"\n{field['text']}")
        elif block.get('type') == 'divider':
            print("\n" + "-" * 40)
        elif block.get('type') == 'context':
            for element in block['elements']:
                print(f"\n{element['text']}")
    
    print("\n" + "="*80)

def print_detail_report(detail_message):
    """상세 리포트를 콘솔에 출력"""
    print("\n" + "="*80)
    print("상세 데이터 전송 분석")
    print("="*80)
    print(detail_message)
    print("="*80)

# =============================================================================
# ARCHIVED: SLACK FUNCTIONS (Commented out for future restoration)
# =============================================================================
# To restore Slack functionality, uncomment the following functions and 
# update the main() function to use send_slack_message() instead of print_console_report()

# def send_slack_message(message):
#     response = slack.post_message(SLACK_CHANNEL_ID, None, message)
#     if response.get('ok'):
#         return response['ts']
#     else:
#         print(f"Error sending message: {response.get('error')}")
#         return None

# def send_detail_message(thread_ts, detail_message):
#     kst = pytz.timezone('Asia/Seoul')
#     now = datetime.now(kst)
    
#     response = slack.files_upload_v2(
#         channel_id=SLACK_CHANNEL_ID,
#         content=detail_message,
#         file_name=f"{now.strftime('%Y-%m-%d')}-data-transfer-details.txt",
#         title="*Data Transfer Details*",
#         thread_ts=thread_ts
#     )
    
#     if not response.get('ok'):
#         print(f"Error sending detail message: {response.get('error')}")

# =============================================================================
# MAIN EXECUTION FUNCTION (ARCHIVED - CRON DISABLED)
# =============================================================================
# This cron job has been archived and disabled.
# To re-enable: uncomment the main() function and remove the early return guard.

def main():
    # ARCHIVED: Cron job execution disabled
    print("⚠️  This cron job has been ARCHIVED and is not running.")
    print("📋 To re-enable this cron job:")
    print("   1. Uncomment the main() function below")
    print("   2. Remove this early return guard")
    print("   3. Update your cron scheduler")
    print("   4. Optionally restore Slack functionality from archived sections")
    return
    
    # ARCHIVED: Original main function (commented out)
    # print("Starting data collection...")
    # metrics = get_data_transfer_metrics()
    
    # if all(df.empty for df in metrics.values()):
    #     print("Error: All queries returned empty results")
    #     return
    
    # print("\nFormatting report...")
    # message = format_slack_message(metrics)
    
    # print("\nPrinting report to console...")
    # print_console_report(message)
    
    # print("\nPrinting detailed analysis...")
    # detail_message = format_detail_message(metrics)
    # print_detail_report(detail_message)
    
    # print("\nReport generation completed successfully!")

# =============================================================================
# ARCHIVED: SLACK VERSION OF MAIN FUNCTION
# =============================================================================
# To restore Slack functionality, replace the main() function above with this:

# def main():
#     print("Starting data collection...")
#     metrics = get_data_transfer_metrics()
    
#     if all(df.empty for df in metrics.values()):
#         print("Error: All queries returned empty results")
#         return
    
#     print("\nFormatting Slack message...")
#     message = format_slack_message(metrics)
    
#     print("\nSending to Slack...")
#     thread_ts = send_slack_message(message)
    
#     if thread_ts:
#         print("Message sent successfully")
#         detail_message = format_detail_message(metrics)
#         send_detail_message(thread_ts, detail_message)
#     else:
#         print("Failed to send message to Slack")

# =============================================================================
# CRON JOB EXECUTION (ARCHIVED)
# =============================================================================
# This cron job is currently archived and will not execute.
# The main() function has been disabled with an early return guard.

if __name__ == "__main__":
    main()