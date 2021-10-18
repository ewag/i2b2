#!/usr/bin/env bash
## Import the secrets as env vars

set -e

file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"

  if ! test -f ${!fileVar} ; then
    echo >&2 "warning: '${!fileVar}' not available in this container"
    return 1
  fi
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  echo >&2 "exporting ${var}=${val}"
  ## The scope of this export is only this script (but this is what runs the container, so generally its enough)
  export "${var}"="${val}"
  ## Put the variables into the profile so a new shell will also have them
  if test -f "/etc/profile.d/docker.sh"; then
    sed -i "/export ${var}=/d" /etc/profile.d/docker.sh
  fi
  echo -e "export ${var}=${val}" >> /etc/profile.d/docker.sh
  unset "$fileVar"
}

echo -e "Processing secrets..."
if test -f /run/secrets/ENV_MULTILOAD; then
    echo >&2 -e "Loading ENV_MULTILOAD secrets..."
    source /run/secrets/ENV_MULTILOAD
fi
while read secret_env; do
  secret_var=$(echo ${secret_env} | cut -d= -f 1)
  file_env ${secret_var:0:-5};
done < <(env | grep '_FILE=')
echo -e "...complete"

## Run check-db script in the background.
## It will wait for the database to start, check for i2b2 and run the init-database script if needed
/bin/bash -c '/docker-entrypoint/check-db.sh' &

## Now call the original/upstream entrypoint and append arguments
echo -e "Starting postgres server as per upstream image..."
/bin/bash -C /usr/local/bin/docker-entrypoint.sh $@
