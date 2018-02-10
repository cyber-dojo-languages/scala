FROM  openjdk:8-alpine
LABEL maintainer=jon@jaggersoft.com

# From https://github.com/bigtruedata/docker-scala/blob/master/2.12.4/alpine/Dockerfile
# Patch to generate images in Wercker's pipelines.
COPY env /usr/local/bin/env
ADD install.sh /
RUN /install.sh && rm -f /install.sh

