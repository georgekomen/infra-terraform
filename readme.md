# infra-terraform

1.) To install terraform run `brew install terraform`

2.) To install provider needed by your project run `terraform init`, if aws then it installs aws plugin

3.) `terraform plan -out m3.tfplan` will look at your configuration files in your current working directory and also load variables from tfvars files in that directory. With modules, there is another way of loading variables and not from tfvars

`terraform plan` works by looking at your existing env, compares it with what you want to do and come up with a plan.# infra-terraform

4.) For authentication into your aws account, I have a separate file not included in the remote git repo, that is secrets.tfvars and has aws secret and private keys.

5.) `terraform destroy -state <path>` - will destroy all resources created

Terraform needs a way to store the state of your deployment. It does this using json format. It stores resource mappings and metadata. It supports locking. It can be stored either locally or remotely e.g. s3
Terraform planning takes into consideration of dependency graph. In that case one resource that depends on the other will not be created if one fails e.g. ec2 instance and subnets

6.) `terraform console` - this returns a terraform CLI where you can execute terraform functions e.g. numeric functions like: min(1,2,3), network functions like cidrsubnet(var.network_address_space, 8, 0) & cidrhost(cidrsubnet(var.network_address_space, 8, 0),5), map functions like lookup(local.common_tags, "BillingCode", "Unknown")

7.) terraform `env` command is deprecated and the new command is `workspace`

8.) resource arguments e.g. `depends_on` for declaring dependency, `count` and `for_each` are for loops. `provider` is for creation provider

9.) example using `cidrsubnet` e.g. cidrsubnet(10.1.0.0/16, 8, 0) => 10.1.0.0/24
cidrsubnet(10.1.0.0/16, 8, 1) => 10.1.1.0/24
cidrsubnet(10.1.0.0/16, 8, 5) => 10.1.5.0/24

10.) variables have a name, type and default. The last two are not a must. This values can be got from env variables files or from command line (var options). The precedence is also in that order.
You could also have env variables in separate files
e.g.

```
    #specifying default in code
    variable "env_name" {
        type = string
        default = "dev"
    }

    #in file
    env_name = "uat"

    #in-line
    terraform plan -var 'env_name=prod'
```

multiple env decisions : state managment, variable data, credentials management

11.) using `terraform workspace new dev`
`terraform workspace select dev`

12.) Terraform module: are for code re-use, terraform registry, root module, modules have versioning, provider inheritance, no count

**other learnings**
1.) the triplet notation: resourceType.resourceName.resourceProperty
2.) ingress allows in bound traffic while egress allows outbound traffic

**TODO learn**
1.) network ACL vs sg vs route table vs IG
2.) vpc vs subnet
3.) DHCP
4.) Elastic IPs - needed when you want an instance to have a static IP.
5.) Network interface
6.) public IPv4 address vs an Elastic IP address
7.) you can have a instance access to different subnets by attaching it to different network interfaces
