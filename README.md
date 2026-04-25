# AWS Compliance as Code Lab (AWS Config)

This lab demonstrates a mission-critical governance pattern for the **AWS SysOps Administrator Associate**: implementing continuous compliance monitoring using **AWS Config**.

## Architecture Overview

The system implements an automated compliance monitoring and alerting framework:

1.  **Configuration Recording:** An AWS Config Configuration Recorder captures all resource configuration changes within the account.
2.  **Compliance Auditing:** Managed Config Rules evaluate resources against specific security standards (e.g., prohibiting public S3 buckets and requiring encrypted EBS volumes).
3.  **Secure Archival:** A dedicated S3 bucket stores the history of configuration changes and compliance snapshots for long-term auditing.
4.  **Real-time Monitoring:** A CloudWatch Event (EventBridge) rule monitors for any compliance state changes, enabling immediate detection of non-compliant resources.

## Key Components

-   **AWS Config Recorder:** The engine that tracks resource history.
-   **Config Rules:** The logic that defines "Compliance as Code."
-   **IAM Role:** Secure service identity for the Config service.
-   **CloudWatch Event Rule:** The automated trigger for operational response to non-compliance.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html)
-   [LocalStack Pro](https://localstack.cloud/)
-   [AWS CLI / awslocal](https://github.com/localstack/awscli-local)

## Deployment

1.  **Initialize and Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    
```

## Verification & Testing

To test the continuous compliance engine:

1.  **Verify Recorder Status:**
    ```bash
    awslocal configservice describe-configuration-recorder-status
    aws configservice describe-configuration-recorder-status
    
```

2.  **Check Config Rules:**
    List the deployed compliance rules:
    ```bash
    awslocal configservice describe-config-rules
    aws configservice describe-config-rules
    
```

3.  **Inspect Compliance Status:**
    View the current compliance state for a specific rule:
    ```bash
    awslocal configservice get-compliance-details-by-config-rule --config-rule-name s3-bucket-public-read-prohibited
    aws configservice get-compliance-details-by-config-rule --config-rule-name s3-bucket-public-read-prohibited
    
```

4.  **Simulate Non-Compliance (Conceptual):**
    In a real environment, creating an unencrypted EBS volume would trigger the `encrypted-volumes` rule and generate a CloudWatch Event.

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```

---

💡 **Pro Tip: Using `aws` instead of `awslocal`**

If you prefer using the standard `aws` CLI without the `awslocal` wrapper or repeating the `--endpoint-url` flag, you can configure a dedicated profile in your AWS config files.

### 1. Configure your Profile
Add the following to your `~/.aws/config` file:
```ini
[profile localstack]
region = us-east-1
output = json
# This line redirects all commands for this profile to LocalStack
endpoint_url = http://localhost:4566
```

Add matching dummy credentials to your `~/.aws/credentials` file:
```ini
[localstack]
aws_access_key_id = test
aws_secret_access_key = test
```

### 2. Use it in your Terminal
You can now run commands in two ways:

**Option A: Pass the profile flag**
```bash
aws iam create-user --user-name DevUser --profile localstack
```

**Option B: Set an environment variable (Recommended)**
Set your profile once in your session, and all subsequent `aws` commands will automatically target LocalStack:
```bash
export AWS_PROFILE=localstack
aws iam create-user --user-name DevUser
```

### Why this works
- **Precedence**: The AWS CLI (v2) supports a global `endpoint_url` setting within a profile. When this is set, the CLI automatically redirects all API calls for that profile to your local container instead of the real AWS cloud.
- **Convenience**: This allows you to use the standard documentation commands exactly as written, which is helpful if you are copy-pasting examples from AWS labs or tutorials.
