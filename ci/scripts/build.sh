#!/usr/bin/env bash

set -e

pushd geode
./gradlew --no-daemon build
popd
