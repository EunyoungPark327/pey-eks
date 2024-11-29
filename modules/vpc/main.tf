
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.vpc_name
  cidr   = var.vpc_cidr

  azs             = var.azs
  public_subnets  = [for i in range(0, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(0, 2) : cidrsubnet(var.vpc_cidr, 8, i + 32)]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Name        = var.vpc_name
    Environment = var.env
  }

  public_subnet_tags = {
    "Name"                                      = "${var.vpc_name}-pub"
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "Name"                                      = "${var.vpc_name}-prv"
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  public_route_table_tags = {
    "Name" = "${var.vpc_name}-pub-rtb"
  }
  private_route_table_tags = {
    "Name" = "${var.vpc_name}-prv-rtb"
  }
}
