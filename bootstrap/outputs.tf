output "bucket_name" {
  description = "Paste this into versions.tf → backend 's3' → bucket"
  value       = aws_s3_bucket.tfstate.bucket
}

output "next_step" {
  description = "What to do after this apply"
  value       = <<-EOT
    Update ../versions.tf with:

      bucket = "${aws_s3_bucket.tfstate.bucket}"

    Then run from the project root:
      terraform init
  EOT
}
