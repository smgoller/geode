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

SSHKEY_FILE="instance-data/sshkey"
BUILD_NAME=$(cat concourse-metadata/build-name)
BUILD_JOB_NAME=$(cat concourse-metadata/build-job-name)
BUILD_PIPELINE_NAME=$(cat concourse-metadata/build-pipeline-name)
GEODE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
SANITIZED_GEODE_BRANCH=$(echo ${GEODE_BRANCH} | tr "/" "-" | tr '[:upper:]' '[:lower:]')
IMAGE_FAMILY_PREFIX=""

if [[ -z "${GEODE_FORK}" ]]; then
  echo "GEODE_FORK environment variable must be set for this script to work."
  exit 1
fi


if [[ "${GEODE_FORK}" != "apache" ]]; then
  IMAGE_FAMILY_PREFIX="${GEODE_FORK}-${SANITIZED_GEODE_BRANCH}-"
fi

INSTANCE_NAME="$(echo "geode-builder-${BUILD_PIPELINE_NAME}-${BUILD_JOB_NAME}-${BUILD_NAME}" | tr '[:upper:]' '[:lower:]')"
PROJECT=apachegeode-ci
ZONE=us-central1-f
echo "${INSTANCE_NAME}" > "instance-data/instance-name"
echo "${PROJECT}" > "instance-data/project"
echo "${ZONE}" > "instance-data/zone"

echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config

gcloud compute --project=${PROJECT} instances create ${INSTANCE_NAME} \
  --zone=${ZONE} \
  --machine-type=custom-8-30720 \
  --min-cpu-platform=Intel\ Skylake \
  --image-family="${IMAGE_FAMILY_PREFIX}geode-builder" \
  --image-project=${PROJECT} \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-ssd
CREATE_EXIT_STATUS=$?


while ! gcloud compute --project=${PROJECT} ssh geode@${INSTANCE_NAME} --zone=${ZONE} --ssh-key-file=${SSHKEY_FILE} --quiet -- true; do
  echo -n .
done

INSTANCE_IP_ADDRESS=$(gcloud compute instances list  | awk "/^${INSTANCE_NAME}/ {print \$5}")
echo "${INSTANCE_IP_ADDRESS}" > "instance-data/instance-ip-address"
