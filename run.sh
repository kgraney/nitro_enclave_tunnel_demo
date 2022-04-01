#!/bin/sh
# Assign an IP address to local loopback
ip addr add 127.0.0.1/32 dev lo
ip link set dev lo up

echo "Yup, it sure is!" >> /public/THIS_IS_IN_THE_ENCLAVE.txt

# Forward incoming connections from the vsock to the nginx server.
/app/socat VSOCK-LISTEN:5000,reuseaddr,fork TCP:localhost:8000 &
/app/socat VSOCK-LISTEN:5001,reuseaddr,fork TCP:localhost:8001 &

nginx -c /app/nginx.conf
#cd /app && python3 -m http.server
