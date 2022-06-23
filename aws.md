AWS:

1. VPC peering between 2 AWS accounts - good use case is having security tools with limited access in one account and the other services in the other aws account

But how can a resource in one account access a resource in the other: using roles e.g., in vpc peering, you can create a peering role in the security account and give a resource in the other account access to the peering role.

Steps:
**1.** In the security account, using IAM, create a policy to allow describing of a peering connection and then accept appending of the peering connectiong from another vpc.
**2.** Create a peering role and assign the policy to the role. If someone assumes this role, they get the permissions defined in the policy.
**3.** In the other dev account, create a policy: assume_role_policy that allows users in the dev account to assume the peering role in the security account. We then assign that policy to the peering group.
**4.** Add individuals to the peering group to get the permissions to create peering connection to the security account.

Terraform :
**1.** variables in .ts file, values in .tfvars file
**2.** providers in .tf file, you can have more than one provider e.g., for different AWS accounts in same or different regions (also requires different aws profiles in your machine that contain creds e.g., secret keys for the different accounts), for same AWS accounts in different regions
**3.** data sources, format is data source resource name and its local name
**4.** resources e.g., vpc, ec2 machines etc.
**5.** outputs, print out values after resource creation.
**6.** locals - overriding variable values.

-   If you have more than than one profile in your terraform config then you should specify the provider alias/name in every resource or data source in your config. Your provider should also specify the profile and alias/name for the provider.
-   assume_role_policy in a role means another AWS account can assume this role. The assume role policy also needs the principle (the other AWS account id) specified.

-   what is intra subnets?
-   plural sight course on AWS terraform: https://www.pluralsight.com/courses/implementing-terraform-aws
-   assume_role inside a provider scope means we want to assume a role that's in another account
-   how to create a vpc peering connection between two accounts: https://app.pluralsight.com/course-player?clipId=14c7aadd-a4d0-4607-832a-a7fc25687ea6

When you need VPC peering:
**1.** VPCs are in different AWS accounts.
**2.** VPCs are in same account but in different regions.
**3.** 2 VPCs in thesame account.

-   gitLabs vs gitOps?

Authentication methods:
**1.** instance profiles
**2.** access keys and secret keys
**3.** credentials file and profile
**4.** session profile

IAC fundamentals:

-   infrastructure defined in a software defined way
-   your configurations are able to adopt software development principles like reusability and repeatability (e.g., terraform modules)
-   source control e.g., with git
-   automation to multiple envs (CICD)

Terraform work spaces:

-   Terraform workspaces uses the same configuration but the difference is the state.
-   this feature supports deployment to multiple environments
-   you define the terraform workspace with terraform.workspace

AWS Code tools:

-   code commit - source control
-   code build - continuous deployment
-   code pipeline - deploy code in stages accross multiple environments
