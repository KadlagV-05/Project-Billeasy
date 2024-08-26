provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Billeasy_F/VPC"
  }
}

resource "aws_security_group" "cluster_shared_node_sg" {
  name_prefix = "ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Billeasy_F/ClusterSharedNodeSecurityGroup"
  }
}

resource "aws_security_group" "control_plane_sg" {
  name_prefix = "ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Billeasy_F/ControlPlaneSecurityGroup"
  }
}

resource "aws_security_group_rule" "ingress_default_cluster_to_node" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  security_group_id = aws_security_group.cluster_shared_node_sg.id
  source_security_group_id = aws_security_group.control_plane_sg.id
}

resource "aws_security_group_rule" "ingress_inter_node_group" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  security_group_id = aws_security_group.cluster_shared_node_sg.id
  source_security_group_id = aws_security_group.cluster_shared_node_sg.id
}

resource "aws_security_group_rule" "ingress_node_to_default_cluster" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  security_group_id = aws_security_group.control_plane_sg.id
  source_security_group_id = aws_security_group.cluster_shared_node_sg.id
}

resource "aws_eks_cluster" "control_plane" {
  name = "Billeasy_F"
  role_arn = aws_iam_role.service_role.arn
  version = "1.30"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_eu_west_1a.id,
      aws_subnet.public_eu_west_1b.id,
      aws_subnet.public_eu_west_1c.id,
      aws_subnet.private_eu_west_1a.id,
      aws_subnet.private_eu_west_1b.id,
      aws_subnet.private_eu_west_1c.id
    ]
    security_group_ids = [aws_security_group.control_plane_sg.id]
    endpoint_public_access = true
    endpoint_private_access = false
  }

  tags = {
    Name = "Billeasy_F/ControlPlane"
  }
}

resource "aws_iam_role" "service_role" {
  name = "Billeasy_F-ServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]

  tags = {
    Name = "Billeasy_F-ServiceRole"
  }
}

resource "aws_subnet" "private_eu_west_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name                           = "Billeasy_F/SubnetPrivateEUWEST1A"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_eu_west_1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name                           = "Billeasy_F/SubnetPrivateEUWEST1B"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_eu_west_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1c"

  tags = {
    Name                           = "Billeasy_F/SubnetPrivateEUWEST1C"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "public_eu_west_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                           = "Billeasy_F/SubnetPublicEUWEST1A"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_eu_west_1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                           = "Billeasy_F/SubnetPublicEUWEST1B"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_eu_west_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "eu-west-1c"
  map_public_ip_on_launch = true

  tags = {
    Name                           = "Billeasy_F/SubnetPublicEUWEST1C"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Billeasy_F/InternetGateway"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_eu_west_1a.id

  tags = {
    Name = "Billeasy_F/NATGateway"
  }
}

resource "aws_eip" "nat_ip" {
  domain = "vpc"

  tags = {
    Name = "Billeasy_F/NATIP"
  }
}

resource "aws_route_table" "private_eu_west_1a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Billeasy_F/PrivateRouteTableEUWEST1A"
  }
}

resource "aws_route_table" "private_eu_west_1b" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Billeasy_F/PrivateRouteTableEUWEST1B"
  }
}

resource "aws_route_table" "private_eu_west_1c" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Billeasy_F/PrivateRouteTableEUWEST1C"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Billeasy_F/PublicRouteTable"
  }
}

resource "aws_route_table_association" "private_eu_west_1a" {
  subnet_id      = aws_subnet.private_eu_west_1a.id
  route_table_id = aws_route_table.private_eu_west_1a.id
}

resource "aws_route_table_association" "private_eu_west_1b" {
  subnet_id      = aws_subnet.private_eu_west_1b.id
  route_table_id = aws_route_table.private_eu_west_1b.id
}

resource "aws_route_table_association" "private_eu_west_1c" {
  subnet_id      = aws_subnet.private_eu_west_1c.id
  route_table_id = aws_route_table.private_eu_west_1c.id
}

resource "aws_route_table_association" "public_eu_west_1a" {
  subnet_id      = aws_subnet.public_eu_west_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_eu_west_1b" {
  subnet_id      = aws_subnet.public_eu_west_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_eu_west_1c" {
  subnet_id      = aws_subnet.public_eu_west_1c.id
  route_table_id = aws_route_table.public.id
}
