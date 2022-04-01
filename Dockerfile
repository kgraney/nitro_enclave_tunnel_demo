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
# limitations under the License.
FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN amazon-linux-extras install epel -y
RUN yum install python3 iproute nginx certbot -y

WORKDIR /app
COPY certs/enclave.kiwiairforce.com/fullchain.pem ./
COPY certs/enclave.kiwiairforce.com/privkey.pem ./
COPY run.sh ./
COPY nginx.conf ./

# Install newer version of socat (must be statically compiled on Amazon Linux).
COPY socat_pkg/socat ./

RUN chmod +x /app/run.sh

WORKDIR /public

CMD ["/app/run.sh"]
