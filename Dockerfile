FROM node:22.13.0-alpine3.21 AS frontend

ARG SEMAPHORE_VERSION="develop"

ENV OPENTOFU_VERSION="1.9.0"
ENV TERRAFORM_VERSION="1.11.3"

WORKDIR /semaphore

RUN apk add --no-cache curl git && \
  git clone https://github.com/ansible-semaphore/semaphore.git . && \
  git config --add advice.detachedHead false && \
  git checkout "${SEMAPHORE_VERSION}" && \
  sh -c "$(curl -sSL https://taskfile.dev/install.sh)" -- -b /usr/local/bin && \
  task deps:fe && \
  task build:fe

RUN wget https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.tar.gz && \
    tar xf tofu_${OPENTOFU_VERSION}_linux_amd64.tar.gz -C /tmp && \
    rm tofu_${OPENTOFU_VERSION}_linux_amd64.tar.gz

RUN curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /tmp && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

FROM golang:1.24-alpine3.21 AS backend

WORKDIR /semaphore

COPY --from=frontend /semaphore /semaphore
COPY --from=frontend /usr/local/bin/task /usr/local/bin/task

RUN apk add --no-cache curl git && \
  task deps:tools && \
  task deps:be && \
  task build:be GOOS= GOARCH=

FROM alpine:3.20 AS runtime

ARG USER_UID=1001
ARG USER_GID=$USER_UID

COPY --from=backend /semaphore/bin/semaphore /usr/local/bin/
COPY --from=frontend /tmp/tofu /usr/local/bin/
COPY --from=frontend /tmp/terraform /usr/local/bin/

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
