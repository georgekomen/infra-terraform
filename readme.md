# infra-terraform
1.) To install terraform run `brew install terraform`

2.) To install provider needed by your project run `terraform init`, if aws then it installs aws plugin

3.) `terraform plan -out m3.tfplan` will look at your configuration files in your current working directory and also load variables from tfvars files in that directory. With modules, there is another way of loading variables and not from tfvars

`terraform plan` works by looking at your existing env, compares it with what you want to do and come up with a plan.# infra-terraform

