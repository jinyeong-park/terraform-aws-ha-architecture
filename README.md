# terraform-aws
#### Terraform Setup
```
cd terraform
terraform init
terraform validate # optional
terraform plan
terraform apply
```


##### Destroy the infrastructure
```
terraform destroy
```

##### Terraform folder structure
terraform/                  # Terraform code directory  
├── main.tf                 # Defines the main infrastructure resources (EC2, RDS, VPC, etc.)  
├── provider.tf             # AWS provider configuration (connects to AWS resources)  
├── variables.tf            # Defines input variables (e.g., instance size, region, etc.)  
└── outputs.tf              # Output values (e.g., DB URL, load balancer URL, etc.)


#### Useful Resources for Terraform
- [Terraform doc for AWS - Prerequisites](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)
- [Terraform registry AWS](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform syntax](https://developer.hashicorp.com/terraform/language)

<!-- 시간 되면.... 밑의 구조로 수정 -->
<!-- terraform/                         # Terraform code for provisioning AWS resources
    ├── modules/                   # Reusable Terraform modules
    │   ├── vpc/                   # VPC and subnet configuration
    │   │   ├── main.tf            # VPC, subnets, route tables
    │   │   └── variables.tf       # VPC variables
    │   ├── ec2/                   # EC2 instance module (Bastion Host)
    │   │   ├── main.tf            # Bastion Host and security groups
    │   │   └── variables.tf       # EC2 variables
    │   ├── rds/                   # RDS (Active-Standby) module
    │   │   ├── main.tf            # RDS setup for Active-Standby
    │   │   └── variables.tf       # RDS variables
    │   └── alb/                   # Application Load Balancer (ALB) module
    │       ├── main.tf            # ALB setup (load balancing)
    │       └── variables.tf       # ALB variables
    ├── main.tf                    # Main entry point, tying everything together
    ├── provider.tf                # AWS provider configuration
    ├── variables.tf               # Variables (e.g., region, instance types)
    ├── outputs.tf                 # Outputs (e.g., DB endpoint, ALB URL)
    └── terraform_backend.tf       # Backend configuration (optional, for remote state management) -->
