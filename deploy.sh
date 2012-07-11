#!/bin/bash
NO_ARGS=0
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
TARGET="/raid/home/tomasz/archive"
CONFIG_DIR="/etc/beaver/servers"

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi
while getopts ":dp:v:e:" Option
do
	case $Option in
		d	) echo $TARGET; exit;;
		p	) echo "Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		v	) echo "Version ${OPTARG}"; VERSION_NAME=${OPTARG};;
		e	) echo "Enviorment ${OPTARG}"; ENV_NAME=${OPTARG};;
	esac
done

FILE=$TARGET/$PROJECT_NAME/$VERSION_NAME/package.tgz;

if [ ! -e $FILE ]
then 
	echo "Could not find archive: $FILE";
	exit $E_OPTERROR;
fi

CONFIG=$CONFIG_DIR/$PROJECT_NAME/$ENV_NAME/servers

if [ ! -e $CONFIG ]
then 
	echo "Could not find enviorment: $CONFIG";
	exit $E_OPTERROR;
fi

source $CONFIG;

#echo $TEST1;

for DEST in "${SERVERS[@]}"
do
	echo "-- $DEST"
done