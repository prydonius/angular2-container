#!/bin/bash
set -e

INIT_SEM=/tmp/initialized.sem
PACKAGE_FILE=/app/package.json

fresh_container() {
  [ ! -f $INIT_SEM ]
}

app_present() {
  [ -f /app/package.json ]
}

modules_present() {
  [ -d /app/node_modules ]
}

dependencies_up_to_date() {
  # It is up to date if the package file is older than
  # the last time the container was initialized
  [ ! $PACKAGE_FILE -nt $INIT_SEM ]
}

log () {
  echo -e "\033[0;33m$(date "+%H:%M:%S")\033[0;37m ==> $1."
}

if [ "$1" == ng -a "$2" == "serve" ]; then
  if ! app_present; then
    log "Creating angular application"
    sudo chown -R bitnami:bitnami /app
    # Copy the bootstrapped app at buildtime
    tar xzf ~/sample.tar.gz --strip-components=1
  fi

  # Copy the backed modules existing in the sample app
  if ! modules_present; then
    log "Copying node_modules directory"
    tar xzf ~/sample.tar.gz --strip-components=1 sample/node_modules
  fi

  if ! dependencies_up_to_date; then
    log "Installing/Updating Angular dependencies (npm)"
    npm install
    log "Dependencies updated"
  fi

  if ! fresh_container; then
    echo "#########################################################################"
    echo "                                                                       "
    echo " App initialization skipped:"
    echo " Delete the file $INIT_SEM and restart the container to reinitialize"
    echo " You can alternatively run specific commands using docker-compose exec"
    echo " e.g docker-compose exec myapp npm install angular"
    echo "                                                                       "
    echo "#########################################################################"
  else
    log "Initialization finished"
  fi

  touch $INIT_SEM
fi

exec /entrypoint.sh "$@"
