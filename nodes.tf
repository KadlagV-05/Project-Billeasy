# Define IAM Role for Node Instances
resource "aws_iam_role" "node_instance_role" {
  name = "Bumblebee-07-node-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Bumblebee-07-node-instance-role"
  }
}

# Attach Policies to Node Instance Role
resource "aws_iam_role_policy_attachment" "node_instance_registry_policy" {
  role      = aws_iam_role.node_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_instance_worker_policy" {
  role      = aws_iam_role.node_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_instance_cni_policy" {
  role      = aws_iam_role.node_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_instance_ssm_policy" {
  role      = aws_iam_role.node_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Define EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.control_plane.name
  node_group_name = "Bumblebee-07-node-group"
  node_role_arn   = aws_iam_role.node_instance_role.arn
  subnet_ids      = [
    aws_subnet.public_eu_west_1a.id,
    aws_subnet.public_eu_west_1b.id,
    aws_subnet.public_eu_west_1c.id
  ]

  instance_types = [
    "t2.micro"  # Directly specify the instance type here
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "Bumblebee-07-node-group"
  }
}
