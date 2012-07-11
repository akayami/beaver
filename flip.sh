#!/bin/bash
PID=$$
NO_ARGS=0
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
CONFIG_LOCATION="/etc/beaver/servers"


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

source $CONFIG;

REMOTE_PATH=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME

if [ ! -e $REMOTE_PATH ]
then
	echo "Requested version not found: $REMOTE_PATH";
	echo "Try deploying first";
	exit 0;
fi

for DEST in "${SERVERS[@]}"
do
	
#	ssh $DEST mkdir -p $REMOTE_PATH
#	scp $FILE $DEST:$REMOTE_PATH
	#ssh $DEST "cd $REMOTE_PATH ; ls -al;"
	ssh $DEST "cd $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/ ; rm current; ln -s $VERSION_NAME current;"
	echo "-- $DEST"
done