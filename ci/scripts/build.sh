#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


set -e

GEODE_BUILD_VERSION=geode-build-version/number

if [ ! -e "${GEODE_BUILD_VERSION}" ]; then
  echo "${GEODE_BUILD_VERSION} file does not exist. Concourse is probably not configured correctly."
  exit 1
fi
if [ -z ${MAINTENANCE_VERSION+x} ]; then
  echo "MAINTENANCE_VERSION is unset. Check your pipeline configuration and make sure this script is called properly."
  exit 1
fi
ROOT_DIR=$(pwd)

CONCOURSE_VERSION=$(cat ${GEMFIRE_BUILD_VERSION})
PRODUCT_VERSION=${CONCOURSE_VERSION%%-*}
BUILD_ID=${CONCOURSE_VERSION##*.}

echo "Concourse VERSION is ${CONCOURSE_VERSION}"
echo "Product VERSION is ${PRODUCT_VERSION}"
echo "Build ID is ${BUILD_ID}"

printf "\nUsing the following JDK:"
java -version
printf "\n\n"

export TERM=${TERM:-dumb}
export DEST_DIR=$(pwd)/built-geode
export TMPDIR=${DEST_DIR}/tmp
mkdir -p ${TMPDIR}

pushd geode
./gradlew --no-daemon -PversionNumber=${PRODUCT_VERSION} -PbuildId=${BUILD_ID} --system-prop "java.io.tmpdir=${TMPDIR}" build
popd

tar zcvf ${DEST_DIR}/geodefiles-${CONCOURSE_VERSION}.tgz geode