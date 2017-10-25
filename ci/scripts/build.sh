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
BUILD_DATE=$(date +%s)
EMAIL_SUBJECT="results/subject"
EMAIL_BODY="results/body"

GEODE_BUILD_VERSION=geode-build-version/number

if [ ! -e "${GEODE_BUILD_VERSION}" ]; then
  echo "${GEODE_BUILD_VERSION} file does not exist. Concourse is probably not configured correctly."
  exit 1
fi
if [ -z ${MAINTENANCE_VERSION+x} ]; then
  echo "MAINTENANCE_VERSION is unset. Check your pipeline configuration and make sure this script is called properly."
  exit 1
fi
if [ -z ${SERVICE_ACCOUNT+x} ]; then
  echo "SERVICE_ACCOUNT is unset. Check your pipeline configuration and make sure this script is called properly."
  exit 1
fi
ROOT_DIR=$(pwd)

CONCOURSE_VERSION=$(cat ${GEODE_BUILD_VERSION})
PRODUCT_VERSION=${CONCOURSE_VERSION%%-*}
BUILD_ID=${CONCOURSE_VERSION##*.}

echo "Concourse VERSION is ${CONCOURSE_VERSION}"
echo "Product VERSION is ${PRODUCT_VERSION}"
echo "Build ID is ${BUILD_ID}"

printf "\nUsing the following JDK:"
java -version
printf "\n\n"

gcloud config set account ${SERVICE_ACCOUNT}

export TERM=${TERM:-dumb}
export DEST_DIR=$(pwd)/built-geode
export TMPDIR=${DEST_DIR}/tmp
mkdir -p ${TMPDIR}

pushd geode
set +e
./gradlew --no-daemon -PversionNumber=${PRODUCT_VERSION} -PbuildId=${BUILD_ID} --system-prop "java.io.tmpdir=${TMPDIR}" build
GRADLE_EXIT_STATUS=$?
set -e

popd
TEST_RESULTS_DESTINATION="files.apachegeode-ci.info/test-results/${MAINTENANCE_VERSION}/${CONCOURSE_VERSION}/build/${BUILD_DATE}/"
ARCHIVE_DESTINATION="files.apachegeode-ci.info/artifacts/${MAINTENANCE_VERSION}/geodefiles-${CONCOURSE_VERSION}.tgz"
URL_PATH="files.apachegeode-ci.info/test-results/${MAINTENANCE_VERSION}/${CONCOURSE_VERSION}/"
ARTIFACTS_PATH="files.apachegeode-ci.info/artifacts/${MAINTENANCE_VERSION}/geodefiles-${CONCOURSE_VERSION}.tgz"

function sendSuccessfulJobEmail {
  echo "Sending job success email"

  cat <<EOF >${EMAIL_SUBJECT}
Build for version ${CONCOURSE_VERSION} of Apache Geode succeeded.
EOF

  cat <<EOF >${EMAIL_BODY}
=================================================================================================

The build job for Apache Geode version ${CONCOURSE_VERSION} has completed successfully.


Build artifacts are available at:
http://${ARCHIVE_DESTINATION}

Test results are available at:
http://${TEST_RESULTS_DESTINATION}


=================================================================================================
EOF

}

function sendFailureJobEmail {
  echo "Sending job failure email"

  cat <<EOF >${EMAIL_SUBJECT}
Build for version ${CONCOURSE_VERSION} of Apache Geode failed.
EOF

  cat <<EOF >${EMAIL_BODY}
=================================================================================================

The build job for Apache Geode version ${CONCOURSE_VERSION} has failed.


Build artifacts are available at:
http://${ARCHIVE_DESTINATION}

Test results are available at:
http://${TEST_RESULTS_DESTINATION}


Job: \${ATC_EXTERNAL_URL}/teams/\${BUILD_TEAM_NAME}/pipelines/\${BUILD_PIPELINE_NAME}/jobs/\${BUILD_JOB_NAME}/builds/\${BUILD_NAME}

=================================================================================================
EOF

}

if [ ! -d "geode/build/reports/combined" ]; then
    echo "No tests exist, compile failed."
    mkdir -p geode/build/reports/combined
    echo "<html><head><title>No Test Results Were Captured</title></head><body><h1>No Test Results Were Captured</h1></body></html>" > geode/build/reports/combined/index.html
fi

pushd geode/build/reports/combined
gsutil -q -m cp -r * gs://${TEST_RESULTS_DESTINATION}
popd

echo ""
printf "\033[92m=-=-=-=-=-=-=-=-=-=-=-=-=-=  Test Results Website =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\033[0m\n"
printf "\033[92mhttp://${TEST_RESULTS_DESTINATION}\033[0m\n"
printf "\033[92m=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\033[0m\n"
printf "\n"

tar zcf ${DEST_DIR}/geodefiles-${CONCOURSE_VERSION}.tgz geode
printf "\033[92mTest artifacts from this job are available at:\033[0m\n"
printf "\n"
printf "\033[92mhttp://${ARCHIVE_DESTINATION}\033[0m\n"

if [ ${GRADLE_EXIT_STATUS} -eq 0 ]; then
    sendSuccessfulJobEmail
else
    sendFailureJobEmail
fi

exit ${GRADLE_EXIT_STATUS}
