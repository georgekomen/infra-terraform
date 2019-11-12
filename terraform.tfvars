key_name = "komen-vm-keys"

private_key_path = "/Users/georgekomen/Documents/aws/komen-vm-keys.pem"

bucket_name_prefix = "komen-s3"

billing_code_tag = "bill-komen"

network_address_space = {
    dev = "10.0.0.0/16"
    uat = "10.1.0.0/16"
    prod = "10.2.0.0/16"
}

instance_size = {
    dev = "t2.micro"
    uat = "t2.small"
    prod = "t2.medium"
}

subnet_count = {
    dev = 2
    uat = 4
    prod = 6
}

instance_count = {
    dev = 2
    uat = 4
    prod = 6
}