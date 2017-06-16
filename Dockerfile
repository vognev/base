FROM scratch
MAINTAINER Vitaliy Ognev <vitaliy.ognev@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

ADD root.tar.gz /
ADD ./bin/wupiao /usr/local/bin/wupiao

