FROM stackbrew/ubuntu:13.10
MAINTAINER Democracy Works, Inc. <dev@turbovote.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update # REFRESHED: 2014-02-08
RUN apt-get upgrade -y -q

RUN apt-get install -qy supervisor unzip haproxy sbcl
ADD https://dl.bintray.com/mitchellh/serf/0.4.1_linux_amd64.zip serf.zip
RUN unzip serf.zip
RUN mv serf /usr/bin/

RUN mkdir -p /var/log/haproxy
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD haproxy.conf /haproxy/haproxy.conf
ADD start-serf.sh /start-serf.sh
ADD start-haproxy.sh /start-haproxy.sh
ADD handler.lisp /handlers/handler.lisp
ADD xlb.lisp /handlers/xlb.lisp
RUN chmod 755 /*.sh
RUN chmod 755 /handlers/xlb.lisp

EXPOSE 80

CMD ["/usr/bin/supervisord"]
