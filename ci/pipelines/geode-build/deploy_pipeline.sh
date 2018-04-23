#!/usr/bin/env bash
#

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if ! [ -x "$(command -v spruce)" ]; then
    echo "Spruce must be installed for pipeline deployment to work."
    echo "For macos: 'brew tap starkandwayne/cf; brew install spruce'"
    echo "For Ubuntu: follow the instructions at https://github.com/geofffranks/spruce"
    echo ""
    exit 1
else
    SPRUCE=$(which spruce || true)
fi

set -e

if [ -z "${GEODE_BRANCH}" ]; then
  GEODE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

if [ "${GEODE_BRANCH}" = "HEAD" ]; then
  echo "Unable to determine branch for deployment. Quitting..."
  exit 1
fi

BIN_DIR=${OUTPUT_DIRECTORY}/bin
TMP_DIR=${OUTPUT_DIRECTORY}/tmp
mkdir -p ${BIN_DIR} ${TMP_DIR}
curl -o ${BIN_DIR}/fly "https://concourse.apachegeode-ci.info/api/v1/cli?arch=amd64&platform=linux"
chmod +x ${BIN_DIR}/fly

PATH=${PATH}:${BIN_DIR}

for i in ${SCRIPTDIR}/test-stubs/*.yml; do
  X=$(basename $i)
  echo "Merging ${i} into ${TMP_DIR}/${X}"
  ${SPRUCE} merge --prune metadata \
    <(echo "metadata:"; \
      echo "  geode-build-branch: ${GEODE_BRANCH}") \
    ${SCRIPTDIR}/test-template.yml \
    ${i} > ${TMP_DIR}/${X}
done

echo "Spruce branch-name into resources"
${SPRUCE} merge --prune metadata \
  ${SCRIPTDIR}/base.yml \
  <(echo "metadata:"; \
    echo "  geode-build-branch: ${GEODE_BRANCH}"; \
    echo "  ") \
  ${TMP_DIR}/*.yml > ${TMP_DIR}/final.yml


TARGET="geode"

TEAM="staging"
if [[ "${GEMFIRE_BUILD_BRANCH}" == develop ]] || [[ ${GEMFIRE_BUILD_BRANCH} =~ ^support/* ]]; then
  TEAM="main"
fi

fly login -t ${TARGET} -n ${TEAM} -c https://concourse.apachegeode-ci.info -u ${CONCOURSE_USERNAME} -p ${CONCOURSE_PASSWORD}
fly -t ${TARGET} set-pipeline --non-interactive --pipeline ${GEODE_BRANCH} --config ${TMP_DIR}/final.yml

