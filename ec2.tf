data "aws_key_pair" "main" {
  key_name = "main_v2"
}

data "aws_ami" "agent" {
  most_recent = true
  # owners      = ["054536564342"]
  filter {
    name   = "name"
    values = ["aws-datasync-*-x86_64-gp2"]
  }
}

resource "aws_eip" "agent" {
  tags = {
    Name = "DataSync Agent"
  }
}

resource "aws_eip_association" "agent" {
  allocation_id        = aws_eip.agent.allocation_id
  network_interface_id = aws_network_interface.agent.id
}

resource "aws_instance" "agent" {
  #  ami                         = data.aws_ami.agent.id
  ami                         = "ami-0aa9633328c0f3488"
  instance_type               = "t3a.large"
  key_name                    = "main"
  private_ip                  = "172.31.26.142"
  user_data                   = file("datasync-agent-user-data")
  user_data_replace_on_change = false

  tags = {
    Name = "Locally DataSync Agent"
  }
}

resource "aws_network_interface" "agent" {
  subnet_id       = data.aws_subnet.use1a.id
  private_ips     = ["172.31.26.142"]
  security_groups = [aws_security_group.agent.id]
}

resource "aws_security_group" "agent" {
  name        = "locally-datasync-endpoint-sg"
  description = "Allow appropriate traffic for the DataSync endpoint for Locally"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port   = 1024
    to_port     = 1064
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["73.58.239.164/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["73.58.239.164/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.58.239.164/32"]
  }

  ingress {
    from_port   = 1024
    to_port     = 1064
    protocol    = "tcp"
    cidr_blocks = ["73.58.239.164/32"]
  }

  tags = {
    Name = "locally-datasync-endpoint-sg"
  }
}
