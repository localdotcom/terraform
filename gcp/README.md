# GCP Infrastructure


## Description
Provides IaC to deploy infrastructure to the Google Cloud using Gitlab CI and Terraform


## Folder Structure
```bash
./infrastructure/
├── config                           # Terraform configuration files
├── modules                          # Terraform project-related modules
│   ├── bastion
│   ├── cert-manager
│   ├── gke
│   ├── ingress-nginx
│   ├── lb
│   ├── mysql
│   ├── postgresql
│   ├── vpc
│   └── global                       # Terraform global modules
│       ├── backend
│       ├── iam
│       ├── project
│       ├── terraform                # Script to deploy global modules (manually run)
│       └── values.tfvars.json       # Terraform values for global modules
├── scripts                          # Terraform scripts used by modules
├── .projects
│   └── gcp_organization             # GCP organization
│        ├── gcp_project_id_001      # GCP project
│        │   └── values.tfvars.json  # Project-related Terraform values
│        └── gcp_project_id_002 
│            └── values.tfvars.json           
└── terraform                        # Script to deploy project-related modules (via Gitlab CI)
```

## Prerequisites

Create a bucket for storing backend tfstate
```bash
gcloud config set project <gcp_project_id_to_store_backends>
gsutil mb gs://<bucket_name_for_storing_backend_tfstate>
```

Check whether the backend exists in the Google Cloud
```bash
gcloud storage ls --project=<gcp_project_id_to_store_backends> | grep '<gcp_project_id>-tfstate'
```

## Infrastructure

### Global Modules

#### Backend

##### Input Variables JSON
```json
{
  "backend": {
    "backend_project": "<gcp_project_id_to_store_backends>",
    "backend_bucket": "<bucket_name_for_storing_backend_tfstate>"
  }
}
```

##### Deployment
```bash
cd ./gcp/infrastructure/modules/global/
./terraform plan backend --project <gcp_project_id> --region <gcp_region>
./terraform apply backend --project <gcp_project_id> --region <gcp_region>
````

#### Project

##### Input Variables JSON
```json
{
  "project_settings": {
    "organizations": {
      "<gcp_organization>": {
        "org_id": "<gcp_org_id>",
        "billing_account": "<gcp_billing_account>"
      }
    },
    "api_services": [
      "compute.googleapis.com",
      "iam.googleapis.com",
      "iap.googleapis.com",
      "dns.googleapis.com"
    ],
    "metadata": [
      {
        "key": "enable-oslogin",
        "value": "TRUE"
      }
    ]
  }
}
```

##### Deployment
```bash
cd ./gcp/infrastructure/modules/global/
./terraform plan project --organization <gcp_organization> --project <gcp_project_id> --region <gcp_region>
./terraform apply project --organization <gcp_organization> --project <gcp_project_id> --region <gcp_region>
````

#### IAM Roles And Service Accounts

##### Input Variables JSON
```json
{
  "iam": {
    "service_accounts": {
      "<gcp_project_id_001>": [
        // create a new service account
        {
          "name": "<service_account_to_create>",
          "create": true,
          "display_name": "<service_account_display_name>",
          "grant_access_to": "project",
          "roles": [
            "roles/viewer"
          ]
        },
        {
          "name": "<service_account_without_roles>",
          "create": true,
          "display_name": "<service_account_display_name>"
        }
      ],
      "<gcp_project_id_002>": [
        // add inherited service account from another project
        {
          "name": "<inherited_service_account>",
          "parent_project": "gcp_project_id_001",
          "grant_access_to": "project",
          "roles": [
            "roles/viewer"
          ]
        }
      ]
    },
    "users": {
      "<gcp_project_id_001>": [
        {
          "name": "<user@domain.com>",
          "roles": [
            "roles/viewer"
          ]
        }
      ],
      "<gcp_project_id_002>": [
        {
          "name": "<user@domain.com>",
          "roles": [
            "roles/viewer"
          ]
        }
      ]
    }
  }
}
```

##### Deployment
```bash
cd ./gcp/infrastructure/modules/global/
./terraform plan iam --project <gcp_project_id> --region <gcp_region>
./terraform apply iam --project <gcp_project_id> --region <gcp_region>
````
