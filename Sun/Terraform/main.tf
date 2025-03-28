resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "VPC-Sun"
  }
}

resource "aws_subnet" "subnet_1" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.subnet_zone1
  cidr_block              = var.subnet_cidrs[0]

  tags = {
    Name = "Subnet-Public"
  }
}

resource "aws_subnet" "subnet_2" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.subnet_zone2
  cidr_block              = var.subnet_cidrs[1]

  tags = {
    Name = "Subnet-Private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet-Gateway"
  }
}

resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route-Public"
  }
}

resource "aws_route_table" "route_table_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Route-Private"
  }
}

resource "aws_route_table_association" "assoc_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_route_table_association" "assoc_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.route_table_2.id
}

resource "aws_security_group" "sun_sg" {
  name        = "sun_sg"
  vpc_id      = aws_vpc.main.id
  description = "Groupe de securite pour la machine Sun"

  tags = {
    Name = "Security-Group-Sun"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = {
    Name = "Key-Sun"
  }
}

resource "aws_iam_role" "sun_role" {
  name               = "sun-role"

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

  tags = {
    Name = "IAM-Role-Sun"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.sun_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.sun_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "sun_instance_profile" {
  name = "sun-instance-profile"
  role = aws_iam_role.sun_role.name
}

resource "aws_instance" "sun" {
  associate_public_ip_address = true
  private_ip                  = "192.168.0.10"
  ami                         = "ami-0160e8d70ebc43ee1"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_1.id
  iam_instance_profile        = aws_iam_instance_profile.sun_instance_profile.name
  key_name                    = aws_key_pair.sun_key.key_name
  vpc_security_group_ids      = [aws_security_group.sun_sg.id]

  tags = {
    Name = "Sun"
  }
}