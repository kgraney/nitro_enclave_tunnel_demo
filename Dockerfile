FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN amazon-linux-extras install epel -y
RUN yum install python3 iproute nginx certbot -y

WORKDIR /app
COPY certs/enclave.kiwiairforce.com/fullchain.pem ./
COPY certs/enclave.kiwiairforce.com/privkey.pem ./
COPY run.sh ./
COPY nginx.conf ./
COPY socat_pkg/socat ./

RUN chmod +x /app/run.sh

WORKDIR /public
# Install newer version of socat (must be statically compiled on Fedora).

CMD ["/app/run.sh"]
