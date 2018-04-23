#!/usr/bin/env bash

GEODE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TARGET=geode

set -x
fly -t ${TARGET} set-pipeline -p meta-${GEODE_BRANCH} -c meta.yml --var geode-build-branch=${GEODE_BRANCH}
