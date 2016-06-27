#!/bin/bash
#
# Run TrafficGenerator in a many-to-many fashion and print aggregated results

# General settings
USER="weiyu"
CONTROLLER="192.168.1.51"
SERVERS=("192.168.1.52")
CLIENTS=("192.168.1.52")

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
TIME_IN_SECONDS=20


# Start server programs
for server in ${SERVERS[@]}; do
    ssh ${USER}@${server} "${SERVER_PROGRAM} -p ${PORT}" >> /dev/null &
done

# For every client, create a result directory and send the configuration file to it
for client in ${CLIENTS[@]}; do
    mkdir ${LOCAL_RESULT_DIR}/${client} -p
    scp ${LOCAL_CONF_FILE} ${USER}@${client}:${CONF_FILE}
done

# Run client programs and send back flow files to controller afterwards
run_client_cmd="${CLIENT_PROGRAM} -b ${BANDWIDTH} -t ${TIME_IN_SECONDS} -c ${CONF_FILE} -l ${FLOW_FILE}"
scp_cmd="scp ${FLOW_FILE} ${USER}@${CONTROLLER}:${LOCAL_RESULT_DIR}/${client}"
for client in ${CLIENTS[@]}; do
    ssh ${USER}@${client} "${run_client_cmd}; ${scp_cmd}" >> /dev/null &
done

# Wait until all clients have completed running and sent their flow files to controller
sleep ${TIME_IN_SECONDS}
while [[ `find ${LOCAL_RESULT_DIR} -type f | wc -l` != ${#CLIENTS[@]} ]] ; do
    sleep 1
done

# Stop server programs
for server in ${SERVERS[@]}; do
    ssh ${USER}@${server} "pgrep server | xargs kill"
done

# Aggregate and parse results
touch ${LOCAL_AGGREGATED_FLOW_FILE}
for client in ${CLIENTS[@]}; do
        cat ${LOCAL_RESULT_DIR}/${client}/* >> ${LOCAL_AGGREGATED_FLOW_FILE}
done
python ${LOCAL_RESULT_SCRIPT} ${LOCAL_AGGREGATED_FLOW_FILE}

