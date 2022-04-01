#!/bin/sh
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

# Assign an IP address to local loopback
ip addr add 127.0.0.1/32 dev lo
ip link set dev lo up

echo "Yup, it sure is!" >> /public/THIS_IS_IN_THE_ENCLAVE.txt

# Forward incoming connections from the vsock to the nginx server.
/app/socat VSOCK-LISTEN:5000,reuseaddr,fork TCP:localhost:8000 &
/app/socat VSOCK-LISTEN:5001,reuseaddr,fork TCP:localhost:8001 &

nginx -c /app/nginx.conf
#cd /app && python3 -m http.server
