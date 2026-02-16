from PIL import Image
from google.cloud import storage, monitoring_v3
import io, time, base64, os

PROJECT_ID = os.environ.get("PROJECT_ID")

if not PROJECT_ID:
    raise RuntimeError("PROJECT_ID not set. Please set PROJECT_ID environment variable and redeploy the project.")

PROJECT_NAME = f"projects/{PROJECT_ID}"

client = monitoring_v3.MetricServiceClient()

def create_thumbnail(event, context):
    file_name = base64.b64decode(event["data"]).decode("utf-8")
    start_time = time.time()

    print("File: "+file_name)

    client_storage = storage.Client()
    bucket = client_storage.bucket("obrazkowe-wiadro")
    blob = bucket.blob(file_name)
    
    image = Image.open(io.BytesIO(blob.download_as_bytes()))
    image = image.convert("RGB")
    image.thumbnail((200, 200))
    
    thumb_bucket = client_storage.bucket("thumbnailowe-wiadro")
    thumb_blob = thumb_bucket.blob(f"thumbnails/{file_name}")
    
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG")
    thumb_blob.upload_from_string(buffer.getvalue())

    duration = time.time() - start_time
    send_custom_metric("thumbnail_processing_time_seconds", duration)

# dla metryków
def send_custom_metric(metric_name, value):
    series = monitoring_v3.TimeSeries()
    series.metric.type = f'custom.googleapis.com/{metric_name}'
    series.resource.type = 'global'
    series.points = [
        monitoring_v3.Point({
            'interval': {'end_time': {'seconds': int(time.time())}},
            'value': {'double_value': value}
            })
    ]
    
    client.create_time_series(name=PROJECT_NAME, time_series=[series])
    print(f"Custom metric {metric_name} sent with value {value}")
