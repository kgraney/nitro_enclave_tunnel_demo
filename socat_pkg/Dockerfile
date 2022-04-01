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
FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install gcc tar gzip make glibc-static -y
WORKDIR /app

COPY socat-1.7.4.3.tar.gz ./
RUN tar xzvf socat-1.7.4.3.tar.gz

WORKDIR /app/socat-1.7.4.3

RUN ./configure LDFLAGS="-static"
RUN make

CMD ["/bin/bash"]
