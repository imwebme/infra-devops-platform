{{#is_alert}}

[*${duration}ms* 이상 지연된 API]({{ span.link }})의 개수가 임계치인 `{{value}}`를 초과하였습니다.

해당 서비스의 Owner는 ${owners}님 입니다.

- *타임스탬프*: {{ span.timestamp }}
- *서비스*: {{ span.attributes.service }}
- *배포버전*: {{ span.attributes.version }}
- *환경(언어)*: {{ span.attributes.env }}({{ span.attributes.language }})
- *서버 정보*: {{ span.tags.name }}
- *WEB 정보*
```
컴포넌트: {{ span.attributes.component }}
리소스 명: {{ span.resource_name }}
오퍼레이션: {{ span.operation_name }}
```

- *HTTP 정보*
```
url: {{ span.attributes.http.url }}
url_details.scheme: {{ span.attributes.http.url_details.scheme }}
url_details.host: {{ span.attributes.http.url_details.host }}
url_details.path: {{ span.attributes.http.url_details.path }}
url_details.queryString: {{ span.attributes.http.url_details.queryString }}
status_code: {{ span.attributes.http.status_code }}
method: {{ span.attributes.http.method }}
route: {{ span.attributes.http.route }}
client_ip: {{ span.attributes.http.client_ip }}
useragent: {{ span.attributes.http.useragent }}
request.headers.x-access-token: {{ span.attributes.http.request.headers.x-access-token }}
```


{{/is_alert}}

{{#is_alert_recovery}}
💊 [에러({{ span.trace_id }})]({{ span.link }})가 해소 되었습니다.
{{/is_alert_recovery}}

${slack_channels}