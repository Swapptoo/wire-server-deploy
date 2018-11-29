#!/usr/bin/env bash

USAGE="download and bundle dependent helm charts: $0 <chart-directory>"
chart=${1:?$USAGE}

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
CHARTS_DIR="$BASE_DIR/charts"

set -e

# nothing serves on localhost, remove that repo
helm repo remove local 2&> /dev/null || true

# hacky workaround for helm's lack of recursive dependency update
# See https://github.com/helm/helm/issues/2247
helmDepUp () {
    local path
    path=$1
    cd "$path"
    # remove previous bundled versions of helm charts, if any
    find . -name "*\.tgz" -delete
    if [ -f requirements.yaml ]; then
      echo "Updating dependencies in $path ..."
      # very hacky bash, I'm sorry
      for subpath in $(grep "file://" requirements.yaml | awk '{ print $2 }' | xargs -n 1 | cut -c 8-)
      do
        ( helmDepUp "$subpath" )
      done
      helm dep up
      echo "... updating in $path done."
    fi
}

helmDepUp "${CHARTS_DIR}/${chart}"