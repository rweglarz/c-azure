module "vpc-fw-1" {
  source = "../../ce-aws/modules/vpc"

  name = "${var.name}-fw-1"

  cidr_block              = var.aws_cidr
  public_mgmt_prefix_list = "pl-0139bb989ef6d1988"

  deploy_igw  = true
  connect_tgw = false

  subnets = {
    "mgmt" : { "idx" : 0, "zone" : var.aws_availability_zones[0] },
    "isp1" : { "idx" : 1, "zone" : var.aws_availability_zones[0] },
    "isp2" : { "idx" : 2, "zone" : var.aws_availability_zones[0] },
    "priv" : { "idx" : 3, "zone" : var.aws_availability_zones[0] },
    "host" : { "idx" : 4, "zone" : var.aws_availability_zones[0] },
  }
}

module "vm-fw-1" {
  source = "../../ce-aws/modules/vmseries"

  name             = "${var.name}-fw-1"
  fw_instance_type = "m5.xlarge"

  key_pair = "rweglarz"
  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_pub"],
    var.bootstrap_options["aws1"],
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.vpc-fw-1.subnets["mgmt"].id
      security_group_ids = [
        module.vpc-fw-1.sg_public_id,
        module.vpc-fw-1.sg_private_id,
      ]
      private_ips = [cidrhost(module.vpc-fw-1.subnets["mgmt"].cidr_block, 5)]
    }
    isp1 = {
      device_index = 1
      public_ip    = true
      subnet_id    = module.vpc-fw-1.subnets["isp1"].id
      private_ips  = [cidrhost(module.vpc-fw-1.subnets["isp1"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-fw-1.sg_open_id,
      ]
    }
    isp2 = {
      device_index = 2
      public_ip    = true
      subnet_id    = module.vpc-fw-1.subnets["isp2"].id
      private_ips  = [cidrhost(module.vpc-fw-1.subnets["isp2"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-fw-1.sg_open_id,
      ]
    }
    priv = {
      device_index = 3
      subnet_id    = module.vpc-fw-1.subnets["priv"].id
      private_ips  = [cidrhost(module.vpc-fw-1.subnets["priv"].cidr_block, 5)]
      security_group_ids = [
        module.vpc-fw-1.sg_open_id,
      ]
    }
  }
}

resource "aws_route_table_association" "aws1-mgmt-dg" {
  subnet_id      = module.vpc-fw-1.subnets["mgmt"].id
  route_table_id = module.vpc-fw-1.route_tables["via_igw"]
}
resource "aws_route_table_association" "aws1-isp1-dg" {
  subnet_id      = module.vpc-fw-1.subnets["isp1"].id
  route_table_id = module.vpc-fw-1.route_tables["via_igw"]
}
resource "aws_route_table_association" "aws1-isp2-dg" {
  subnet_id      = module.vpc-fw-1.subnets["isp2"].id
  route_table_id = module.vpc-fw-1.route_tables["via_igw"]
}

resource "aws_ec2_managed_prefix_list_entry" "aws-pa-vm" {
  for_each       = { for k, v in module.vm-fw-1.public_ips : k => v if length(regexall("mgmt", k)) > 0 }
  cidr           = "${each.value}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "${var.name}-aws-azure-vwan"
}

output "vm-fw-1" {
  value = module.vm-fw-1.public_ips
}
