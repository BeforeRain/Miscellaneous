#!/bin/bash
#
# Run TrafficGenerator in a many-to-many fashion and parse aggregated results

# General settings
CONTROLLER="192.168.1.51"
SERVERS=("192.168.1.1" "192.168.1.2" "192.168.1.3" "192.168.1.4" "192.168.1.5")
CLIENTS=("192.168.1.1" "192.168.1.2" "192.168.1.3" "192.168.1.4" "192.168.1.5")

# Local settings
LOCAL_BASE_DIR="${PWD}"
LOCAL_CONF_FILE="${LOCAL_BASE_DIR}/config.txt"
LOCAL_RESULT_SCRIPT="${LOCAL_BASE_DIR}/result.py"
LOCAL_RESULT_DIR="${LOCAL_BASE_DIR}/result_`date +%Y%m%d_%H%M%S`"
LOCAL_AGGREGATED_FLOW_FILE="${LOCAL_BASE_DIR}/aggregated_flows.txt"

# Remote settings
BASE_DIR="~/TrafficGenerator"
CONF_FILE="${BASE_DIR}/conf/config.txt"
SERVER_PROGRAM="${BASE_DIR}/bin/server"
CLIENT_PROGRAM="${BASE_DIR}/bin/client"
FLOW_FILE="${BASE_DIR}/flows.txt"
PORT=5001
BANDWIDTH=60
TIME_IN_SECONDS=30


# Start server programs
for server in ${SERVERS[@]}; do
    ssh ${server} "${SERVER_PROGRAM} -p ${PORT}" >> /dev/null &
done

# For every client, create a result directory and send the configuration file to it
for client in ${CLIENTS[@]}; do
    mkdir ${LOCAL_RESULT_DIR}/${client} -p
    scp ${LOCAL_CONF_FILE} @${client}:${CONF_FILE} >> /dev/null
done

# Run client programs and send back flow files to controller afterwards
for client in ${CLIENTS[@]}; do
    run_client_cmd="${CLIENT_PROGRAM} -b ${BANDWIDTH} -t ${TIME_IN_SECONDS} -c ${CONF_FILE} -l ${FLOW_FILE}"
    scp_cmd="scp ${FLOW_FILE} ${CONTROLLER}:${LOCAL_RESULT_DIR}/${client}"
    ssh ${client} "${run_client_cmd}; ${scp_cmd}" >> /dev/null &
done

# Wait until all clients have completed running and sent their flow files to controller
sleep ${TIME_IN_SECONDS}
while [[ `find ${LOCAL_RESULT_DIR} -type f | wc -l` != ${#CLIENTS[@]} ]]; do
    sleep 1
done

# Stop server programs
for server in ${SERVERS[@]}; do
    ssh ${server} "pgrep server | xargs kill"
done

# Aggregate and parse results
touch ${LOCAL_AGGREGATED_FLOW_FILE}
for client in ${CLIENTS[@]}; do
    cat ${LOCAL_RESULT_DIR}/${client}/* >> ${LOCAL_AGGREGATED_FLOW_FILE}
done
python ${LOCAL_RESULT_SCRIPT} ${LOCAL_AGGREGATED_FLOW_FILE}

