#!/bin/bash
# Install stuff
amazon-linux-extras install aws-nitro-enclaves-cli -y
yum install aws-nitro-enclaves-cli-devel -y
yum install amazon-ecr-credential-helper -y
yum install python3 -y

# Download custom build of recent socat with vsock support.
# (The version in Amazon Linux is too old)
su ec2-user -c 'curl -o $HOME/socat https://kmg-ps-public.s3.amazonaws.com/socat'
su ec2-user -c 'chmod +x $HOME/socat'

# Setup enclaves
usermod -aG ne ec2-user
usermod -aG docker ec2-user
echo "---
memory_mib: 2048
cpu_count: 2" > /etc/nitro_enclaves/allocator.yaml

# Start stuff
systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
systemctl start docker && sudo systemctl enable docker

## Commands to build an enclave.
#eval $(aws ecr get-login --region us-east-1 --no-include-email)
#su ec2-user -c 'nitro-cli build-enclave --docker-uri 743396514183.dkr.ecr.us-east-1.amazonaws.com/nitro_test_server:latest --output-file $HOME/enclave.eif'

# Download and start the built enclave
su ec2-user -c 'curl -o $HOME/enclave.eif https://kmg-ps-public.s3.amazonaws.com/enclave.eif'
su ec2-user -c 'nitro-cli run-enclave --cpu-count 2 --enclave-cid 16 --memory 2048 --eif-path $HOME/enclave.eif --debug-mode'

# Forward HTTP port 80 to the enclave's vsock.
/home/ec2-user/socat TCP4-LISTEN:80,reuseaddr,fork VSOCK-CONNECT:16:5000 &
