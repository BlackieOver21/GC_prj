from google.cloud import monitoring_v3
from google.cloud import pubsub_v1
import base64
import time

client = monitoring_v3.MetricServiceClient()
project_name = f"projects/{'gcloud-prj-484723'}"
project_id = "gcloud-prj-484723"
metric_type = 'custom.googleapis.com/image_validation'

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path("gcloud-prj-484723", "image-events")

def validate_image(event, context):
    file_name = event["name"]
    start_time = time.time()

    if not file_name.lower().endswith((".jpg", ".png")):
        send_custom_metric("invalid_image", 1)
        print("Invalid file type")
        return
    
    send_custom_metric("valid_image", 1)

    message = file_name.encode("utf-8")
    publisher.publish(topic_path, message)

    duration = time.time() - start_time
    send_custom_metric("processing_time_seconds", duration)

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
    
    client.create_time_series(name=project_name, time_series=[series])
    print(f"Custom metric {metric_name} sent with value {value}")