FROM debian:bullseye-slim

## Build only args
ARG API_BASE_DIR=${API_BASE_DIR:-/api_base}
## ENV used in build and runtime
ENV API_PROD_DIR=${API_PROD_DIR:-${API_BASE_DIR}}
ENV TZ="Europe/Berlin"

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && \
    apt-get install -y curl python3=3.9.2-* python3-pip gawk && \
    pip3 install --no-cache-dir --upgrade setuptools && \
    pip3 install --no-cache-dir Werkzeug Jinja2 MarkupSafe ItsDangerous Click Flask requests flask-accept && \
    apt-get autoremove -y && \
    apt-get clean; rm -rf /var/lib/apt/lists/*

COPY src ${API_BASE_DIR}
COPY config config

EXPOSE 5000

## Override entrypoint for custom initialisation...
COPY ./bootstrap-api.sh /root/bin/bootstrap.sh
ENTRYPOINT ["/root/bin/bootstrap.sh"]
