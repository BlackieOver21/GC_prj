import json
import base64
from google.cloud import storage
from PIL import Image
import io

storage_client = storage.Client()

def generate_thumbnail(event, context):
    message = json.loads(
        base64.b64decode(event["data"]).decode("utf-8")
    )

    bucket_name = message["bucket"]
    file_name = message["file"]

    source_bucket = storage_client.bucket(bucket_name)
    target_bucket = storage_client.bucket("images-thumbnails-bucket")

    blob = source_bucket.blob(file_name)
    image_bytes = blob.download_as_bytes()

    img = Image.open(io.BytesIO(image_bytes))
    img.thumbnail((200, 200))

    output = io.BytesIO()
    img.save(output, format="JPEG")

    thumb_blob = target_bucket.blob(file_name)
    thumb_blob.upload_from_string(
        output.getvalue(),
        content_type="image/jpeg"
    )
