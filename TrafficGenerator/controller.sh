#!/bin/bash
#
# Run TrafficGenerator in a many-to-many fashion and print aggregated results

# General settings
USER="weiyu"
CONTROLLER="192.168.1.51"
SERVERS=("192.168.1.52")
CLIENTS=("192.168.1.52")

# Local settings
LOCAL_BASE_DIR=`pwd`
LOCAL_CONF_FILE="config.txt"
LOCAL_RESULT_DIR_PREFIX="result"
LOCAL_RESULT_SCRIPT="result.py"

# Remote settings
CONF_FILE="~/TrafficGenerator/conf/config.txt"
SERVER_PROGRAM="~/TrafficGenerator/bin/server"
CLIENT_PROGRAM="~/TrafficGenerator/bin/client"
FLOW_FILE="~/TrafficGenerator/flows.txt"
RESULT_SCRIPT="~/TrafficGenerator/src/script/result.py"
RESULT_FILE="~/TrafficGenerator/results"
PORT=5001
BANDWIDTH=60
TIME_IN_SECONDS=20


# Unique directory indentified by timestamp for every round
local_result_dir=${LOCAL_BASE_DIR}/${LOCAL_RESULT_DIR_PREFIX}_`date +%Y%m%d_%H%M%S`

# Start server programs
for server in ${SERVERS[@]}; do
    ssh ${USER}@${server} "${SERVER_PROGRAM} -p ${PORT}" >> /dev/null &
done

# For every client, create a result directory and send the configuration file to it
for client in ${CLIENTS[@]}; do
    mkdir ${local_result_dir}/${client} -p
    scp ${LOCAL_CONF_FILE} ${USER}@${client}:${CONF_FILE}
done

# Run client programs and send back flow files to controller afterwards
run_client_cmd="${CLIENT_PROGRAM} -b ${BANDWIDTH} -t ${TIME_IN_SECONDS} -c ${CONF_FILE} -l ${FLOW_FILE} -r ${RESULT_SCRIPT} > ${RESULT_FILE}"
scp_cmd="scp ${FLOW_FILE} ${USER}@${CONTROLLER}:${local_result_dir}/${client}"
for client in ${CLIENTS[@]}; do
    ssh ${USER}@${client} "${run_client_cmd}; ${scp_cmd}" >> /dev/null &
done

# Wait until all clients have completed running and sent their flow files to controller
sleep ${TIME_IN_SECONDS}
while [ `find ${local_result_dir} -type f | wc -l` != ${#CLIENTS[@]} ] ; do
    sleep 1
done

# Stop server programs
for server in ${SERVERS[@]}; do
    ssh ${USER}@${server} "pgrep server | xargs kill"
done

# Aggregate and parse results
touch ${local_result_dir}/aggregated_flows.txt
for client in ${CLIENTS[@]}; do
    cat ${local_result_dir}/${client}/* >> ${local_result_dir}/aggregated_flows.txt
done
python ${LOCAL_BASE_DIR}/${LOCAL_RESULT_SCRIPT} ${local_result_dir}/aggregated_flows.txt

