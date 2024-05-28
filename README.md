# Unofficial docker image for [Ansible Semaphore](https://github.com/ansible-semaphore/semaphore)

[![GitHub Actions](https://github.com/AndrewSav/semaphore-docker/actions/workflows/main.yml/badge.svg)](https://github.com/AndrewSav/semaphore-docker/actions)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrewsav/semaphore?sort=semver)](https://hub.docker.com/r/andrewsav/semaphore/tags)


## How to use

A sample `docker-compose.yaml` is available in the [sample](sample) directory. First, configure your [config.json](sample/config.json). Refer to the [official Semaphore documentation](https://docs.ansible-semaphore.com/administration-guide/configuration) for the details on configuring that file. `cookie_hash`, `cookie_encryption` and `access_key_encryption` should be random 32 byte long secrets in base64 encoding, you can generated them with `head -c32 /dev/urandom | base64`

Secondly, review and update `docker-compose.yaml`. Chose strong passwords. Set the desired [andrewsav/semaphore](https://hub.docker.com/r/andrewsav/semaphore) image tag. This image support the following variables:

- SEMAPHORE_ADMIN, SEMAPHORE_ADMIN_PASSWORD, SEMAPHORE_ADMIN_NAME, SEMAPHORE_ADMIN_EMAIL - These four variables have to be specified together. They are used if Semaphore is connecting to the new database which does not have the specified user (probably because it does not have _any_ users). A new admin user will be created from the supplied values

Additionally, Semaphore itself supports the following variables:

- SEMAPHORE_ACCESS_KEY_ENCRYPTION - this variable if set, overrides the `config.json` variable `access_key_encryption`. Some people prefer to keep this secret in memory, rather than in a file.
- SEMAPHORE_CONFIG_PATH - the image is authored to read the configuration file from `/home/semaphore/config.json`, there for it is not recommended to pass this variable in normal circumstances, since the default should work

This image relies on the external `config.json` file which is mapped from host to the docker container as a bind volume. If you are not using the sample `docker-compose.yaml`please make sure to specify this mapping.

You can use the usual `semaphore user` and `semaphore setup` commands for maintenance, if you exec into the running container, e.g.:

```
docker exec -it semaphore sh
semaphore user list
```

Note that if you are using `semaphore setup` the generated config will be written inside the container, so you will have to map the directory you are writing it to, or use `docker cp` command to get the result out. Also node that the `/home/semaphore/config.json` may be in use and not writable, if the Semaphore server is running.

For troubleshooting purposes, if your container stops too quickly and you do not have time to exec into it uncoment the following line in `docker-compose.yaml`:

```
#command: ["sh","-c","sleep 999999"]
```

This will prevent Semaphore server from starting, but you will be able to exec into the container for maintenance / troubleshooting.

## How to build

Build it like this:

```
docker build -t andrewsav/semaphore:v2.9.109 --build-arg SEMAPHORE_VERSION=v2.9.109 .
```

Substitute `v2.9.109` above with the git commit hash, branch or tag name from the [ansible-semaphore/semaphore](https://github.com/ansible-semaphore/semaphore) repository.

It also can be build via GitHub actions. Create a PAT with the repo permission [here](https://github.com/settings/tokens>), then enter the PAT value and docker credentials [here](https://github.com/BarfootThompson/semaphore-docker/settings/secrets/actions) as `DOCKERHUB_TOKEN`, `DOCKERHUB_USERNAME` and `PAT`

## Differences from the official image

- `config.json` is not regenerated on each container start, instead it is mapped from host
- most of the configuration is provided via `config.json`, not via environment variables. This makes _all_ configuration options available, not just those that are exposed by the official image
- `semaphore setup` is not run on startup since we already have a working `config.json` configuration
- this build has to use `git clone` to get the sources since it is not in the official repository
- this build uses an official nodejs image for building the frontend (the official image does `apk add node npm` instead)
- this build uses more up to date (as of the time of writing) alpine images
- this image by default no longer runs under user that belongs to the `root` group
- a few dependencies have been removed because it was not clear where they are used
- it does not dump admin password to stdout
