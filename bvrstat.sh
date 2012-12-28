#!/bin/bash
PID=$$
NO_ARGS=0
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
TARGET=$HOME"/.bvrconfig/archive"
CONFIG_LOCATION=$HOME"/.bvrconfig/servers"
SERVER_DEPLOY_TMP_HOME="/tmp/$PID"


if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi
while getopts ":p:v:e:c:" Option
do
	case $Option in
		p	) echo "-Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		c   ) echo "-Config Dir:${OPTARG}"; CONFIG_LOCATION=${OPTARG};;
		v	) echo "-Version ${OPTARG}"; VERSION_NAME=${OPTARG};;
		e	) echo "-Enviorment ${OPTARG}"; ENV_NAME=${OPTARG};;
	esac
done

CONFIG=$CONFIG_LOCATION/$PROJECT_NAME/$ENV_NAME/servers

if [ ! -e $CONFIG ]
then 
	echo "Could not find enviorment: $CONFIG";
	exit $E_OPTERROR;
else
	echo "Config Found !"
fi

source $CONFIG;

REMOTE_PATH=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current

for DEST in "${SERVERS[@]}"
do
	echo "### Listing Deployed Versions"
	STAT=`ssh $DEST "ls -l $REMOTE_PATH"`;
	echo "$DEST => $STAT";
	echo "### Done Listing Deployed Versions";
done