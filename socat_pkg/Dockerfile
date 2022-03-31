FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN yum install gcc tar gzip make glibc-static -y
WORKDIR /app

COPY socat-1.7.4.3.tar.gz ./
RUN tar xzvf socat-1.7.4.3.tar.gz

WORKDIR /app/socat-1.7.4.3

RUN ./configure LDFLAGS="-static"
RUN make

#CMD ["/app/socat-1.7.4.3/socat"]
CMD ["/bin/bash"]
