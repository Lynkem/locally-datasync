# Locally DataSync
Contains Terraform code for the Locally DataSync transfer from Google to S3

## Using This Terraform
This document assumes your AWS API shared credentials file uses a profile called `brandslice`.
If this is not the case, you'll need to modify the lines that reference `profile` in `main.tf`
and `terraform.tfvars` to use the profile name that matches yours.

### Initialize the Terraform Workspace
Clone the repository and `cd` into it.  Run the command

`AWS_PROFILE=brandslice aws ssm get-parameter --name /datasync/locally/terraform-vars --with-decryption | jq -r '.Parameter.Value' >> terraform.tfvars`

Again, if your AWS shared credentials profile is something other than `brandslice`, you will also need to
use a different value for `AWS_PROFILE` in the above command and in the generated `terraform.tfvars`.

Run `terraform init --backend-config key=locally/datasync/terraform.tfstate`
