FROM docker:26.0.2-dind

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

COPY /docker-action /docker-action
