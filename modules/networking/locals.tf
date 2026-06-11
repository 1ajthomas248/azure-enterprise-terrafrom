locals {
  tags = merge(
    var.common_tags,
    {
      managed_by = "terraform"
    }
  )

  names = {
    app_nsg     = "${var.name_prefix}-nsg-app"
    vm_nsg      = "${var.name_prefix}-nsg-vm"
    bastion     = "${var.name_prefix}-bastion"
    bastion_pip = "${var.name_prefix}-pip-bastion"
    appgw_pip   = "${var.name_prefix}-pip-appgw"
    appgw       = "${var.name_prefix}-appgw-main"
  }
}