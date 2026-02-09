# Start

provider "google" {
  project = "gcloud-prj-484723"
  region  = "us-central1"
}


# Buckets


resource "google_storage_bucket" "images" {
  name     = "obrazkowe-wiadro"
  location = "us-central1"
}

resource "google_storage_bucket" "thumbnails" {
  name     = "thumbnailowe-wiadro-2"
  location = "us-central1"
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
  source_archive_object = "valid_func.zip"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.images.id
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
  source_archive_object = "thumb_func.zip"

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
  project = "gcloud-prj-484723"
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-agent@gcloud-prj-484723.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_thumbnailer_role" {
  project = "gcloud-prj-484723"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:service-agent@gcloud-prj-484723.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_monitoring_role" {
  project = "gcloud-prj-484723"
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:service-agent@gcloud-prj-484723.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_monitoring_role_thumbnailer" {
  project = "gcloud-prj-484723"
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:service-agent@gcloud-prj-484723.iam.gserviceaccount.com"
}
