# Start

provider "google" {
  project = "gcloud-prj-484723"
  region  = "us-central1"
}


# Buckets


resource "google_storage_bucket" "images" {
  name     = "gcloud-prj-484723-images"
  location = "US"
}

resource "google_storage_bucket" "thumbnails" {
  name     = "gcloud-prj-484723-thumbnails"
  location = "US"
}


# Pub/Sub Topic


resource "google_pubsub_topic" "image_events" {
  name = "image-events"
}


# Cloud Functions


resource "google_cloudfunctions_function" "validator" {
  name        = "image-validator"
  runtime     = "python310"
  entry_point = "validate_image"
  
  source_archive_bucket = google_storage_bucket.images.name
  source_archive_object = "validator.zip"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.images.name
  }

  environment_variables = {
    PUBSUB_TOPIC = google_pubsub_topic.image_events.name
  }
}

resource "google_cloudfunctions_function" "thumbnailer" {
  name        = "thumbnail-generator"
  runtime     = "python310"
  entry_point = "create_thumbnail"

  source_archive_bucket = google_storage_bucket.images.name
  source_archive_object = "thumbnailer.zip"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.image_events.name
  }

  environment_variables = {
    STORAGE_BUCKET = google_storage_bucket.thumbnails.name
  }
}


# IAM Roles


resource "google_project_iam_member" "cf_validator_role" {
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_cloudfunctions_function.validator.service_account_email}"
}

resource "google_project_iam_member" "cf_thumbnailer_role" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_cloudfunctions_function.thumbnailer.service_account_email}"
}

resource "google_project_iam_member" "cf_monitoring_role" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_cloudfunctions_function.validator.service_account_email}"
}

resource "google_project_iam_member" "cf_monitoring_role_thumbnailer" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_cloudfunctions_function.thumbnailer.service_account_email}"
}