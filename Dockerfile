FROM docker:23.0.4-dind

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

COPY /docker-action /docker-action
