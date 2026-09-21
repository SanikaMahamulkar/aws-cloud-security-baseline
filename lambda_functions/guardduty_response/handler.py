import json
import os
import boto3

sns_client = boto3.client("sns")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):
    detail = event.get("detail", {})
    finding_type = detail.get("type", "Unknown")
    severity = detail.get("severity", "Unknown")
    title = detail.get("title", "GuardDuty Finding")
    description = detail.get("description", "No description available")
    region = event.get("region", "unknown")
    account_id = event.get("account", "unknown")

    message = (
        f"GuardDuty Security Finding\n"
        f"----------------------------\n"
        f"Title: {title}\n"
        f"Type: {finding_type}\n"
        f"Severity: {severity}\n"
        f"Account: {account_id}\n"
        f"Region: {region}\n"
        f"Description: {description}\n"
    )

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"[Security Alert] {title}"[:100],
        Message=message,
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Alert processed and published to SNS"}),
    }
