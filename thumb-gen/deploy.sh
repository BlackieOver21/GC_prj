#!/bin/bash
set -e

PROJECT_ID="thumbnailz"
REGION="us-central1"
IMAGE_INPUT_BUCKET="images-input-bucket"
IMAGE_THUMBNAIL_BUCKET="images-thumbnails-bucket"
PUBSUB_TOPIC="image-validated"

gcloud config set project $PROJECT_ID

echo "Creating Cloud Storage buckets..."
gsutil mb gs://$IMAGE_INPUT_BUCKET
gsutil mb gs://$IMAGE_THUMBNAIL_BUCKET

echo "Creating Pub/Sub topic..."
gcloud pubsub topics create $PUBSUB_TOPIC

echo "Deploying Cloud Function - Validator..."
gcloud functions deploy image-validator \
  --gen2 \
  --runtime=python311 \
  --region=$REGION \
  --source=functions/valid_func \
  --entry-point=validate_image \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$IMAGE_INPUT_BUCKET" \
  --allow-unauthenticated

echo "Deploying Cloud Function - Thumbnail Generator..."
gcloud functions deploy image-thumbnailer \
  --gen2 \
  --runtime=python311 \
  --region=$REGION \
  --source=functions/thumb_func \
  --entry-point=generate_thumbnail \
  --trigger-topic=$PUBSUB_TOPIC \
  --allow-unauthenticated

echo "Setting up IAM permissions..."
gcloud functions add-iam-policy-binding image-validator \
  --member="serviceAccount:$(gcloud iam service-accounts describe --format="value(email)" $PROJECT_ID@appspot.gserviceaccount.com)" \
  --role="roles/pubsub.publisher"
gcloud functions add-iam-policy-binding image-thumbnailer \
  --member="serviceAccount:$(gcloud iam service-accounts describe --format="value(email)" $PROJECT_ID@appspot.gserviceaccount.com)" \
  --role="roles/storage.objectViewer"
gcloud functions add-iam-policy-binding image-thumbnailer \
  --member="serviceAccount:$(gcloud iam service-accounts describe --format="value(email)" $PROJECT_ID@appspot.gserviceaccount.com)" \
  --role="roles/storage.objectCreator"

echo "Deployment complete! Functions are now live!"