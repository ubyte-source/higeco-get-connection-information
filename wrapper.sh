#!/bin/bash

JQ=/usr/bin/jq
CURL=/usr/bin/curl
MYSQL=/usr/bin/mysql
WORKER=${TOOL}/worker
IPCALC=/usr/bin/ipcalc
SSHPASS=/usr/bin/sshpass
GREPCIDR=/usr/bin/grepcidr

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with job finish

HEALTH="/tmp/healthz"

runner() {
    echo "Stop this container."
    exit 1
}

declare -a RESPONSE=()

if ! [ -v DATABASE ] ; then
    RESPONSE+=("environment: Specifies the MySQL database.")
fi

if ! [ -v DATABASE_ENDPOINT ] ; then
    RESPONSE+=("environment: Specifies the MySQL database endpoint.")
fi

if ! [ -v DATABASE_PORT ] ; then
    RESPONSE+=("environment: Specifies the MySQL database port.")
fi

if ! [ -v DATABASE_USERNAME ] ; then
    RESPONSE+=("environment: Specifies the MySQL username.")
fi

if ! [ -v DATABASE_PASSWORD ] ; then
    RESPONSE+=("environment: Specifies the MySQL password.")
fi

if ! [ -v PROXY ] ; then
    RESPONSE+=("environment: Specifies the proxy.")
fi

if ! [ -v PROXY_PORT ] ; then
    RESPONSE+=("environment: Specifies the proxy port.")
fi

if ! [ -v USERNAME ] ; then
    RESPONSE+=("environment: Specifies the GWC username.")
fi

if ! [ -v ROOT ] ; then
    RESPONSE+=("environment: Specifies the root password.")
fi

if ! [ -v PASSWORD ] ; then
    RESPONSE+=("environment: Specifies the GWC password.")
fi

if ! [ -v FORTIGATE ] ; then
    RESPONSE+=("environment: Specifies the your Fortigate ip.")
fi

if ! [ -v FORTIGATE_PORT ] ; then
    RESPONSE+=("environment: Specifies the your Fortigate API port.")
fi

if ! [ -v FORTIGATE_TOKEN ] ; then
    RESPONSE+=("environment: Specifies the your Fortigate Token.")
fi

if [ ${#RESPONSE[@]} -ne 0 ] ; then
    printf '%s\n' "${RESPONSE[@]}"
    runner
fi

unset RESPONSE

echo "Status ok!" > "$HEALTH"

trap runner SIGINT SIGQUIT SIGTERM

export JQ
export CURL
export MYSQL
export WORKER
export IPCALC
export SSHPASS
export GREPCIDR

query='SELECT `serial_higeco`, `connectivity_type` FROM `energia_europa_higeco_get_connection_information` ORDER BY `device_serial` ASC';

trap runner SIGINT SIGQUIT SIGTERM

mapfile RESPONSE < <($MYSQL -u${DATABASE_USERNAME} -p${DATABASE_PASSWORD} -h ${DATABASE_ENDPOINT} --port=${DATABASE_PORT} --database ${DATABASE} --batch -s -N -e "${query}")
for result in "${RESPONSE[@]}" ; do
    type=$(echo $result | awk '{print $2}')
    higeco=$(echo $result | awk '{print $1}')
    echo "Call radar for device $higeco"
    $WORKER -s "$higeco" -t "$type" &
    sleep 4
done

while sleep 8; do
    ps aux | grep "$WORKER" | grep -v grep > /dev/null
    if [[ $? -ne 0 ]] ; then
        break
    fi
done

echo "The work for this container is finished."
exit 0
