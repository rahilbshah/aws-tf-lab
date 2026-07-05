#!/bin/bash
set -euxo pipefail

# --- Boot-time web server bootstrap ---------------------------------------
# nginx is NOT in our golden AMI (see notes/03-ami-bake) — in production you'd
# bake it in so instances serve traffic in seconds during an ASG scale-out.
# Here we install at boot for learning simplicity; that's exactly the tradeoff
# the Packer note calls out.
apt-get update -qq
apt-get install -y nginx

# --- Pull instance identity via IMDSv2 (token first — see notes/02-ec2) -----
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# --- Serve a page that reveals WHICH instance answered ----------------------
# Refreshing the ALB URL in a browser will show this value changing as the
# load balancer spreads requests across instances/AZs.
cat > /var/www/html/index.html <<HTML
<!doctype html>
<title>ALB + ASG demo</title>
<h1>Served by ${IID}</h1>
<p>Availability Zone: ${AZ}</p>
HTML

systemctl enable --now nginx
