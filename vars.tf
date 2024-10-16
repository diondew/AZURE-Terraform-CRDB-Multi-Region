# ----------------------------------------
# My IP Address
# This is used in the creation of the security group 
# and will allow access to the ec2-instances on ports
# 22 (ssh), 26257 (database), 8080 (for observability)
# and 3389 (rdp)
# ----------------------------------------
    variable "my_ip_address" {
      description = "User IP address for access to the ec2 instances."
      type        = string
      default     = "0.0.0.0"
    }

# ----------------------------------------
# Globals
# ----------------------------------------
    variable "resource_name" {
      description = "resource names will usually be the concatenation of var.owner-var.resource_name-resourceType and also a count.index if there are mulitple resources"
      type        = string
      default     = "demo"
      nullable    = false
    }
    variable "owner" {
      description = "Owner of the infrastructure"
      type        = string
      nullable    = false
    }

# ----------------------------------------
# Multi-Region
# ----------------------------------------    
    # Please leave these variables as is.  When using this as a module in the multi-region setup, these will be passed in.  For single region, leave as is.  Total hack.
    variable "multi_region" {
      type        = bool
      default     = true
    }

# ----------------------------------------
# Existing Key Info
# ----------------------------------------
    variable "azure_ssh_key_name" {
      description = "The name of an existing ssh key in Microsoft Azure"
      type    = string      
    }
    variable "azure_ssh_key_resource_group" {
      description = "The name of the resource group containing the existing Microsoft Azure SSH Key"
      type        = string
    }

# ----------------------------------------
# Resource Group
# ----------------------------------------
    variable "resource_group_location" {
      # where do you want the resource group, that is created as part of this HCL to be located?  This is the metadata store location.
      # you must leave the default as an empty string.  for single region, pass in the value in terraform.tfvars.  for multi-region, pass in the value.
      type    = string
      default = ""
    }

# ----------------------------------------
# TAGS
# ----------------------------------------
    # owner will be applied to all resources that accept tags along with any other optional tags specified here. 
    # Optional tags
    variable "resource_tags" {  #! Not in terraform.tfvars
      description = "Tags to set for all resources"
      type        = map(string)
      default     = {}
    }

# ----------------------------------------
# CRDB Regions
# ----------------------------------------
    variable "virtual_network_locations" {
      description = "list of the Azure regions for the multi-region crdb cluster"
      type = list
      default = ["westus2", "centralus", "eastus2"]
    }

# ----------------------------------------
# Network
# ----------------------------------------
    variable "virtual_network_cidr_blocks" {
      description = "CIDR block for the VPC"
      type        = list
      default     = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
    }

# ----------------------------------------
# CRDB Instance Specifications
# Azure names available here: https://azureprice.net/
# ----------------------------------------
    variable "crdb_vm_size" {
      description = "The Azure instance type for the crdb instances."
      type        = string
      default     = "Standard_D4ps_v5" #arm
    }
    variable "crdb_nodes" { #! Not in terraform.tfvars (ok)
      description = "Number of crdb nodes PER REGION.  This should be a multiple of 3.  Each node is an Azure Instance"
      type        = number
      default     = 3
      validation {
        condition = var.crdb_nodes%3 == 0
        error_message = "The variable 'crdb_nodes' must be a multiple of 3"
      }
    }
    variable "crdb_store_disk_size" {
      description = "Size of the data disk attached to the vm.  This is not the OS disk size, but the size of the disk available for CRDB data and logs"
      type        = number
      default     = 64
      validation {
        condition = contains([64, 128, 256, 512], var.crdb_store_disk_size)
        error_message = "CRDB Node disk size (in GB) must be 64, 128, 256 or 512"
      }
    }

    variable "crdb_arm_release" {
      description = "Do you want to use the ARM version of CRDB?  There are implications on the instances available for the installation.  You must choose the correct instance type or this will fail.  See https://learn.microsoft.com/en-us/azure/virtual-machines/dpsv5-dpdsv5-series"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.crdb_arm_release)
        error_message = "Valid value for variable 'arm' is : 'yes' or 'no'"        
      } 
    }
    variable "crdb_enable_spot_instances" {
      description = "Do you want to use SPOT instances?  There are implications on the instances available for the installation.  You must choose the correct instance type or this will fail."
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.crdb_enable_spot_instances)
        error_message = "Valid value for variable 'spot instances' is : 'yes' or 'no'"        
      } 
    }
