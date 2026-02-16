import uuid
from flask import jsonify
from google.cloud import storage

storage_client = storage.Client()
BUCKET_NAME = "obrazkowe-wiadro"

def upload_image(request):
    """Cloud Function entry point for image upload."""
    if request.method != "POST":
        return jsonify({"error": "Only POST allowed"}), 405

    if "image" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    filename = f"{uuid.uuid4()}_{file.filename}"
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(filename)
    blob.upload_from_file(file)

    return jsonify({"message": "Uploaded successfully", "filename": filename})

