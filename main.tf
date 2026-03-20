# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    configservice  = "http://localhost:4566"
    iam            = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    sns            = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

# S3 Bucket: Stores AWS Config compliance snapshots and history
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "sysops-config-compliance-logs"
  force_destroy = true

  tags = {
    Name        = "config-logs"
    Environment = "CloudOps-Lab"
  }
}

# IAM Role: Identity for AWS Config to record resource data and write to S3
resource "aws_iam_role" "config_role" {
  name = "aws-config-recorder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

# IAM Policy: Grants AWS Config permission to use the S3 bucket and record data
resource "aws_iam_role_policy" "config_policy" {
  role = aws_iam_role.config_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetBucketLocation", "s3:PutObject"]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.config_bucket.arn}", "${aws_s3_bucket.config_bucket.arn}/*"]
      },
      {
        Action   = ["config:Put*", "config:Get*", "config:List*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Config Recorder: Captures resource changes in the account
resource "aws_config_configuration_recorder" "recorder" {
  name     = "compliance-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }
}

# Delivery Channel: Defines where Config data is delivered
resource "aws_config_delivery_channel" "delivery" {
  name           = "compliance-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
  depends_on     = [aws_config_configuration_recorder.recorder]
}

# Config Recorder Status: Activates the recording process
resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.delivery]
}

# Config Rule: Managed rule to ensure S3 buckets have public access blocked
resource "aws_config_config_rule" "s3_public_access_check" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.status]
}

# Config Rule: Managed rule to ensure all EC2 volumes are encrypted
resource "aws_config_config_rule" "ebs_encryption_check" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder_status.status]
}

# Outputs: Key identifiers for compliance monitoring
output "config_recorder_id" {
  value = aws_config_configuration_recorder.recorder.id
}

output "compliance_log_bucket" {
  value = aws_s3_bucket.config_bucket.id
}
