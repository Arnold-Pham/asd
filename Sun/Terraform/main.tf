resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "VPC-Sun"
  })
}

resource "aws_subnet" "subnet_1" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.subnet_zone
  cidr_block              = var.subnet_cidr

  tags = merge(var.common_tags, {
    Name = "Subnet-Public"
  })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "Internet-Gateway"
  })
}

resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, {
    Name = "Route-Public"
  })
}

resource "aws_route_table_association" "assoc_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_security_group" "sun_sg" {
  name        = "sun_sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group pour la machine Sun"

  tags = merge(var.common_tags, {
    Name = "Security-Group-Sun"
  })

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API (Port 6443)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [
      "192.168.0.10/32",
      "192.168.1.11/32",
      "192.168.1.12/32",
      "192.168.1.13/32",
      "192.168.1.14/32"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "sun_key" {
  key_name   = var.ssh_key_name
  public_key = file("sun-key.pub")

  tags = merge(var.common_tags, {
    Name = "Key-Sun"
  })
}

resource "aws_iam_role" "sun_role" {
  name = "sun-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "IAM-Role-Sun"
  })
}

resource "aws_iam_role_policy_attachment" "sun_policies" {
  count      = length(var.iam_policies)
  role       = aws_iam_role.sun_role.name
  policy_arn = var.iam_policies[count.index]
}

resource "aws_iam_instance_profile" "sun_instance_profile" {
  name = "sun-instance-profile-${random_id.suffix.hex}"
  role = aws_iam_role.sun_role.name
}

resource "aws_instance" "sun" {
  depends_on = [
    aws_internet_gateway.gw,
    aws_security_group.sun_sg
  ]

  associate_public_ip_address = true
  private_ip                  = "192.168.0.10"
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_1.id
  iam_instance_profile        = aws_iam_instance_profile.sun_instance_profile.name
  key_name                    = aws_key_pair.sun_key.key_name
  vpc_security_group_ids      = [aws_security_group.sun_sg.id]

  tags = merge(var.common_tags, {
    Name = "Sun"
  })
}