# ----------------------------------------
# CRDB Admin User - Cert Connection
# ----------------------------------------
    variable "create_admin_user" { 
      description = "'yes' or 'no' to create an admin user in the database.  This might only makes sense when adding an app instance since the certs will be created and configured automatically for connection to the database."
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.create_admin_user)
        error_message = "Valid value for variable 'include_ha_proxy' is : 'yes' or 'no'"        
      }      
    }
    variable "admin_user_name"{
      description = "An admin with this username will be created if 'create_admin_user=yes'"
      type        = string
      default     = ""
    }

# ----------------------------------------
# CRDB Specifications
# ----------------------------------------
    variable "crdb_version" {
      description = "CockroachDB Version"
      type        = string
      default     = "23.2.12"
    }
    variable "run_init" { #! not in terraform.tfvars, but I think I want to leave it in case, for whatever reason, I don't want to run the init.
      description = "'yes' or 'no' to run init on the database.  In a multi-region configuration, only run the init in one of the regions."
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.run_init)
        error_message = "Valid value for variable 'run_init' is : 'yes' or 'no'"        
      }
    }

# ----------------------------------------
# Cluster Enterprise License Keys
# ----------------------------------------
  variable "install_enterprise_keys" {
    description = "Setting this to 'yes' will attempt to install enterprise license keys into the cluster.  The environment variables (TF_VAR_cluster_organization and TF_VAR_enterprise_license)"
    type = string
    default = "no"
    validation {
      condition = contains(["yes", "no"], var.install_enterprise_keys)
      error_message = "Valid value for variable 'install_enterprise_keys' is : 'yes' or 'no'"        
    }
  }

  # Be sure to do the following in your environment if you plan on installing the license keys
  #   export TF_VAR_cluster_organization='your cluster organization'
  #   export TF_VAR_enterprise_license='your enterprise license'
  variable "cluster_organization" { #! Not in terraform.tfvars
    type = string  
    default = "" 
  }
  variable "enterprise_license"   { #! Not in terraform.tfvars
    type = string  
    default = "" 
  }
# ----------------------------------------
# Cluster Location Data - For console map
# ----------------------------------------
  variable "install_system_location_data" {
    description = "Setting this to 'yes' will attempt to install data in the system.location table.  The data will be used by the console to display cluster node locations)"
    type = string
    default = "no"
    validation {
      condition = contains(["yes", "no"], var.install_system_location_data)
      error_message = "Valid value for variable 'install_system_location_data' is : 'yes' or 'no'"        
    }
  }

# ----------------------------------------
# HA Proxy Instance Specifications
# ----------------------------------------
    variable "include_ha_proxy" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.include_ha_proxy)
        error_message = "Valid value for variable 'include_ha_proxy' is : 'yes' or 'no'"        
      }
    }

    variable "haproxy_vm_size" {
      description = "The Azure instance type for the crdb instances HA Proxy Instance"
      type        = string
      default     = "Standard_B1ms"
    }

