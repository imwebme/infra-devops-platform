const https = require("https");
const url = require("url");

exports.handler = async (event) => {
  const message = JSON.parse(event.Records[0].Sns.Message);

  // CloudTrail 이벤트 파싱
  const eventName = message.detail.eventName;
  const eventTime = message.detail.eventTime;
  const userIdentity = message.detail.userIdentity;
  const sourceIPAddress = message.detail.sourceIPAddress;
  const userAgent = message.detail.userAgent;
  const region = message.detail.awsRegion;

  // Slack 메시지 구성
  const slackMessage = {
    channel: process.env.SLACK_CHANNEL,
    username: "AWS CloudTrail Alert",
    icon_emoji: ":warning:",
    attachments: [
      {
        color: "#FF0000",
        title: `CloudTrail Alert: ${eventName}`,
        fields: [
          {
            title: "Event Time",
            value: eventTime,
            short: true,
          },
          {
            title: "Region",
            value: region,
            short: true,
          },
          {
            title: "User Identity",
            value: JSON.stringify(userIdentity, null, 2),
            short: false,
          },
          {
            title: "Source IP",
            value: sourceIPAddress,
            short: true,
          },
          {
            title: "User Agent",
            value: userAgent,
            short: true,
          },
        ],
      },
    ],
  };

  // Slack으로 메시지 전송
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  const requestUrl = url.parse(webhookUrl);

  const options = {
    hostname: requestUrl.host,
    path: requestUrl.path,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () => resolve({ statusCode: res.statusCode, body: body }));
    });

    req.on("error", (e) => reject(e));
    req.write(JSON.stringify(slackMessage));
    req.end();
  });
};
