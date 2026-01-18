import json
import base64
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
TOPIC_PATH = publisher.topic_path(
    "my-project-id",
    "image-validated"
)

def validate_image(event, context):
    file_name = event["name"]
    bucket_name = event["bucket"]
    content_type = event.get("contentType", "")

    # prosta walidacja
    if not content_type.startswith("image/"):
        print("Not an image, ignoring")
        return

    message = {
        "bucket": bucket_name,
        "file": file_name
    }

    publisher.publish(
        TOPIC_PATH,
        json.dumps(message).encode("utf-8")
    )
