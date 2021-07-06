#Create resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-rg"
  location = var.location
  tags     = var.tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.resource_group_name}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

}

resource "azurerm_network_security_rule" "mainrules" {
  for_each                    = local.nsgrules
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

#Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

#Create subnet to vm1
resource "azurerm_subnet" "vm1" {
  name                 = "${var.resource_group_name}-vm1-sn"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

#network_security_group_association to vm1
resource "azurerm_subnet_network_security_group_association" "vm1" {
  subnet_id                 = azurerm_subnet.vm1.id
  network_security_group_id = azurerm_network_security_group.main.id
}

#public_ip to vm1
resource "azurerm_public_ip" "vm1" {
  name                = "${var.resource_group_name}-vm1-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  allocation_method   = "Static"
  ip_version          = "IPv4"

  tags = var.tags
}

#Create network interface to vm1
resource "azurerm_network_interface" "vm1" {
  name                = "${var.resource_group_name}-vm1-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm1.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}


#Create subnet to vm2
resource "azurerm_subnet" "vm2" {
  name                 = "${var.resource_group_name}-vm2-sn"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 10)]
}

#network_security_group_association to vm2
resource "azurerm_subnet_network_security_group_association" "vm2" {
  subnet_id                 = azurerm_subnet.vm2.id
  network_security_group_id = azurerm_network_security_group.main.id
}

#public_ip to vm2
resource "azurerm_public_ip" "vm2" {
  name                = "${var.resource_group_name}-vm2-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "standard"
  #availability_zone = var.vm.vm2["zone"]

  tags = var.tags
}

#Create network interface to vm2
resource "azurerm_network_interface" "vm2" {
  name                = "${var.resource_group_name}-vm2-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content              = tls_private_key.example_ssh.private_key_pem
  file_permission      = "0600"
  directory_permission = "0777"
  filename             = "${var.path}${var.key_name}.pem"
}
data "tls_public_key" "example" {
  private_key_pem = file("${var.path}${var.key_name}")
}

#Public key vm1
resource "azurerm_ssh_public_key" "vm1" {
  name                = "${var.resource_group_name}-vm1-key"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  public_key          = file("${var.path}${var.key_name}.pub")
}

#Public key vm2
resource "azurerm_ssh_public_key" "vm2" {
  name                = "${var.resource_group_name}-vm2-key"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  public_key          = file("${var.path}${var.key_name}.pub")
}

#Create VM1
resource "azurerm_linux_virtual_machine" "vm1" {
  name     = "${var.resource_group_name}-vm1"
  location = azurerm_resource_group.main.location
  #availability_set_id   = azurerm_availability_set.avset.id
  size                  = var.vm.vm1["size"]
  resource_group_name   = azurerm_resource_group.main.name
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm1.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${var.path}${var.key_name}.pub")
  }

  zone = var.vm.vm1["zone"]
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true


  os_disk {
    caching = var.vm.vm1["caching"]
    storage_account_type = var.vm.vm1["storage_account_type"]
  }


  source_image_reference {
    publisher = var.vm.vm1["publisher"]
    offer     = var.vm.vm1["offer"]
    sku       = var.vm.vm1["sku"]
    version   = var.vm.vm1["version"]
  }
}


#Create VM2
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "${var.resource_group_name}-vm2"
  location            = azurerm_resource_group.main.location
  size                = var.vm.vm2["size"]
  resource_group_name = azurerm_resource_group.main.name
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.vm2.id]

  admin_ssh_key {
    username = var.admin_username
    public_key = file("${var.path}${var.key_name}.pub")
  }
  zone = var.vm.vm2["zone"]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true


  os_disk {
    caching = var.vm.vm2["caching"]
    storage_account_type = var.vm.vm2["storage_account_type"]
  }


  source_image_reference {
    publisher = var.vm.vm1["publisher"]
    offer     = var.vm.vm1["offer"]
    sku       = var.vm.vm1["sku"]
    version   = var.vm.vm1["version"]
  }

  tags = var.tags
}


#Config inventory Ansible
resource "local_file" "hosts" {
  content = templatefile("hosts.tpl",
    {
      user = var.admin_username,
      web1 = azurerm_public_ip.vm1.ip_address,
      web2 = azurerm_public_ip.vm2.ip_address
    }
  )
  filename = "/etc/ansible/hosts"
}

#run ansible script
resource "null_resource" "sp" {
  depends_on = [time_sleep.wait, azurerm_linux_virtual_machine.vm1, azurerm_linux_virtual_machine.vm2]

  provisioner "local-exec" {
    command = "chmod +x script.sh"
  }

  provisioner "local-exec" {
    command = "./script.sh"
  }
}

resource "time_sleep" "wait" {
  create_duration = "160s"
}


#Public IP LB
resource "azurerm_public_ip" "lb" {
  name                = "${var.resource_group_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "standard"

  tags = var.tags
}

#Create LB
resource "azurerm_lb" "main" {
  name                = "${var.resource_group_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "standard"

  frontend_ip_configuration {
    name                 = "publicIPForLB"
    public_ip_address_id = azurerm_public_ip.lb.id
    #availability_zone = "Zone-Redundant"
  }
}

# probe lb
resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "ssh-running-probe"
  port                = 80
  #protocol            = "TCP"
}

#lb_backend_address_pool
resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  #backend_ip_configurations = [var.vnet_cidr]
  name = "backend_address_pool"
}

#lb_backend_address_pool_address vm2
resource "azurerm_lb_backend_address_pool_address" "vm1" {
  name                    = "vm1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool.id
  virtual_network_id      = azurerm_virtual_network.main.id
  ip_address              = "10.10.1.4"

}

#lb_backend_address_pool_address vm2
resource "azurerm_lb_backend_address_pool_address" "vm2" {
  name                    = "vm2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool.id
  virtual_network_id      = azurerm_virtual_network.main.id
  ip_address              = "10.10.10.4"

}

#lb rule
resource "azurerm_lb_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_address_pool.id
  frontend_ip_configuration_name = "publicIPForLB"
  probe_id                       = azurerm_lb_probe.main.id

}
