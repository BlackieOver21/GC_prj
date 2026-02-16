import json
from google.cloud import storage

def list_images(request):
    bucket_name = "thumbnailowe-wiadro"
    prefix = "thumbnails/"
    
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blobs = bucket.list_blobs(prefix=prefix)
    
    urls = [f"https://storage.googleapis.com/{bucket_name}/{blob.name}" for blob in blobs]

    response = {
        "images": urls
    }

    return json.dumps(response)

