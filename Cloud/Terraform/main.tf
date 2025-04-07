resource "aws_subnet" "subnet" {
  for_each = {
    for idx, name in var.subnet_names : 
    name => {
      cidr_block        = var.subnet_cidrs[idx]
      availability_zone = var.subnet_zones[idx]
    }
  }

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "Subnet-${each.key}"
  })
}

resource "aws_route_table" "route_table" {
  for_each = toset(var.subnet_names)

  vpc_id = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "Route-${each.key}"
  })
}

resource "aws_route_table_association" "assoc" {
  for_each = toset(var.subnet_names)

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.route_table[each.key].id
}

resource "aws_security_group" "cloud_sg_1" {
  name        = "cloud_sg_1"
  description = "Security Group pour machines prod"
  vpc_id      = var.vpc_id

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

  tags = merge(var.common_tags, {
    Name = "SG-cloud-1"
  })
}

resource "aws_security_group" "cloud_sg_2" {
  name        = "cloud_sg_2"
  description = "Security Group pour gestion"
  vpc_id      = var.vpc_id

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

  tags = merge(var.common_tags, {
    Name = "SG-cloud-2"
  })
}

resource "aws_security_group" "cloud_sg_3" {
  name        = "cloud_sg_3"
  description = "Security Group pour metriques"
  vpc_id      = var.vpc_id

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

  tags = merge(var.common_tags, {
    Name = "SG-cloud-3"
  })
}

resource "aws_security_group" "cloud_sg_4" {
  name        = "cloud_sg_4"
  description = "Security Group pour donnees"
  vpc_id      = var.vpc_id

  ingress {
    description = "BDD"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "BDD"
    from_port   = 3306
    to_port     = 3306
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

  tags = merge(var.common_tags, {
    Name = "SG-cloud-4"
  })
}

resource "aws_iam_role" "cloud_role" {
  name = "cloud-role"

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

resource "aws_key_pair" "cloud_key_1" {
  key_name   = "cloud-key-1"
  public_key = file("/home/ubuntu/.ssh/cloud-key-1.pub")

  tags = merge(var.common_tags, {
    Name = "cloud-key-1"
  })
}

resource "aws_key_pair" "cloud_key_2" {
  key_name   = "cloud-key-2"
  public_key = file("/home/ubuntu/.ssh/cloud-key-2.pub")

  tags = merge(var.common_tags, {
    Name = "cloud-key-2"
  })
}

resource "aws_key_pair" "cloud_key_3" {
  key_name   = "cloud-key-3"
  public_key = file("/home/ubuntu/.ssh/cloud-key-3.pub")

  tags = merge(var.common_tags, {
    Name = "cloud-key-3"
  })
}

resource "aws_key_pair" "cloud_key_4" {
  key_name   = "cloud-key-4"
  public_key = file("/home/ubuntu/.ssh/cloud-key-4.pub")

  tags = merge(var.common_tags, {
    Name = "cloud-key-4"
  })
}

resource "aws_instance" "cloud_1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet["${var.subnet_names[0]}"].id
  private_ip             = var.private_ips[0]
  key_name               = aws_key_pair.cloud_key_1.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_1.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name

  tags = merge(var.common_tags, {
    Name = "Cloud-1"
  })
}

resource "aws_instance" "cloud_2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet["${var.subnet_names[1]}"].id
  private_ip             = var.private_ips[1]
  key_name               = aws_key_pair.cloud_key_2.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_2.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name

  tags = merge(var.common_tags, {
    Name = "Cloud-2"
  })
}

resource "aws_instance" "cloud_3" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet["${var.subnet_names[2]}"].id
  private_ip             = var.private_ips[2]
  key_name               = aws_key_pair.cloud_key_3.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_3.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name

  tags = merge(var.common_tags, {
    Name = "Cloud-3"
  })
}

resource "aws_instance" "cloud_4" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet["${var.subnet_names[3]}"].id
  private_ip             = var.private_ips[3]
  key_name               = aws_key_pair.cloud_key_4.key_name
  vpc_security_group_ids = [aws_security_group.cloud_sg_4.id]
  iam_instance_profile   = aws_iam_instance_profile.cloud_instance_profile.name

  tags = merge(var.common_tags, {
    Name = "Cloud-4"
  })
}