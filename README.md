
# Terraform + Terragrunt AWS Infrastructure

This repository manages **AWS infrastructure** using **Terraform** and **Terragrunt** to create and manage:
- **VPC** (Virtual Private Cloud)
- **Public & Private Subnets**
- **EC2 Instances**
- **S3 Buckets** (for application usage and remote state storage)

The setup supports **multiple environments**:
- `dev`
- `preprod`
- `prod`

---

## **Folder Structure**

```
terraform-infra/
├── README.md
├── .gitignore
├── terragrunt.hcl               # Root Terragrunt configuration (common to all environments)
│
├── modules/                      # Reusable Terraform modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── subnet/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/                 # Environment-specific configurations
    ├── dev/
    │   └── terragrunt.hcl
    │
    ├── preprod/
    │   └── terragrunt.hcl
    │
    └── prod/
        └── terragrunt.hcl
```

---

## **Why We Have Root `terragrunt.hcl`**

The root `terragrunt.hcl` contains **common configuration shared by all environments**, such as:
- Remote state backend configuration (S3 + DynamoDB).
- Terraform module source path.

This avoids repeating the same backend configuration in every environment.

### Example: Root `terragrunt.hcl`
```hcl
terraform {
  source = "./modules//" # Points to reusable Terraform modules
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-states-123"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

**Purpose:**
- **Centralized configuration:** All environments inherit the backend and module source.
- **DRY (Don't Repeat Yourself):** Instead of defining the S3/DynamoDB backend in every environment, we define it **once here**.

---

## **Why Each Environment Has Its Own `terragrunt.hcl`**

Each environment (`dev`, `preprod`, `prod`) needs **different variables**, such as:
- VPC CIDR range
- Subnet IPs
- EC2 instance type
- S3 bucket names

By having separate `terragrunt.hcl` files in each environment folder:
- Environments are **isolated** from each other.
- We can deploy, update, or destroy one environment without affecting others.

### Example: `environments/dev/terragrunt.hcl`
```hcl
include {
  path = find_in_parent_folders() # Inherits from root terragrunt.hcl
}

inputs = {
  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]
  instance_type   = "t2.micro"
  bucket_name     = "dev-app-bucket-123"
}
```

For `preprod` and `prod`, only the `inputs` change.

---

## **How Terragrunt Works**

When you run `terragrunt plan` or `terragrunt apply`, this is what happens internally:

1. Terragrunt reads the **environment-specific `terragrunt.hcl`**.
2. It merges it with the **root `terragrunt.hcl`** (`include` keyword).
3. It creates a `.terragrunt-cache/` folder where it copies the Terraform code.
4. Runs Terraform commands inside the `.terragrunt-cache/` folder.

---

## **Generated Folders and Files**

### **1. `.terraform/` Folder**
- Created automatically when you run `terraform init` or `terragrunt init`.
- Stores:
  - Terraform providers (e.g., AWS provider plugin).
  - Backend configuration.
  - Local cache for performance.

You **should never commit this folder** to Git.

---

### **2. `.terragrunt-cache/` Folder**
- Created automatically by **Terragrunt**.
- Purpose:
  - Keeps a **temporary copy** of Terraform modules per environment.
  - Ensures that different environments don't interfere with each other.

Example structure:
```
.terragrunt-cache/
└── nT5bP1FjQ2vLz6Qx9b/
    └── modules/
        ├── vpc/
        ├── subnet/
        ├── ec2/
        └── s3/
```

You **should never commit this folder** to Git.

---

### **3. `terraform.tfstate` File**
- Tracks the real-world state of AWS resources.
- Stored **remotely in S3** as configured in the root `terragrunt.hcl`.
- DynamoDB table is used to **lock** the state file during updates to prevent race conditions.

---

## **Setup Remote Backend**

Before running Terragrunt, create an S3 bucket and DynamoDB table for storing and locking the Terraform state:

```bash
# Create S3 bucket for remote state
aws s3 mb s3://my-terraform-states-123 --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table   --table-name terraform-lock-table   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --region us-east-1
```

---

## **Commands to Run**

### **1. Navigate to Environment**
Each environment is managed independently:
```bash
cd environments/dev
```

### **2. Initialize Terragrunt**
Initializes Terraform backend and providers:
```bash
terragrunt init
```

### **3. Validate Configuration**
Checks for syntax issues:
```bash
terragrunt validate
```

### **4. Plan Changes**
Shows what resources will be created, updated, or destroyed:
```bash
terragrunt plan
```

### **5. Apply Changes**
Applies the plan and provisions AWS resources:
```bash
terragrunt apply
```

### **6. Destroy Resources**
Destroys resources in the current environment:
```bash
terragrunt destroy
```

---

## **Example Workflow**

### Deploying Dev Environment
```bash
cd environments/dev
terragrunt init
terragrunt plan
terragrunt apply
```

### Deploying Preprod Environment
```bash
cd environments/preprod
terragrunt init
terragrunt plan
terragrunt apply
```

### Deploying Prod Environment
```bash
cd environments/prod
terragrunt init
terragrunt plan
terragrunt apply
```

---

## **Git Commands**

```bash
# Stage all files
git add .

# Commit files
git commit -m "Initial Terraform + Terragrunt project setup"

# Push to remote
git push origin main
```

---

## **Why This Structure Is Best Practice**

| **Folder/File**        | **Purpose** |
|------------------------|-------------|
| `modules/`             | Reusable Terraform code for AWS resources like VPC, Subnets, EC2, and S3. |
| `environments/`        | Keeps each environment isolated with its own variables. |
| `root terragrunt.hcl`  | Centralizes backend and module source configuration. |
| `.terraform/`          | Local Terraform provider cache (auto-generated). |
| `.terragrunt-cache/`   | Temporary folder where Terragrunt copies Terraform code for execution. |
| `terraform.tfstate`    | Remote state file that tracks AWS resources. |

---

## **Best Practices**
1. **Never commit these folders:**
   - `.terraform/`
   - `.terragrunt-cache/`
   - `terraform.tfstate`

2. Always run:
   ```bash
   terragrunt plan
   ```
   before applying to see changes.

3. Use **separate AWS accounts** for dev, preprod, and prod.

4. Protect the `main` branch with **code reviews** for safe production deployments.

---

## **References**
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)

---

## **Summary**

- Root `terragrunt.hcl` → shared backend & module source configuration.  
- Environment-specific `terragrunt.hcl` → unique variables per environment.  
- `.terraform/` → local cache for Terraform providers.  
- `.terragrunt-cache/` → temporary copy of Terraform code per environment.  
- `terraform.tfstate` → remote state stored in S3 with DynamoDB lock.  
- Commands provided for initialization, planning, applying, and destroying infrastructure.
# terragrunt-project
