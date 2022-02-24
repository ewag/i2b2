FROM python:3.10-slim-bullseye

EXPOSE 5000
## ENV used in build and runtime
ENV TZ=${TZ:-'Europe/Berlin'}

ARG DEBIAN_FRONTEND="noninteractive"

## Update and install project requirements from requirements.txt (copy separately to entire src to aid docker layer cache reuse)
COPY support/requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

## Build only args
ARG API_BASE_DIR=${API_BASE_DIR:-/api_base}
## ENV used in build and runtime
ENV API_PROD_DIR=${API_PROD_DIR:-${API_BASE_DIR}}
ENV TZ=${TZ:-'Europe/Berlin'}

## Supporting files for bootstrap and config etc
COPY support/ /
## Copy project files over
COPY src ${API_BASE_DIR}

ENV META_SERVER=${META_SERVER:-i2b2.meta}
ENV LOG_CONF_PATH=${LOG_CONF_PATH:-'/config/logging.yaml'}
ENV APP_CONF_PATH=${LOG_CONF_PATH:-'/config/conf.cfg'}

ENV FLASK_APP="${API_PROD_DIR}/flask/i2b2.py"
CMD /bootstrap-api.sh && flask run -h 0.0.0.0 --reload
