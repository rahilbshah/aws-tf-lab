# ROOT MODULE — calls the child modules and wires their outputs -> inputs.
# This file is the "assembly": it says how the pieces connect, not how each
# piece is built (that's inside each module).
#
# After writing each module, run `terraform init` again so Terraform registers
# the new module source.
#
# Start with just the vpc module; add compute + database as you build them.

module "vpc" {
  source = "./modules/vpc"
  # inputs are optional here because the module's variables have defaults;
  # override any you want, e.g.:
  vpc_cidr = "10.0.0.0/16"
}

# ---- add these as you build the modules (shape shown so you see the wiring) ----
#
module "compute" {
  source            = "./modules/compute"
  vpc_id            = module.vpc.vpc_id            # <- output from vpc module
  public_subnet_ids = module.vpc.public_subnet_ids # ALB goes here
  app_subnet_ids    = module.vpc.app_subnet_ids    # ASG goes here
}
#
module "database" {
  source          = "./modules/database"
  vpc_id          = module.vpc.vpc_id
  data_subnet_ids = module.vpc.data_subnet_ids
  app_sg_id       = module.compute.app_sg_id # DB allows only the app tier
  db_password     = var.db_password          # <- from tfvars, NOT hardcoded
  db_port         = 5432
  db_username     = "dbadmin"
  instance_class  = "db.t4g.micro"
}
