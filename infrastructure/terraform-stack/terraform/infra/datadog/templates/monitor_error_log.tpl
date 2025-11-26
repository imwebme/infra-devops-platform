{{#is_alert}}
🚨 {{ log.service }}에 에러가 {{ value }}번 발생했습니다!

해당 서비스의 Owner는 ${owners}님 입니다.

서비스: {{ log.service }}
처음 발생한 시점: {{first_triggered_at}}
에러 메시지: {{log.message}}
링크: {{ log.link }}
{{/is_alert}}

{{#is_alert_recovery}}
🟢 에러가 해소되었습니다! [메트릭]({{ log.link }})
해소된 에러 메시지: {{log.message}}
{{/is_alert_recovery}}

${slack_channels}
