provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20251212"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_placement_group" "pg" {
  name = "contbk-pg"
  strategy = "cluster"
  tags = {
    Name    = "contbk-sg"
    Project = "contbk"
  }
 
}

resource "aws_security_group" "sg" {
  name = "contbk-sg"
  tags = {
    Name    = "contbk-sg"
    Project = "contbk"
  }
}

resource "aws_security_group_rule" "sg_cb_ingress" {
  security_group_id = aws_security_group.sg.id
  type              = "ingress"
  from_port         = 8091
  protocol          = "tcp"
  to_port           = 8091
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_ssh_ingress" {
  security_group_id = aws_security_group.sg.id
  type              = "ingress"
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_all_egress" {
  type              = "egress"
  security_group_id = aws_security_group.sg.id
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_sg_egress" {
  type              = "egress"
  security_group_id = aws_security_group.sg.id
  self              = true
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
}

resource "aws_security_group_rule" "sg_sg_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  self              = true
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
}

resource "aws_instance" "nfs_server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.nfs_server_instance_type
  security_groups = [aws_security_group.sg.name]
  placement_group = aws_placement_group.pg.name
  key_name        = var.key_name

  root_block_device {
    volume_size = 1024
    volume_type = "gp3"
    throughput  = var.nfs_server_disk_throughput
    iops        = var.nfs_server_disk_iops
  }

  tags = {
    Name    = "contbk-nfs-server"
    Project = "contbk"
  }
}

resource "aws_instance" "client" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.client_instance_type
  security_groups = [aws_security_group.sg.name]
  placement_group = aws_placement_group.pg.name
  key_name        = var.key_name

  root_block_device {
    volume_size = 1024
    volume_type = "gp3"
  }

  tags = {
    Name    = "contbk-client"
    Project = "contbk"
  }
}

resource "aws_instance" "server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.server_instance_type
  security_groups = [aws_security_group.sg.name]
  placement_group = aws_placement_group.pg.name
  key_name = var.key_name
  count = var.server_nodes
  root_block_device {
    volume_size = 1024
    volume_type = "gp3"
    throughput = var.server_disk_throughput
    iops = var.server_disk_iops
  }
  tags = {
    Name = "contbk-server"
    Project = "contbk"
  }
}

output "nfs_public_ip" {
  value = aws_instance.nfs_server.public_ip
}

output "nfs_private_ip" {
  value = aws_instance.nfs_server.private_ip
}

output "client_public_ip" {
  value = aws_instance.client.public_ip
}

output "client_private_ip" {
  value = aws_instance.client.private_ip
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../bridge/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.ini.tmpl", {
    nfs_public_ip        = aws_instance.nfs_server.public_ip
    client_public_ip     = aws_instance.client.public_ip
    server_public_ips    = aws_instance.server[*].public_ip
  })
}

resource "local_file" "ansible_vars" {
  filename = "${path.module}/../bridge/vars.yml"
  content = <<-END
    client_private_ip: ${aws_instance.client.private_ip}
    nfs_private_ip: ${aws_instance.nfs_server.private_ip}
    server_private_ips: [${join(", ", aws_instance.server[*].private_ip)}]
    server_public_ips: [${join(", ", aws_instance.server[*].public_ip)}]
  END
}
