#!/bin/bash

rm ../functions/thumb_func/thumb_func.zip
zip -r ../functions/thumb_func/thumb_func.zip ../functions/thumb_func

gsutil rm gs://obrazkowe-wiadro/thumb_func.zip
gsutil cp ../functions/thumb_func/thumb_func.zip gs://obrazkowe-wiadro/

terraform taint google_cloudfunctions_function.thumbnailer
terraform apply
