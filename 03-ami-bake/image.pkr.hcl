packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
  }
}

data "amazon-ami" "ubuntu" {
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    root-device-type    = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
  region      = "us-east-1"
}


source "amazon-ebs" "ubuntu" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"
  ami_name      = "saa-c03-learning-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  source_ami    = data.amazon-ami.ubuntu.id
  tags          = { Project = "saa-c03-learning", BakedBy = "packer", BaseAmi = "ubuntu-24.04" }
  snapshot_tags = { Project = "saa-c03-learning", BakedBy = "packer", BaseAmi = "ubuntu-24.04" }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get install -y git docker.io unzip",
      "curl -fsSL 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o /tmp/awscliv2.zip",
      "unzip -q /tmp/awscliv2.zip -d /tmp",
      "sudo /tmp/aws/install",
      "rm -rf /tmp/awscliv2.zip /tmp/aws",
      "sudo usermod -aG docker ubuntu",
      "git --version && docker --version && aws --version",
    ]
  }
}
