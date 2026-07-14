# 05.2 – VPC Security: Network ACL on the public subnets
#
# All .tf files merge; this groups the NACL. A NACL is stateless + subnet-level,
# so you configure BOTH directions AND remember ephemeral return ports.
#
#   A. aws_network_acl.public
#        - vpc_id      = aws_vpc.this.id
#        - subnet_ids  = [public-a, public-b]   (associate it to the public subnets)
#        - tags Name = "public-nacl"
#
#   B. Rules — write as inline ingress{}/egress{} blocks on the NACL above,
#      OR as separate aws_network_acl_rule resources. Pick ONE, don't mix.
#      rule_number sets PRECEDENCE (lower = evaluated first, first match wins).
#
#      INGRESS (inbound to the subnet):
#        #100  DENY   all from 203.0.113.50/32   <-- a blocked IP; proves precedence
#                                                    (put a low number so it beats the allows)
#        #110  ALLOW  tcp 80    from 0.0.0.0/0    (client HTTP requests)
#        #120  ALLOW  tcp 443   from 0.0.0.0/0    (client HTTPS requests)
#        #130  ALLOW  tcp 22    from <your IP>/32 (admin SSH — not 0.0.0.0/0)
#        #140  ALLOW  tcp 1024-65535 from 0.0.0.0/0  <-- EPHEMERAL: return traffic for
#                                                        connections the instances initiated
#                                                        outbound (apt/yum responses, etc.)
#
#      EGRESS (outbound from the subnet):
#        #100  ALLOW  tcp 80    to 0.0.0.0/0      (instances reaching out)
#        #110  ALLOW  tcp 443   to 0.0.0.0/0
#        #120  ALLOW  tcp 1024-65535 to 0.0.0.0/0 <-- EPHEMERAL: your server's RESPONSE goes
#                                                     back to each CLIENT's ephemeral port
#
#   Notice: rule #100 DENY 203.0.113.50 wins over #110-#140 ALLOW because lower
#   rule_number is evaluated first. That's the Q2 precedence lesson, live.
#   Also notice there's an implicit final "* DENY all" AWS adds you can't remove.

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "203.0.113.50/32"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "183.82.198.65/32"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }


  tags = {
    Name = "public-nacl"
  }
}

