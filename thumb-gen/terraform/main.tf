# Start


variable "project_id" {
  description = "ID of project"
  type = string
}

variable "root" {
  description = "Path to root folder"
  type        = string
}



provider "google" {
  project = var.project_id
  region  = "us-central1"
}


# Buckets


resource "google_storage_bucket" "source_code" {
  name     = "zrodlowe-wiadro"
  location = "us-central1"
}

resource "google_storage_bucket" "images" {
  name     = "obrazkowe-wiadro"
  location = "us-central1"
}

resource "google_storage_bucket" "thumbnails" {
  name     = "thumbnailowe-wiadro"
  location = "us-central1"
}


# Pub/Sub Topic


resource "google_pubsub_topic" "image_events" {
  name = "image-events"
}


# Cloud Functions - source code


resource "google_storage_bucket_object" "thumb_func.zip" {
  name   = "thumb_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/thumb_func/thumb_func.zip"
}

resource "google_storage_bucket_object" "valid_func.zip" {
  name   = "valid_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/valid_func/valid_func.zip"
}


# Cloud Functions


resource "google_cloudfunctions_function" "validator" {
  name        = "image-validator"
  runtime     = "python310"
  entry_point = "validate_image"
  
  source_archive_bucket = google_storage_bucket.source_code.name
  source_archive_object = "valid_func.zip"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.images.id
  }

  environment_variables = {
    PUBSUB_TOPIC = google_pubsub_topic.image_events.name
    PROJECT_ID   = var.project_id
  }
}

resource "google_cloudfunctions_function" "thumbnailer" {
  name        = "thumbnail-generator"
  runtime     = "python310"
  entry_point = "create_thumbnail"

  source_archive_bucket = google_storage_bucket.source_code.name
  source_archive_object = "thumb_func.zip"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.image_events.name
  }

  environment_variables = {
    STORAGE_BUCKET = google_storage_bucket.thumbnails.name
    PROJECT_ID   = var.project_id
  }
}


# IAM Roles


resource "google_project_iam_member" "cf_validator_role" {
  project = var.project_id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-agent@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_thumbnailer_role" {
  project = var.project_id
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:service-agent@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_monitoring_role" {
  project = var.project_id
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:service-agent@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cf_monitoring_role_thumbnailer" {
  project = var.project_id
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:service-agent@${var.project_id}.iam.gserviceaccount.com"
}
