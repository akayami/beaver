#!/bin/bash
PID=$$
NO_ARGS=0
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
TARGET="/var/beaver/archive"
CONFIG_LOCATION="/etc/beaver/servers"


if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi
while getopts ":dp:v:e:c:" Option
do
	case $Option in
		d	) echo $TARGET; exit;;
		p	) echo "-Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		c   ) echo "-Config Dir:${OPTARG}"; CONFIG_LOCATION=${OPTARG};;
		v	) echo "-Version ${OPTARG}"; VERSION_NAME=${OPTARG};;
		e	) echo "-Enviorment ${OPTARG}"; ENV_NAME=${OPTARG};;
	esac
done

FILE=$TARGET/$PROJECT_NAME/$VERSION_NAME/package.tgz;

if [ ! -e $FILE ]
then 
	echo "Could not find archive: $FILE";
	exit $E_OPTERROR;
fi

CONFIG=$CONFIG_LOCATION/$PROJECT_NAME/$ENV_NAME/servers

if [ ! -e $CONFIG ]
then 
	echo "Could not find enviorment: $CONFIG";
	exit $E_OPTERROR;
fi

source $CONFIG;

#echo $TEST1;

REMOTE_PATH=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME

for DEST in "${SERVERS[@]}"
do
	ssh $DEST mkdir -p $REMOTE_PATH
	scp $FILE $DEST:$REMOTE_PATH
	ssh $DEST "cd $REMOTE_PATH ; tar zxvf package.tgz ; rm package.tgz ;"
	echo "-- $DEST"
done

if [ ! -z "$EMAIL_LIST" ]
then
	echo "Email: $EMAIL_LIST";
	EMAIL_MESSAGE="Deployment Completed For: $PROJECT_NAME - $ENV_NAME - $VERSION_NAME\n\n\n----"

	echo -e $EMAIL_MESSAGE | mail -s "Deployment Completed - Beaver Deployment Tool" "$EMAIL_LIST" -- -f tomasz.rakowski@manwin.com
	
fi