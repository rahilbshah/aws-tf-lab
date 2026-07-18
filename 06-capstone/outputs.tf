# ROOT outputs — re-export module outputs so `terraform output` (the CLI) shows them.
#
# Key module concept: a child module's outputs are visible to its CALLER (this
# root) as module.<name>.<output>, but they are NOT automatically surfaced to the
# CLI. You must re-declare them here at the root to see them with `terraform output`.
# (Outputs bubble up exactly one level — the caller decides what to expose further.)

output "alb_dns_name" {
  description = "Public URL of the app — hit this in a browser"
  value       = module.compute.alb_dns_name
}

output "db_endpoint" {
  description = "RDS endpoint (private, app-tier only)"
  value       = module.database.db_endpoint
}
