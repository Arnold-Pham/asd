resource "aws_subnet" "subnet_2" {
  map_public_ip_on_launch = true
  vpc_id                  = var.vpc_id
  availability_zone       = var.subnet_zone
  cidr_block              = var.subnet_cidr

  tags = merge(var.common_tags, {
    Name = "Subnet-Private"
  })
}

resource "aws_route_table" "route_table_2" {
  vpc_id = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "Route-Private"
  })
}

resource "aws_route_table_association" "assoc_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.route_table_2.id
}

resource "aws_security_group" "cloud_sg_1" {
  name        = "cloud_sg_1"
  description = "Security Group pour Cloud-1 et Cloud-2 (80, 443)"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "Security-Group-Cloud1"
  })

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
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cloud_sg_2" {
  name        = "cloud_sg_2"
  description = "Security Group pour Cloud-3 (3000, 4317, 4318)"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "Security-Group-Cloud2"
  })

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OTel"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OTel"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cloud_sg_3" {
  name        = "cloud_sg_3"
  description = "Security Group pour Cloud-4 (8080, 9000)"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "Security-Group-Cloud3"
  })

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "cloud_role" {
  name = "cloud-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "IAM-Role-cloud"
  })
}

resource "aws_iam_role_policy_attachment" "cloud_policies" {
  count      = length(var.iam_policies)
  role       = aws_iam_role.cloud_role.name
  policy_arn = var.iam_policies[count.index]
}

resource "aws_iam_instance_profile" "cloud_instance_profile" {
  name = "cloud-instance-profile-${random_id.suffix.hex}"
  role = aws_iam_role.cloud_role.name
}

resource "aws_key_pair" "cloud_key" {
  key_name   = var.ssh_key_name
  public_key = file("./cloud-key.pub")

  tags = merge(var.common_tags, {
    Name = "Key-Cloud"
  })
}

resource "aws_instance" "cloud_1" {
  depends_on = [aws_security_group.cloud_sg_1]

  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_2.id
  private_ip             = var.private_ips[0]
  key_name               = aws_key_pair.cloud_key.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_1.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name
  
  tags = merge(var.common_tags, {
    Name = "Cloud-1"
  })
}

resource "aws_instance" "cloud_2" {
  depends_on = [aws_security_group.cloud_sg_1]

  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_2.id
  private_ip             = var.private_ips[1]
  key_name               = aws_key_pair.cloud_key.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_1.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name
  
  tags = merge(var.common_tags, {
    Name = "Cloud-2"
  })
}

resource "aws_instance" "cloud_3" {
  depends_on = [aws_security_group.cloud_sg_2]

  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_2.id
  private_ip             = var.private_ips[2]
  key_name               = aws_key_pair.cloud_key.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_2.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name
  
  tags = merge(var.common_tags, {
    Name = "Cloud-3"
  })
}

resource "aws_instance" "cloud_4" {
  depends_on = [aws_security_group.cloud_sg_3]

  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_2.id
  private_ip             = var.private_ips[3]
  key_name               = aws_key_pair.cloud_key.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_3.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name
  
  tags = merge(var.common_tags, {
    Name = "Cloud-4"
  })
}