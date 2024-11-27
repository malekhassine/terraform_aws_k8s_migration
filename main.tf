# Specify the VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "k8s-vpc"
  }
}

# Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

# Route Table
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# Security Group
resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

# EC2 Instances
resource "aws_instance" "master" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.k8s_subnet.id
  key_name      = var.key_name
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "worker" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.k8s_subnet.id
  key_name      = var.key_name
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]
  

  tags = {
    Name = "k8s-worker"
  }
}
# EC2 Instance for Ansible Management VM
resource "aws_instance" "ansible_vm" {
  ami           = var.ami # Replace with a valid AMI ID for Ubuntu or any OS
  instance_type = var.instance_type      # Replace with your desired instance type
  subnet_id     = aws_subnet.k8s_subnet.id
  key_name      = var.key_name        # Replace with your key name
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]

  # SSH connection settings
  connection {
    type        = "ssh"
    user        = "ubuntu"        # Replace with appropriate username for your OS
    private_key = file("key.pem")  # Path to your private key file
    host        = aws_instance.ansible_vm.public_ip   # Use the public IP of the Ansible VM
  }

  # Provisioner to install packages or run commands
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",  # Update system
      "sudo apt install -y ansible",  # Install Ansible
      "sudo apt install -y python3-pip",  # Install pip if needed for Ansible modules
      "sudo pip3 install boto boto3",  # Install AWS SDK for Ansible (if needed)
    ]
  }

  tags = {
    Name = "Ansible-VM"
  }
}

# Output the public IP of the Ansible VM
output "ansible_vm_public_ip" {
  value = aws_instance.ansible_vm.public_ip
}
