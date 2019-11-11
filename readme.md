# infra-terraform
1.) To install terraform run `brew install terraform`

2.) To install provider needed by your project run `terraform init`, if aws then it installs aws plugin

3.) `terraform plan -out m3.tfplan` will look at your configuration files in your current working directory and also load variables from tfvars files in that directory. With modules, there is another way of loading variables and not from tfvars

`terraform plan` works by looking at your existing env, compares it with what you want to do and come up with a plan.# infra-terraform

4.) For authentication into your aws account, I have a separate file not included in the remote git repo, that is terraform.tfvars and has the following content:

```
aws_access_key = ""

aws_secret_key = ""

key_name = ""

private_key_path = ""
```
5.) `terraform destroy` - will destroy all resources created

Terraform needs a way to store the state of your deployment. It does this using json format. It stores resource mappings and metadata. It supports locking. It can be stored either locally or remotely e.g. s3
Terraform planning takes into consideration of dependency graph. In that case one resource that depends on the other will not be created if one fails e.g. ec2 instance and subnets

6.) `terraform console` - this returns a terraform CLI where you can execute terraform functions e.g. numeric functions like: min(1,2,3), network functions like cidrsubnet(var.network_address_space, 8, 0) & cidrhost(cidrsubnet(var.network_address_space, 8, 0),5), map functions like lookup(local.common_tags, "BillingCode", "Unknown")

7.) terraform  `env` command is deprecated and the new command is `workspace`

