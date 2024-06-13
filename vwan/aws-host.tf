module "aws_srv" {
  source = "../../ce-aws/modules/linux"

  name          = "${var.name}-aws-vwan-srv"
  key_name      = "rweglarz"

  subnet_id  = module.vpc-fw-1.subnets.host.id
  private_ip = cidrhost(module.vpc-fw-1.subnets.host.cidr_block, 10)
  vpc_security_group_ids = [
    module.vpc-fw-1.sg_public_id,
    module.vpc-fw-1.sg_private_id,
  ]
}

resource "aws_route_table" "aws_srv" {
  vpc_id = module.vpc-fw-1.vpc.id
  tags = {
    Name = "${var.name}-vwan-aws-srv"
  }
}

resource "aws_route_table_association" "aws_srv" {
  subnet_id      = module.vpc-fw-1.subnets.host.id
  route_table_id = aws_route_table.aws_srv.id
}

resource "aws_route" "aws_srv_dg" {
  route_table_id         = aws_route_table.aws_srv.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc-fw-1.internet_gateway_id
}

resource "aws_route" "aws_srv_private" {
  for_each               = toset([
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ])
  route_table_id         = aws_route_table.aws_srv.id
  destination_cidr_block = each.key
  network_interface_id   = module.vm-fw-1.eni.priv
}
