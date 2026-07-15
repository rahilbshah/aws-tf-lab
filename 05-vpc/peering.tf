# 05.3 – VPC Peering (FREE): connect this VPC to a second one
#
# Peering connects two VPCs so they talk over the AWS backbone using PRIVATE IPs.
# Limits to remember: NON-TRANSITIVE (A-B and B-C does NOT give A-C) and NO
# OVERLAPPING CIDRs. Our main VPC is 10.0.0.0/16, so the peer uses 10.1.0.0/16.
#
#   A. A second, minimal VPC to peer with:
#      aws_vpc.peer            - cidr_block = "10.1.0.0/16", tags Name = "vpc-peer"
#      (that's enough to demonstrate peering + routes; add a subnet only if you
#       want to launch something to ping across)
#
#   B. The peering connection:
#      aws_vpc_peering_connection.this
#        - vpc_id      = aws_vpc.this.id     (requester)
#        - peer_vpc_id = aws_vpc.peer.id     (accepter)
#        - auto_accept = true                (works because same account + region)
#        - tags Name = "main-to-peer"
#
#   C. Routes on BOTH sides (peering needs both route tables updated — this is the
#      step people forget, and traffic silently fails without it):
#      aws_route.main_to_peer
#        - route_table_id            = aws_route_table.private.id   (main side)
#        - destination_cidr_block    = "10.1.0.0/16"                (the PEER's range)
#        - vpc_peering_connection_id = aws_vpc_peering_connection.this.id
#      aws_route.peer_to_main
#        - route_table_id            = aws_vpc.peer.main_route_table_id  (peer side —
#                                       the peer VPC's auto-created main RT)
#        - destination_cidr_block    = "10.0.0.0/16"                (MAIN's range)
#        - vpc_peering_connection_id = aws_vpc_peering_connection.this.id
#
# After apply: Peering connections console shows status "Active". Both route
# tables now have a route to the other VPC's CIDR via the pcx-... connection.
# Remember: this is point-to-point. A third VPC would need its OWN peerings
# (non-transitive) — n(n-1)/2 mesh — which is the "why Transit Gateway exists"
# lesson (TGW = hub-and-spoke, conceptual-only, see 05-vpc-endpoints-peering note).

resource "aws_vpc" "peer" {
  cidr_block = "10.1.0.0/16"

  tags = {
    "Name" = "vpc-peer"
  }
}

resource "aws_vpc_peering_connection" "this" {
  vpc_id      = aws_vpc.this.id
  peer_vpc_id = aws_vpc.peer.id
  auto_accept = true

  tags = {
    "Name" = "main-to-peer"
  }
}

resource "aws_route" "main_to_peer" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "peer_to_main" {
  route_table_id            = aws_vpc.peer.main_route_table_id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
