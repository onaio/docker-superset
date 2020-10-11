# Superset

Docker image for [Apache Superset](https://github.com/apache/incubator-superset/). It makes use of the superset docker image built with [/amancevice/docker-superset](https://github.com/amancevice/docker-superset) by extending it with installing uwsgi and [superset-patchup (Ketchup)](https://github.com/onaio/superset-patchup).

This project is mainly for internal use within Ona and is not related to Apache or Superset.

## Building

```sh
make [ SUPERSET_VERSION=<version> UPSTREAM_SUPERSET_VERSION=<version> KETCHUP_SUPERSET_VERSION=<version> ]

# or simply
make
```

