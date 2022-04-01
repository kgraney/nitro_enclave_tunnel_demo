#!/bin/bash
# Install stuff
amazon-linux-extras install aws-nitro-enclaves-cli -y
yum install aws-nitro-enclaves-cli-devel -y
yum install amazon-ecr-credential-helper -y
yum install python3 -y

# Setup enclaves
usermod -aG ne ec2-user
usermod -aG docker ec2-user

# Start stuff
#systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
systemctl start docker && sudo systemctl enable docker

