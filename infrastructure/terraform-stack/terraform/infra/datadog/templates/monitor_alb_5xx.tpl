{{#is_alert}}
*[Alert]* ALB에서 500번대 에러가 5분 동안 발생했습니다.
현재 500번대 에러 개수는 `{{value}}`이며, 임계치인 `{{threshold}}`을 초과하였습니다.

해당 서비스의 Owner는 ${owners}님 입니다.

[*AWS ALB 타켓그룹 5xx 대시보드*](https://app.datadoghq.com/dashboard/mrs-7wq-v9k/aws-applicationelb-cloned?fromUser=false&refresh_mode=paused&tpl_var_host%5B0%5D={{host.hostname}}&view=spans&from_ts={{first_triggered_at_epoch}}&to_ts={{last_triggered_at_epoch}}&live=false&tile_focus=6361225580274948)
{{/is_alert}} 

{{#is_alert_recovery}}
💊 *[Alert]* ALB에서 500번대 에러가 해소되었습니다.
현재 500번대 에러 개수는 `{{value}}`이며, 임계치인 `{{threshold}}` 미만입니다.
{{/is_alert_recovery}}

${slack_channels}