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

STOP=false;

for DEST in "${SERVERS[@]}"
do
	EXIST=`ssh $DEST test -d $REMOTE_PATH || echo "NA"`;
	if [ "$EXIST" = "NA" ] ; then
		STOP=true;
		echo "Not there";
	else
		echo "Exists";
	fi 	
done

if $STOP ; then
	echo "One or more server does not contian the target version: $PROJECT_NAME/$ENV_NAME/$VERSION_NAME";
	echo "Flip aborted on all servers...";
	exit 0;
fi

for DEST in "${SERVERS[@]}"
do
	ssh $DEST "cd $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/ ; rm current; ln -s $VERSION_NAME current;"
	
	
	FILE=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current/post-flip.sh
	EXIST=`ssh $DEST test -f $FILE || echo "NA"`;
	if [ "$EXIST" != "NA" ] ; then
		echo "-Executing Post-Flip";
		ssh $DEST "bash $FILE $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current/"
	else
		echo "-Skipping Post-Flip: $EXIST - $FILE"
	fi
	
	
	echo "-- $DEST"
done

if [ ! -z "$EMAIL_LIST" ]
then
	echo "Email: $EMAIL_LIST";
	EMAIL_MESSAGE="Flip Completed For: $PROJECT_NAME - $ENV_NAME - $VERSION_NAME\n\n\n----"
	echo -e $EMAIL_MESSAGE | mail -s "Flip Completed - Beaver Deployment Tool" "$EMAIL_LIST" -- -f tomasz.rakowski@manwin.com	
fi

echo "Flip completed on all servers";