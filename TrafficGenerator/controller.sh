#!/bin/bash
#
# Run TrafficGenerator in a many-to-many fashion and print aggregated results

USER="weiyu"
MASTER="192.168.1.51"
SERVERS="
192.168.1.52
"
CLIENTS=${SERVERS}

LOCAL_CONF_FILE="config.txt"
RESULT_DIR_PREFIX="result"

CONF_FILE="~/TrafficGenerator/conf/config.txt"
SERVER_PROGRAM="~/TrafficGenerator/bin/server"
CLIENT_PROGRAM="~/TrafficGenerator/bin/client"
PORT=5001


# Unique directory indentified by timestamp for every round
result_dir=${RESULT_DIR_PREFIX}_`date +%Y%m%d_%H%M%S`

for server in ${SERVERS}; do
    # Start server
    ssh ${USER}@${server} "${SERVER_PROGRAM} -p ${PORT}" >> /dev/null &
done

for client in ${CLIENTS}; do
    # Create directory to store result for that client
    mkdir ${result_dir}/${client} -p
    # Copy configuration file to client
    scp ${LOCAL_CONF_FILE} ${USER}@${client}:${CONF_FILE}
done

