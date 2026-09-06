# ==========================================================================
# NAT gateways. The only expensive thing in this module.
#
# var.nat_gateway_count drives how many. The trick is that the number of NAT
# gateways and the number of AZs are DIFFERENT numbers, and the routing has
# to cope with any combination.
# ==========================================================================

# TODO(7) aws_eip.nat — for_each or count over var.nat_gateway_count
#         domain = "vpc"   (NOT the deprecated `vpc = true`)
#         tags   = { Name = "${var.name}-nat-eip-N" }
#
#         Remember from 13-cost-optimization: a public IPv4 address bills
#         $0.005/hr whether attached or not. These are attached, but if a
#         destroy ever half-fails, an orphaned EIP is the classic silent
#         charge. It is the first thing we check after every teardown.

# TODO(8) aws_nat_gateway.this — same count as the EIPs
#         allocation_id = the matching EIP
#         subnet_id     = a PUBLIC subnet   <- say why out loud before writing
#         depends_on    = [aws_internet_gateway.this]
#
#         The depends_on is real, not defensive: a NAT gateway needs a working
#         route to the internet at creation time, and Terraform cannot infer
#         the IGW dependency from the arguments alone.
#
#         INDEXING NOTE, worth getting right: if nat_gateway_count is 1 but
#         az_count is 2, you have NAT[0] only. The private route table for AZ
#         index 1 must still point somewhere - at NAT[0]. A clean way to
#         express that is to pick the NAT with
#             min(index(local.azs, az), var.nat_gateway_count - 1)
#         so 1 NAT serves both AZs, and 2 NATs serve one AZ each, with the
#         same expression. Handle nat_gateway_count = 0 separately - then
#         there is no default route at all.
