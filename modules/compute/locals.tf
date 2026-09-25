locals {
  tags = merge(
    var.common_tags,
    {
      managed_by = "terraform"
    }
  )

  names = {
    app_service_plan = "${var.name_prefix}-asp"
    app_service      = "${var.name_prefix}-app"
  }
}
