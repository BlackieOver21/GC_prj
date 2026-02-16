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
  force_destroy = true
}

resource "google_storage_bucket" "images" {
  name     = "obrazkowe-wiadro"
  location = "us-central1"
  force_destroy = true
}

resource "google_storage_bucket" "thumbnails" {
  name     = "thumbnailowe-wiadro"
  location = "us-central1"
  force_destroy = true
}


# Pub/Sub Topic


resource "google_pubsub_topic" "image_events" {
  name = "image-events"
  lifecycle {
    prevent_destroy = false
  }
}


# Cloud Functions - source code


resource "google_storage_bucket_object" "thumb_func_zip" {
  name   = "thumb_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/thumb_func/thumb_func.zip"
}

resource "google_storage_bucket_object" "valid_func_zip" {
  name   = "valid_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/valid_func/valid_func.zip"
}

resource "google_storage_bucket_object" "upload_func_zip" {
  name   = "upload_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/upload_func/upload_func.zip"
}

resource "google_storage_bucket_object" "list_func_zip" {
  name   = "list_func.zip"
  bucket = google_storage_bucket.source_code.name
  source = "${var.root}/functions/list_func/list_func.zip"
}

# Cloud Functions


resource "google_cloudfunctions_function" "validator" {
  name        = "image-validator"
  runtime     = "python310"
  entry_point = "validate_image"
  
  source_archive_bucket = google_storage_bucket.source_code.name
  source_archive_object = google_storage_bucket_object.valid_func_zip.name

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
  source_archive_object = google_storage_bucket_object.thumb_func_zip.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.image_events.name
  }

  environment_variables = {
    STORAGE_BUCKET = google_storage_bucket.thumbnails.name
    PROJECT_ID   = var.project_id
  }
}

resource "google_cloudfunctions_function" "uploader" {
  name        = "image-uploader"
  runtime     = "python310"
  entry_point = "upload_image"

  source_archive_bucket = google_storage_bucket.source_code.name
  source_archive_object = google_storage_bucket_object.upload_func_zip.name

  trigger_http = true
}

resource "google_cloudfunctions_function" "imglister" {
  name        = "image-lister"
  runtime     = "python310"
  entry_point = "list_images"

  source_archive_bucket = google_storage_bucket.source_code.name
  source_archive_object = google_storage_bucket_object.list_func_zip.name

  trigger_http = true
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

resource "google_cloudfunctions_function_iam_member" "upload_invoker" {
  project        = var.project_id
  cloud_function = google_cloudfunctions_function.uploader.name
  role           = "roles/cloudfunctions.invoker"
  depends_on = [
    google_cloudfunctions_function.uploader
  ]
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "list_invoker" {
  project        = var.project_id
  cloud_function = google_cloudfunctions_function.imglister.name
  role           = "roles/cloudfunctions.invoker"
  depends_on = [
    google_cloudfunctions_function.imglister
  ]
  member = "allUsers"
}

resource "google_storage_bucket_iam_binding" "thumbnails_public_access" {
  bucket = "thumbnailowe-wiadro"
  role   = "roles/storage.objectViewer"
  depends_on = [
    google_storage_bucket.thumbnails
  ]
  members = ["allUsers"]
}

resource "google_cloudfunctions_function_iam_binding" "image_lister_invoker" {
  project        = "gcloud-prj-2-487221"
  region         = "us-central1"
  cloud_function  = "image-lister"
  role           = "roles/cloudfunctions.invoker"
  depends_on = [
    google_cloudfunctions_function.imglister
  ]
  members        = ["allUsers"]
}

resource "google_project_iam_binding" "publisher_binding" {
  project = "gcloud-prj-2-487221"
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:gcloud-prj-2-487221@appspot.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "subscriber_binding" {
  project = "gcloud-prj-2-487221"
  role    = "roles/pubsub.subscriber"

  members = [
    "serviceAccount:gcloud-prj-2-487221@appspot.gserviceaccount.com"
  ]
}


# Some outputs


output "upload_function_url" {
  value = google_cloudfunctions_function.uploader.https_trigger_url
}

output "list_function_url" {
  value = google_cloudfunctions_function.imglister.https_trigger_url
}

