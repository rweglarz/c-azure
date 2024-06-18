module "aws_vpc" {
  source = "../../ce-aws/modules/vpc"

  name = "${var.name}-fw"

  cidr_block              = cidrsubnet(var.ext_spokes_cidr, 4, 0)
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

module "aws_fw" {
  source = "../../ce-aws/modules/vmseries"

  name             = "${var.name}-fw"
  fw_instance_type = "m5.xlarge"

  key_pair = "rweglarz"
  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["aws_fw"],
  )

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.aws_vpc.subnets["mgmt"].id
      security_group_ids = [
        module.aws_vpc.sg_public_id,
        module.aws_vpc.sg_private_id,
      ]
      private_ips = [cidrhost(module.aws_vpc.subnets["mgmt"].cidr_block, 5)]
    }
    isp1 = {
      device_index = 1
      public_ip    = true
      subnet_id    = module.aws_vpc.subnets["isp1"].id
      private_ips  = [cidrhost(module.aws_vpc.subnets["isp1"].cidr_block, 5)]
      security_group_ids = [
        module.aws_vpc.sg_open_id,
      ]
    }
    isp2 = {
      device_index = 2
      public_ip    = true
      subnet_id    = module.aws_vpc.subnets["isp2"].id
      private_ips  = [cidrhost(module.aws_vpc.subnets["isp2"].cidr_block, 5)]
      security_group_ids = [
        module.aws_vpc.sg_open_id,
      ]
    }
    priv = {
      device_index = 3
      subnet_id    = module.aws_vpc.subnets["priv"].id
      private_ips  = [cidrhost(module.aws_vpc.subnets["priv"].cidr_block, 5)]
      security_group_ids = [
        module.aws_vpc.sg_open_id,
      ]
    }
  }
}

resource "aws_route_table_association" "aws1-mgmt-dg" {
  subnet_id      = module.aws_vpc.subnets["mgmt"].id
  route_table_id = module.aws_vpc.route_tables["via_igw"]
}
resource "aws_route_table_association" "aws1-isp1-dg" {
  subnet_id      = module.aws_vpc.subnets["isp1"].id
  route_table_id = module.aws_vpc.route_tables["via_igw"]
}
resource "aws_route_table_association" "aws1-isp2-dg" {
  subnet_id      = module.aws_vpc.subnets["isp2"].id
  route_table_id = module.aws_vpc.route_tables["via_igw"]
}
