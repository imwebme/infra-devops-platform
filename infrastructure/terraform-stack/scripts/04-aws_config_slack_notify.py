#!/usr/bin/env python3

"""
AWS Config 규칙 위반 사항을 Slack으로 알림을 보내는 스크립트
실행: ./aws_config_slack_notify.py
환경변수: AWS_CONFIG_SLACK_WEBHOOK (GitHub Secret)
"""

import os
import sys
import json
import boto3
import requests
import logging
from datetime import datetime
from typing import Dict, Any

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_config_details(config_client, rule_name: str) -> Dict[str, Any]:
    """AWS Config 규칙 상세 정보 조회"""
    response = config_client.describe_config_rules(
        ConfigRuleNames=[rule_name]
    )
    return response['ConfigRules'][0] if response['ConfigRules'] else {}

def get_non_compliant_resources(config_client, rule_name: str) -> list:
    """규칙을 위반한 리소스 목록 조회"""
    resources = []
    paginator = config_client.get_paginator('get_compliance_details_by_config_rule')
    for page in paginator.paginate(
        ConfigRuleName=rule_name,
        ComplianceTypes=['NON_COMPLIANT']
    ):
        resources.extend(page['EvaluationResults'])
    return resources

def send_slack_notification(webhook_url: str, message: Dict[str, Any]) -> None:
    """Slack으로 메시지 전송"""
    try:
        response = requests.post(
            webhook_url,
            json=message,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        response.raise_for_status()
        logger.info("Successfully sent Slack notification")
    except requests.exceptions.Timeout:
        logger.error("Slack notification timed out")
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        logger.error(f"Error sending Slack notification: {e}")
        sys.exit(1)

def format_slack_message(rule_details: Dict[str, Any], resources: list) -> Dict[str, Any]:
    """Slack 메시지 포맷팅"""
    return {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🚨 AWS Config Rule Violation Alert"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Rule Name:*\n{rule_details.get('ConfigRuleName')}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Description:*\n{rule_details.get('Description', 'N/A')}"
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Non-Compliant Resources:* {len(resources)}"
                }
            }
        ]
    }

def main():
    # Slack Webhook URL 환경변수 확인
    webhook_url = os.getenv('AWS_CONFIG_SLACK_WEBHOOK')
    if not webhook_url:
        logger.error("AWS_CONFIG_SLACK_WEBHOOK environment variable is not set")
        sys.exit(1)

    # AWS Config 클라이언트 생성
    try:
        config_client = boto3.client('config')
    except Exception as e:
        logger.error(f"Error creating AWS Config client: {e}")
        sys.exit(1)

    try:
        # Config 규칙 목록 조회
        rules_response = config_client.describe_config_rules()
        
        for rule in rules_response['ConfigRules']:
            rule_name = rule['ConfigRuleName']
            logger.info(f"Checking rule: {rule_name}")
            
            # 규칙 위반 리소스 조회
            non_compliant = get_non_compliant_resources(config_client, rule_name)
            
            if non_compliant:
                # Slack 메시지 생성 및 전송
                message = format_slack_message(rule, non_compliant)
                send_slack_notification(webhook_url, message)
                
                logger.info(f"Notification sent for rule: {rule_name}")

    except Exception as e:
        logger.error(f"Error processing AWS Config rules: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 