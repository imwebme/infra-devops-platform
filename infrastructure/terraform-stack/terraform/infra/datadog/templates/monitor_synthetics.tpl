
{{#is_alert}} <${url}|${service}>가 다운되었습니다. 확인해주세요.

해당 서비스의 Owner는 ${owners}님 입니다.
{{/is_alert}}

{{#is_alert_recovery}} 💊 <${url}|${service}>가 정상화 되었습니다. {{/is_alert_recovery}}

${slack_channels}