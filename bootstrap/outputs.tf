output "bucket_name" {
  description = "Paste this into versions.tf → backend 's3' → bucket"
  value       = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  description = "Paste this into versions.tf → backend 's3' → dynamodb_table"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "next_step" {
  description = "What to do after this apply"
  value       = <<-EOT
    Update ../versions.tf with:

      bucket         = "${aws_s3_bucket.tfstate.bucket}"
      dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"

    Then run from the project root:
      terraform init
  EOT
}
