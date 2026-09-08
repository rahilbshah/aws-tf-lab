# ==========================================================================
# Three tiers x N AZs. This is where you meet for_each properly.
#
# In 17-ecs-alb you wrote public_a, public_b, private_a, private_b as four
# near-identical resource blocks. A module cannot do that - it does not know
# how many AZs the caller wants. So: one resource block per TIER, iterating
# over AZs.
#
#   for_each = toset(local.azs)
#
# Why toset and not the list: with a list, for_each keys would be 0,1,2 and
# inserting an AZ at the front would RENUMBER everything and destroy/recreate
# subnets that did not change. Keyed by AZ NAME, the address is
# aws_subnet.public["us-east-1a"] and it is stable forever.
# That is the whole argument for for_each over count, in one sentence.
# ==========================================================================

# CIDR MATH — how cidrsubnet actually works
#
# cidrsubnet(prefix, newbits, netnum) takes three arguments:
#
#   prefix   the block you are slicing up          "10.10.0.0/16"
#   newbits  how many bits to ADD to the prefix    8  ->  /16 + 8 = /24
#   netnum   WHICH slice you want, counting from 0
#
# THE SHORTCUT THAT MAKES IT CLICK: when you go /16 -> /24, netnum is
# literally the third octet. Verified in `terraform console`:
#
#   cidrsubnet("10.10.0.0/16", 8,  0)  =>  10.10.0.0/24
#   cidrsubnet("10.10.0.0/16", 8,  1)  =>  10.10.1.0/24
#   cidrsubnet("10.10.0.0/16", 8, 10)  =>  10.10.10.0/24
#   cidrsubnet("10.10.0.0/16", 8, 20)  =>  10.10.20.0/24
#
# That shortcut is only true for newbits = 8. Change it and the arithmetic
# changes:  cidrsubnet("10.10.0.0/16", 4, 1)  =>  10.10.16.0/20
#
# WHY THE 0 / 10 / 20 OFFSETS: so the third octet tells you the tier at a
# glance, forever. 10.10.20.x is isolated. You never have to look it up.
#
#   public    netnum = index                10.10.0.x   10.10.1.x
#   private   netnum = index + 10           10.10.10.x  10.10.11.x
#   isolated  netnum = index + 20           10.10.20.x  10.10.21.x
#
# THE MISSING PIECE — turning an AZ name into a number.
# for_each gives you each.key = "us-east-1a", a STRING. cidrsubnet needs a
# NUMBER. index() converts one to the other:
#
#   index(["us-east-1a","us-east-1b"], "us-east-1b")  =>  1
#
# so  index(local.azs, each.key)  is the position of the AZ you are currently
# iterating over. That is your netnum, before you add the tier offset.
#
# PREREQUISITE: local.azs must exist first — that is the `locals` block in
# TODO(1) in vpc.tf. Without it nothing in this file resolves.
#
# THE ALTERNATIVE you are choosing against: pass three list(string) variables
# in and index them. More explicit and greppable, but the caller has to
# recount by hand every time az_count changes. Computing scales; listing is
# readable. Either is defensible — just pick on purpose.

# TODO(4) aws_subnet.public — for_each over the AZs
#         vpc_id, availability_zone = each.key
#         cidr_block              = see the math above
#         map_public_ip_on_launch = true
#         tags = { Name = "${var.name}-public-${each.key}", Tier = "public" }

# TODO(5) aws_subnet.private — for_each over the AZs
#         Same shape. NO map_public_ip_on_launch.
#         tags Tier = "private"

# TODO(6) aws_subnet.isolated — for_each over the AZs
#         Same shape. NO map_public_ip_on_launch.
#         tags Tier = "isolated"
#
#   Tagging the tier is not decoration. When you are staring at 6 subnets in
#   the console at 2am, "which of these can reach the internet" is the first
#   question you will ask.

resource "aws_subnet" "public" {
  for_each                = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key))
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key) + 10)

  tags = {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_subnet" "isolated" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.key) + 20)

  tags = {
    Name = "${var.name}-isolated-${each.key}"
    Tier = "isolated"
  }
}



