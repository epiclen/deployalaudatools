FROM alpine

RUN mkdir /deploytools

ADD . /deploytools/

ADD ./docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]