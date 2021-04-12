ARG NODE_VERSION=12
ARG PYTHON_VERSION=3.8

#
# --- Build assets with NodeJS
#

FROM node:${NODE_VERSION} AS build

# Superset version to build
ARG SUPERSET_VERSION=master
ENV SUPERSET_HOME=/var/lib/superset/

# Download source
WORKDIR ${SUPERSET_HOME}
RUN wget -qO /tmp/superset.tar.gz https://github.com/onaio/superset/archive/${SUPERSET_VERSION}.tar.gz
RUN tar xzf /tmp/superset.tar.gz -C ${SUPERSET_HOME} --strip-components=1

# Build assets
WORKDIR ${SUPERSET_HOME}/superset-frontend/
RUN npm set registry https://verdaccio.oranges.onalabs.org
RUN npm install
RUN npm run build

#
# --- Build dist package with Python 3
#

FROM python:${PYTHON_VERSION} AS dist


# Copy prebuilt workspace into stage
ENV SUPERSET_HOME=/var/lib/superset/
WORKDIR ${SUPERSET_HOME}
COPY --from=build ${SUPERSET_HOME} .
COPY requirements.txt .

# Create package to install
RUN python setup.py sdist
RUN tar czfv /tmp/superset.tar.gz requirements.txt dist

#
# --- Install dist package and finalize app
#

FROM python:${PYTHON_VERSION} AS final

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=apache/superset \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset

# Create superset user & install dependencies
WORKDIR /tmp/superset
COPY --from=dist /tmp/superset.tar.gz .
RUN groupadd supergroup && \
    useradd -U -m -G supergroup superset && \
    mkdir -p /etc/superset && \
    mkdir -p ${SUPERSET_HOME} && \
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        default-libmysqlclient-dev \
        freetds-bin \
        freetds-dev \
        libaio1 \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-2 \
        libsasl2-dev \
        libsasl2-modules-gssapi-mit \
        libssl-dev && \
    apt-get clean && \
    tar xzf superset.tar.gz && \
    pip install Cython==0.29.21 && \
    pip install dist/*.tar.gz -r requirements.txt && \
    rm -rf ./*

# Configure Filesystem
COPY bin /usr/local/bin
WORKDIR /home/superset
VOLUME /etc/superset \
       /home/superset \
       /var/lib/superset

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
