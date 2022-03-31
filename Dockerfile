FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install python3 iproute -y
WORKDIR /app

# Install newer version of socat (must be statically compiled on Fedora).
COPY socat_pkg/socat ./

COPY run.sh ./

RUN chmod +x /app/run.sh

CMD ["/app/run.sh"]
