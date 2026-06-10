locals {
  tags = merge(
    var.common_tags,
    {
      managed_by = "terraform"
    }
  )
}