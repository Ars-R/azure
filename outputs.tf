
output "lb_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "vm1_ip" {
  value = azurerm_public_ip.vm1.ip_address
}

output "vm2_ip" {
  value = azurerm_public_ip.vm2.ip_address
}
