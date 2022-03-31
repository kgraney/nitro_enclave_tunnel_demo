#!/bin/sh
# Assign an IP address to local loopback
ip addr add 127.0.0.1/32 dev lo
ip link set dev lo up

cout "Yup, it sure is!" >> /app/THIS_IS_IN_THE_ENCLAVE.txt

# Forward incoming connections to the VSOCK on port 5000 to the local HTTP
# server on port 8000.
/app/socat VSOCK-LISTEN:5000,reuseaddr,fork TCP:localhost:8000 &

cd /app && python3 -m http.server
