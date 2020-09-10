ARG UPSTREAM_SUPERSET_VERSION=0.37.0
FROM amancevice/superset:${UPSTREAM_SUPERSET_VERSION} as final

ARG SUPERSET_KETCHUP_VERSION=master
ENV SUPERSET_KETCHUP_VERSION=${SUPERSET_KETCHUP_VERSION}

USER root
WORKDIR /tmp/superset
ADD requirements.txt requirements.txt
RUN curl -o superset-patchup.tar.gz https://codeload.github.com/onaio/superset-patchup/tar.gz/${SUPERSET_KETCHUP_VERSION} && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir superset-patchup.tar.gz && \
    pip install -r requirements.txt && \
    ls -a && \
    rm -rf ./* && \
    rm -rf /root/.cache

WORKDIR /home/superset
ADD uwsgi.ini uwsgi.ini
CMD ["uwsgi", "--ini", "uwsgi.ini"]
USER superset
