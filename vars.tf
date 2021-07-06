variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "myVMs"
}
variable "counter" {
  description = "counter"
  default     = 2
}
variable "location" {
  description = "The location"
  type        = string
  default     = "eastus"
}

# port 22 looking out!!!!!!!!!!!!
variable "inbound_port_ranges" {
  description = "inbound ports"
  default = ["22", "80"]
}

variable "tags" {
  description = "the tags"
  type        = map(string)
  default = {
    owner = "Ars"
  }
}

variable "vnet_cidr" {
  description = "virtual network address space"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vm" {
  description = "prop virt machine"
  type        = map(any)
  default = {
    vm1 = {
      size                 = "Standard_DS1_v2"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
      publisher            = "canonical"
      offer                = "0001-com-ubuntu-server-focal"
      sku                  = "20_04-lts"
      version              = "latest"
      zone                 = "1"
      create_option        = "FromImage"
    }
    vm2 = {
      size                 = "Standard_DS1_v2"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
      publisher            = "canonical"
      offer                = "0001-com-ubuntu-server-focal"
      sku                  = "20_04-lts"
      version              = "latest"
      zone                 = "2"
      create_option        = "FromImage"
    }
  }
}

variable "admin_username" {
  description = "User name"
  default     = "azureuser"
}

# Variables for Key
variable "key_name" {
  description = "key"
  type        = string
  default     = "ident"
}

variable "path" {
  description = "key_path_ssh"
  default     = "~/.ssh/"

}
