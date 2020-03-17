FROM alpine

RUN mkdir /deploytools

ADD . /deploytools/

RUN rm -rf /deploytools/.git*

RUN rm -rf /deploytools/Dockerfile

RUN rm -rf /deploytools/docker-entrypoint.sh

ADD ./docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]