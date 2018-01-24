#!/usr/bin/env bash

export TERM=${TERM:-dumb}
export PAGER=cat
export BUILDROOT=$(pwd)
export DEST_DIR=${BUILDROOT}/built-geode
export GEODE_BUILD=${DEST_DIR}/test
export CALLSTACKS_DIR=${GEODE_BUILD}/callstacks

#SLEEP_TIME is in seconds
SLEEP_TIME=${1}
COUNT=3
STACK_INTERVAL=5


mkdir -p ${CALLSTACKS_DIR}

sleep ${SLEEP_TIME}

echo "Capturing call stacks"
for (( h=0; h<${COUNT}; h++)); do
    today=`date +%Y-%m-%d-%H-%M-%S`
    logfile=${CALLSTACKS_DIR}/callstacks-${today}.txt
    mapfile -t containers < <(docker ps --format '{{.Names}}')

    for (( i=0; i<${#containers[@]}; i++ )); do
        echo "Container: ${containers[i]}" | tee -a ${logfile};
        mapfile -t processes < <(docker exec ${containers[i]} jps | grep ChildVM | cut -d ' ' -f 1)
        echo "Got past processes."
        for ((j=0; j<${#processes[@]}; j++ )); do
              echo "********* Dumping stack for process ${processes[j]}:" | tee -a ${logfile}
                  docker exec ${containers[i]} jstack -l ${processes[j]} >> ${logfile}
        done
    done
    sleep ${STACK_INTERVAL}
done

echo "Checking progress files:"
mapfile -t progressfiles < <(find /tmp/gemfire-build -name test-progress.txt)
for (( i=0; i<${#progressfiles[@]}; i++)); do
    echo "Checking progress file: ${progressfiles[i]}"
    /usr/local/bin/dunit-progress hang ${progressfiles[i]} | tee -a ${CALLSTACKS_DIR}/dunit-hangs.txt
done
