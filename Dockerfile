FROM docker:29.4.3-dind

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

COPY /docker-action /docker-action
