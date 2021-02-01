variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
  validation {
    condition = (
      length(trimspace(try(var.infrastructure.region, ""))) != 0
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.environment, ""))) != 0
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.arm_id, ""))) != 0 || ((length(trimspace(try(var.infrastructure.vnets.sap.name, ""))) != 0) && (length(trimspace(try(var.infrastructure.vnets.sap.address_space, ""))) != 0))
    )
    error_message = "Either the arm_id or (name and address_space) of the Virtual Network must be specified in the infrastructure.vnets.sap block."
  }
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "sshkey" {
  description = "Details of ssh key pair"
  default = {
  }
  validation {
    condition = (
      length(var.sshkey) > 1
    )
    error_message = "Either ssh keys or user credentials must be specified."
  }
  validation {
    condition = (
      length(trimspace(var.sshkey.username)) != 0
    )
    error_message = "The default username for the Virtual machines must be specified."
  }
}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default = {
    kv_user_id = "",
    kv_prvt_id = "",
  }
}

variable "diagnostics_storage_account" {
  description = "Storage account information for diagnostics account"
  default     = {
    arm_id = ""
  }
}
