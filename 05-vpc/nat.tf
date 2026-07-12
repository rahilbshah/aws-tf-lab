# NAT gateway — the PAID peek. Do NOT write this until the core in network.tf
# applies cleanly. This is what finally gives private-subnet instances OUTBOUND
# internet (e.g. apt install) while still blocking unsolicited inbound.
#
# Cost: NAT gateway ~$0.045/hr + per-GB data processing. Drawn from your AWS
# credit, not your card. Destroy at end of session.
#
#   8.  aws_eip.nat            – one Elastic IP for the NAT gateway (domain = "vpc")
#   9.  aws_nat_gateway.this   – lives in a PUBLIC subnet (needs the IGW path);
#                                allocation_id = the EIP, subnet_id = a public subnet
#  10.  aws_route.private_nat  – on the PRIVATE route table: 0.0.0.0/0 -> nat gateway id
#                                (add as a separate aws_route, or as an inline route on the
#                                 private route table in network.tf — pick one place)
#
# Notice the asymmetry: the NAT gateway sits in a PUBLIC subnet but serves the
# PRIVATE subnets. That trips people up — say why to yourself before you build it.


resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public_a.id

  depends_on = [ aws_internet_gateway.this ]
}

resource "aws_route" "private_nat" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this.id
}