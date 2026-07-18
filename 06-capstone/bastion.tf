# BASTION (Option A) — a public jump host so TablePlus can tunnel to the private RDS.
# Root-level resources (not a module) so they can reference module.vpc + module.database
# outputs directly. Shows: the root can hold its own resources AND wire across modules.
#
# Build:
#   - data.aws_ami.bastion       owners=["self"], tag:BakedBy=packer, most_recent (reuse your image)
#
#   - aws_key_pair.bastion       key_name = "bastion-key"
#                                public_key = file(pathexpand("~/.ssh/saa-c03-learning.pub"))
#
#   - aws_security_group.bastion vpc_id = module.vpc.vpc_id, description + Name tag "bastion-sg"
#   - aws_vpc_security_group_ingress_rule.bastion_ssh
#        cidr_ipv4 = var.my_ip_cidr, ip_protocol = "tcp", from_port/to_port = 22   (SSH from YOU only)
#   - aws_vpc_security_group_egress_rule.bastion
#        cidr_ipv4 = "0.0.0.0/0", ip_protocol = "-1"     (all protocols -> NO from_port/to_port!)
#
#   - aws_instance.bastion
#        ami                    = data.aws_ami.bastion.id
#        instance_type          = "t3.micro"
#        subnet_id              = module.vpc.public_subnet_ids[0]   # PUBLIC subnet -> gets a public IP
#        vpc_security_group_ids = [aws_security_group.bastion.id]
#        key_name               = aws_key_pair.bastion.key_name
#        tags = { Name = "bastion" }
#
#   THE CROSS-MODULE LINK — let the bastion reach RDS (a rule on the DB's SG,
#   which is a database-MODULE output; referencing the bastion SG created here):
#   - aws_vpc_security_group_ingress_rule.db_from_bastion
#        security_group_id            = module.database.db_sg_id      # <- module output
#        referenced_security_group_id = aws_security_group.bastion.id # <- root resource
#        ip_protocol = "tcp", from_port/to_port = 5432
#
#   - output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
#     (add this to outputs.tf, or here — it's the root, either works)
#
# No `terraform init` needed (no new module/provider) — just fmt -> validate -> plan -> apply.
#
# Then in TablePlus, "Over SSH":
#   SSH  host = <bastion_public_ip>, user = ubuntu, key = ~/.ssh/saa-c03-learning
#   DB   host = <RDS endpoint (no :5432)>, port 5432, user dbadmin,
#        password = your tfvars value, database = postgres

data "aws_ami" "bastion" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "tag:BakedBy"
    values = ["packer"]
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = file(pathexpand("~/.ssh/saa-c03-learning.pub"))
}

resource "aws_security_group" "bastion" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "bastion" {
  cidr_ipv4         = var.my_ip_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.bastion.id
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.bastion.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion.key_name

  tags = {
    Name = "bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_bastion" {
  security_group_id            = module.database.db_sg_id
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
