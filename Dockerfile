ARG THREATSTACK_CONTAINER_VERSION=1.8.0C

FROM threatstack/ts-docker:${THREATSTACK_CONTAINER_VERSION}

RUN mkdir -p /etc/ts-agent

COPY ts_config.json /etc/ts-agent/ts_config.json
COPY ts_start.sh /ts_start.sh

CMD ["/bin/sh", "ts_start.sh"]
