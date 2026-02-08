from PIL import Image
from google.cloud import storage
import io
import time
from google.cloud import monitoring_v3

# Inicjalizacja klienta dla Cloud Monitoring
client = monitoring_v3.MetricServiceClient()
project_name = f"projects/{'gcloud-prj-484723'}"

def create_thumbnail(event, context):
    file_name = event["data"].decode("utf-8")
    start_time = time.time()

    # Pobieranie obrazu z Cloud Storage
    client_storage = storage.Client()
    bucket = client_storage.bucket("gcloud-prj-484723-images")
    blob = bucket.blob(file_name)
    
    image = Image.open(io.BytesIO(blob.download_as_bytes()))
    image.thumbnail((200, 200))
    
    # Zapisanie miniaturki
    thumb_bucket = client_storage.bucket("gcloud-prj-484723-thumbnails")
    thumb_blob = thumb_bucket.blob(f"thumbnails/{file_name}")
    
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG")
    thumb_blob.upload_from_string(buffer.getvalue())

    # Czas przetwarzania miniaturki
    duration = time.time() - start_time
    send_custom_metric("thumbnail_processing_time_seconds", duration)

def send_custom_metric(metric_name, value):
    # Wysyłanie metryki do Cloud Monitoring
    series = monitoring_v3.TimeSeries()
    series.metric.type = f'custom.googleapis.com/{metric_name}'
    series.resource.type = 'global'
    series.points = [
        monitoring_v3.Point({
            'interval': {'end_time': {'seconds': int(time.time())}},
            'value': {'double_value': value}
        })
    ]
    
    # Wysłanie metryki
    client.create_time_series(name=project_name, time_series=[series])
    print(f"Custom metric {metric_name} sent with value {value}")