# ----------------------------------------
# APP Instance Specifications
# ----------------------------------------
    variable "include_app" {
      description = "'yes' or 'no' to include an APP Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.include_app)
        error_message = "Valid value for variable 'include_app' is : 'yes' or 'no'"        
      }
    }

    variable "app_vm_size" {
      description = "The Azure instance type for the crdb instances app Instance"
      type        = string
      default     = "Standard_B1ms"
    }

    variable "app_disk_size" {
      description = "Size of the disk attached to the vm"
      type        = number
      default     = 64
      validation {
        condition = contains([64, 128, 256, 512], var.app_disk_size)
        error_message = "CRDB Node disk size (in GB) must be 64, 128, 256 or 512"
      }
    }

    # Note that app_resize_homelv is dangerous.  Only use this option if you  use the redhat source image and only if you are sure
    # that sda2 contains the lv "rootvg-homelv".   This procedure will add any unused space to homelv.  This is dangerous and a hack.
    variable "app_resize_homelv" {
      description = "When creating a larger disk than exists in the image you'll need to repartition the disk to use the remaining space."
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.app_resize_homelv)
        error_message = "Valid value for variable 'crdb_resize_homelv' is : 'yes' or 'no'"        
      }  
    }

# ----------------------------------------
# Demo
# ----------------------------------------
    variable "include_demo" { #! Not in terraform.tfvars
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.include_demo)
        error_message = "Valid value for variable 'include_demo' is : 'yes' or 'no'"        
      }
    }

# ----------------------------------------
# UI Cert (so that the database console does not issue "Your connection is not private" warning)
# When accessing the database console on 8080, unless there is a certificate signed by an authority 
# accepted by the browser, an error message will be displayed.  If you have a domain name and can 
# associate the IP of the CRDB via a DNS "A" record, then a certifiate can be generated
# via Let's Encrypt / certbot.  
# To generate the cert, FIRST assoicate the public IP of the CRDB node with the domain name
# and then run the bash function "UICERT".   For certbot to generate the certs, you must 
# supply the domain name and email address.  
# ----------------------------------------
    variable "include_uicert" {
      description = "'yes' or 'no' to include the UICERT function in the .bashrc of the CRDB instances.  This also opens port 80 to the world on the CRDB instances for certbot."
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.include_uicert)
        error_message = "Valid value for variable 'include_uicert' is : 'yes' or 'no'"        
      }
    }
    variable "uicert_domain_name" {
      description = "The domain name that will be passed to certbot for the cert."
      type        = string
      default     = ""
    }
    variable "uicert_email_address" {
      description = "The email address to be associated with the cert.  This is required if choosing to generate a CA cert for the ui."
      type        = string
      default     = ""
    }


# ----------------------------------------
# TLS Vars -- Leave blank to have then generated
# ----------------------------------------
    # For multi-region these are probably not needed, but I'm leaving them in case the user wants to pass them in.
    # For single region, they are DEFINITLY needed so that they can all be generated once in the multi-region HCL
    # and then passed to the single region module.
    variable "tls_private_key" {
      description = "tls_private_key.crdb_ca_keys.private_key_pem -> ca.key / TLS Private Key PEM"
      type        = string
      default     = ""
    }

    variable "tls_public_key" {
      description = "tls_private_key.crdb_ca_keys.public_key_pem -> ca.pub / TLS Public Key PEM"
      type        = string
      default     = ""
    }

    variable "tls_cert" {
      description = "tls_self_signed_cert.crdb_ca_cert.cert_pem -> ca.crt / TLS Cert PEM"
      type        = string
      default     = ""
    }

    variable "tls_self_signed_cert" {
      description = "tls_self_signed_cert.crdb_ca_cert.cert_pem -> ca.crt / TLS Cert PEM  /  Duplicate of tls_cert for better naming"
      type        = string
      default     = ""
    }

    variable "tls_user_cert" {
      description = "tls_locally_signed_cert.user_cert.cert_pem -> client.name.crt"
      type        = string
      default     = ""
    }

    variable "tls_locally_signed_cert" {
      description = "tls_locally_signed_cert.user_cert.cert_pem -> client.name.crt / Duplicate of tls_user_cert for better naming"
      type        = string
      default     = ""
    }

    variable "tls_user_key" {
      description = "tls_private_key.client_keys.private_key_pem -> client.name.key"
      type        = string
      default     = ""
    }
