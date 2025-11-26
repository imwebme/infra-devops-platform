{{#is_alert}}
🚨 [에러 발생] PUT /games/gifticon 요청에서 1분 동안 500 에러가 10건 이상 발생했습니다.

해당 서비스의 Owner는 ${owners}님 입니다.
{{/is_alert}}

{{#is_alert_recovery}}
 ✅ [에러 복구] PUT /games/gifticon 관련 에러가 해소되었습니다
{{/is_alert_recovery}}

${slack_channels}
