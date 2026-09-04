output "nameservers" {
  description = "The four nameservers Route 53 assigned. Nothing delegates to these, so we query them directly."
  value       = aws_route53_zone.this.name_servers
}

output "ns" {
  description = "One nameserver, ready to paste after dig's @ sign."
  value       = aws_route53_zone.this.name_servers[0]
}

output "zone_name" {
  value = var.zone_name
}

output "primary_bucket" {
  description = "Delete index.html from this bucket to break the health check and trigger failover."
  value       = aws_s3_bucket.primary.id
}

output "primary_website_endpoint" {
  description = "What the health check monitors, and what the PRIMARY failover record points at."
  value       = aws_s3_bucket_website_configuration.primary.website_endpoint
}

output "health_check_id" {
  value = aws_route53_health_check.primary.id
}

output "dig_cheatsheet" {
  description = "Copy-paste verification commands."
  value       = <<-EOT

    ns=${aws_route53_zone.this.name_servers[0]}

    dig +short @$ns simple.${var.zone_name} A
    dig +short @$ns weighted.${var.zone_name} A
    dig +short @$ns www.${var.zone_name} CNAME
    dig +short @$ns multivalue.${var.zone_name} A
    dig +short @$ns geo.${var.zone_name} A
    dig +short @$ns latency.${var.zone_name} A

    # fake being somewhere else (EDNS0 client subnet):
    dig +short +subnet=3.5.140.0/24 @$ns geo.${var.zone_name} A    # Seoul
    dig +short +subnet=13.234.0.0/24 @$ns geo.${var.zone_name} A   # Mumbai
  EOT
}
