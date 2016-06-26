#!/bin/bash
#
# Run TrafficGenerator in a many-to-many fashion and print aggregated results

USER="weiyu"
MASTER="192.168.1.51"
SERVERS="
192.168.1.52
"
CLIENTS=${SERVERS}
RESULT_DIR_PREFIX="result"
LOCAL_CONF_FILE="config.txt"
CONF_FILE="~/TrafficGenerator/conf/config.txt"


# Unique directory indentified by timestamp for every round
result_dir=${RESULT_DIR_PREFIX}_`date +%Y%m%d_%H%M%S`

for client in ${CLIENTS}; do
    # Create directory to store result for that client
    mkdir ${result_dir}/${client} -p
    # Copy configuration file to client
    scp ${LOCAL_CONF_FILE} ${USER}@${client}:${CONF_FILE}
done


