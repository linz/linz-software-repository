FROM docker:25.0.1-dind

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

COPY /docker-action /docker-action
