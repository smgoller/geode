#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x

BASE_DIR=$(pwd)

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

BUILD_NAME=$(cat concourse-metadata/build-name)
BUILD_JOB_NAME=$(cat concourse-metadata/build-job-name)
BUILD_PIPELINE_NAME=$(cat concourse-metadata/build-pipeline-name)

INSTANCE_NAME="$(echo "geode-builder-${BUILD_PIPELINE_NAME}-${BUILD_JOB_NAME}-${BUILD_NAME}" | tr '[:upper:]' '[:lower:]')"
PROJECT=apachegeode-ci
ZONE=us-central1-f

echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config

gcloud compute --project=${PROJECT} instances delete ${INSTANCE_NAME} \
  --zone=${ZONE} \
  --quiet
