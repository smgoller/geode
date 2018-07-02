#!/usr/bin/env bash
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

GEODE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
SANITIZED_GEODE_BRANCH=$(echo ${GEODE_BRANCH} | tr "/" "-")
TARGET=geode
GEODE_FORK=${1:-apache}
#TEAM=$(fly targetgets | grep ^${TARGET} | awk '{print $3}')
TEAM="staging"

echo "Deploying pipline for ${GEODE_FORK}/${GEODE_BRANCH}"

set -x
fly -t ${TARGET} set-pipeline \
  -p meta-${SANITIZED_GEODE_BRANCH} \
  -c meta.yml \
  --var geode-build-branch=${GEODE_BRANCH} \
  --var geode-fork=${GEODE_FORK} \
  --var concourse-team=${TEAM}
