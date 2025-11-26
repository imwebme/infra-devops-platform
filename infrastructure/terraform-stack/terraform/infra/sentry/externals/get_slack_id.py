#!/usr/bin/env python3
import sys, json, os
from urllib import request, parse

def main():
    try:
        args = json.load(sys.stdin)
        email = args["email"]
        slack_token = os.environ.get("SLACK_TOKEN")
        if not slack_token:
            print("Error: SLACK_TOKEN environment variable is not set.")
            print(json.dumps({"slack_id": ""}))
            return
        url = f"https://slack.com/api/users.lookupByEmail?{parse.urlencode({'email': email})}"
        req = request.Request(url)
        req.add_header("Authorization", f"Bearer {slack_token}")
        with request.urlopen(req) as resp:
            data = json.load(resp)
        if data.get("ok"):
            print(json.dumps({"slack_id": data["user"]["id"]}))
        else:
            print(f"Slack API error: {data.get('error', 'Unknown error')}")
            print(json.dumps({"slack_id": ""}))
    except Exception as e:
        print(f"Exception occurred: {e}")
        print(json.dumps({"slack_id": ""}))

if __name__ == "__main__":
    main() 