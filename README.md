# AWS ECS Demo Infrastructure with Terraform

This project deploys a production-ready demonstration infrastructure on AWS using Terraform. It showcases best practices for networking, container orchestration with ECS on EC2, and a serverless API for file uploads. The entire infrastructure is defined as code, promoting reproducibility and modularity.

## Architecture Overview

The infrastructure consists of the following components:

*   **VPC**: A custom Virtual Private Cloud with public and private subnets across two Availability Zones for high availability.
*   **Application Load Balancer (ALB)**: A public-facing ALB that distributes incoming HTTP traffic.
*   **ECS on EC2**: An Elastic Container Service cluster running on a fleet of EC2 instances managed by an Auto Scaling Group. The EC2 instances are located in private subnets.
*   **NGINX Services**: Two distinct NGINX services (`nginx-a` and `nginx-b`) are deployed to the ECS cluster. The ALB performs round-robin load balancing between them to demonstrate traffic distribution.
*   **Serverless API**: A file upload API built with API Gateway, AWS Lambda, and S3.
    *   **API Gateway**: Provides an HTTP endpoint (`/upload`).
    *   **Lambda Function**: A Python function that processes POST requests, validates the file, and uploads it to an S3 bucket.
    *   **S3 Bucket**: A private S3 bucket for securely storing uploaded files.
*   **IAM**: Least-privilege IAM roles and policies are defined for all services to ensure secure operation.

### Architecture Diagram

```
+--------------------------------------------------------------------------+
|                                  AWS Cloud                               |
|                                                                          |
|  +---------------------------------+      +----------------------------+ |
|  |       Availability Zone A       |      |    Availability Zone B     | |
|  |                                 |      |                            | |
|  |  +-----------(VPC)-----------+  |      |  +-----------------------+ | |
|  |  |                           |  |      |  |                       | | |
|  |  |  Public Subnet-A          |  |      |  |  Public Subnet-B      | | |
|  |  | +-----------------------+ |  |      |  | +-------------------+ | | |
|  |  | |      ALB Node         | |  |      |  | |    ALB Node       | | | |
|  |  | +-----------------------+ |  |      |  | +-------------------+ | | |
|  |  | |     NAT Gateway       | |  |      |  |                       | | |
|  |  | +-----------------------+ |  |      |  |                       | | |
|  |  |                           |  |      |  |                       | | |
|  |  |  Private Subnet-A         |  |      |  |                       | | |
|  |  | +-----------------------+ |  |      |  |                       | | |
|  |  | |   EC2 (ECS Host)      | |  |      |  |                       | | |
|  |  | | +--------+ +--------+ | |  |      |  |                       | | |
|  |  | | | nginx-a| | nginx-b| | |  |      |  |                       | | |
|  |  | | +--------+ +--------+ | |  |      |  |                       | | |
|  |  | +-----------------------+ |  |      |  |                       | | |
|  |  +---------------------------+  |      |  +-----------------------+ | |
|  +---------------------------------+      +----------------------------+ |
|                                                                          |
+--------------------------------------------------------------------------+
       |                                      ^
       | Internet traffic (HTTP)              | S3 API Calls
       v                                      |
+--------------+     +-----------------+   +---------+   +----------+
|    User      |---->|       ALB       |-->|   ECS   |   |  Lambda  |
+--------------+     +-----------------+   +---------+   +----------+
       |                                      ^
       | API Call (POST /upload)              |
       v                                      |
+--------------+                         +----------+
| API Gateway  |------------------------>| S3 Bucket|
+--------------+                         +----------+
```

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform**: Version 1.5.0 or newer.
2.  **AWS CLI**: Configured with your AWS credentials. The user/role must have sufficient permissions to create the resources defined in this project.

    ```
    aws configure
    ```

## Deployment Steps

1.  **Clone the Repository**:
    ```
    git clone https://github.com/YourUsername/YourRepositoryName.git
    cd YourRepositoryName
    ```

2.  **Navigate to the Deployment Environment**:
    All commands should be run from the `environments/demo` directory.
    ```
    cd environments/demo
    ```

3.  **Initialize Terraform**:
    This command downloads the necessary providers and modules.
    ```
    terraform init
    ```

4.  **Plan the Deployment**:
    This command shows you an execution plan of all the resources that will be created. It's a good practice to review this before applying.
    ```
    terraform plan
    ```

5.  **Apply the Configuration**:
    This command will build and deploy all the resources to your AWS account. This process will take several minutes.
    ```
    terraform apply
    ```
    When prompted, type `yes` to confirm the deployment.

## How to Test the Infrastructure

After the `terraform apply` command completes successfully, it will output the DNS name of the load balancer and the URL for the file upload API.

### 1. Test the NGINX Load Balancer

Use `curl` to send requests to the ALB's DNS name. Run the command multiple times to see the response change as the load balancer distributes traffic between the `nginx-a` and `nginx-b` services.

```
# Replace <your_alb_dns_name> with the output from Terraform
curl http://<your_alb_dns_name>
# Expected Output: <h1>Response from NGINX-A</h1>

curl http://<your_alb_dns_name>
# Expected Output: <h1>Response from NGINX-B</h1>
```

### 2. Test the File Upload API

1.  Create a sample file to upload:
    ```
    echo "This is a test file for the serverless API." > test-upload.txt
    ```

2.  Use `curl` to send a POST request to the API Gateway endpoint.

    ```
    # Replace <your_api_upload_url> with the output from Terraform
    curl -X POST --data-binary "@test-upload.txt" "<your_api_upload_url>?filename=test-upload.txt"
    # Expected Output: File test-upload.txt uploaded successfully!
    ```

3.  **Verify the Upload in S3**:
    *   Navigate to the S3 service in your AWS Management Console.
    *   Find the bucket named `my-unique-upload-bucket-<random-suffix>`.
    *   You should see the `test-upload.txt` file inside the bucket.

## Cleanup

To avoid ongoing charges for the resources created, it's crucial to destroy the infrastructure when you are finished.

1.  Navigate to the `environments/demo` directory.

2.  Run the destroy command:
    ```
    terraform destroy
    ```
    When prompted, type `yes` to confirm the deletion of all resources.
```

