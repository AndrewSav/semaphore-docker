FROM node:22.2.0-alpine3.20 as frontend

ARG SEMAPHORE_VERSION="develop"

WORKDIR /semaphore

RUN apk add --no-cache curl git && \
  git clone https://github.com/ansible-semaphore/semaphore.git . && \
  git config --add advice.detachedHead false && \
  git checkout "${SEMAPHORE_VERSION}" && \
  sh -c "$(curl -sSL https://taskfile.dev/install.sh)" -- -b /usr/local/bin && \
  task deps:fe && \
  task build:fe

FROM golang:1.22.3-alpine3.20 as backend

WORKDIR /semaphore

COPY --from=frontend /semaphore /semaphore
COPY --from=frontend /usr/local/bin/task /usr/local/bin/task

RUN apk add --no-cache curl git && \
  task deps:tools && \
  task deps:be && \
  task build:be GOOS= GOARCH=

FROM alpine:3.20 as runtime

ARG USER_UID=1001
ARG USER_GID=$USER_UID

COPY --from=backend /semaphore/bin/semaphore /usr/local/bin/

RUN apk add --no-cache sshpass git curl ansible openssh-client tini && \
    addgroup -g $USER_GID semaphore && \
    adduser -D -u $USER_UID -G semaphore semaphore && \
    mkdir -p /tmp/semaphore && \
    chown -R semaphore:semaphore /tmp/semaphore && \
    chown -R semaphore:semaphore /usr/local/bin/semaphore

WORKDIR /home/semaphore
COPY --chown=semaphore:semaphore entrypoint.py .

USER $USER_UID

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/home/semaphore/entrypoint.py"]
