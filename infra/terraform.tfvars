parent_folder   = "folders/51285667990"
billing_account = "010767-AD0D5D-BCC8F6"
regions = [
  {
    region           = "europe-west1"
    ip_cidr          = "10.0.0.0/18"
    ip_cidr_pods     = "10.0.64.0/18"
    ip_cidr_services = "10.0.128.0/18"
    master_ipv4_cidr = "10.0.192.0/28"
    release_channel  = "RAPID"
  },
  {
    region           = "us-east1"
    ip_cidr          = "10.1.0.0/18"
    ip_cidr_pods     = "10.1.64.0/18"
    ip_cidr_services = "10.1.128.0/18"
    master_ipv4_cidr = "10.1.192.0/28"
    release_channel  = "RAPID"
  },
]
