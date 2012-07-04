#!/bin/bash
PID=$$
WORK_DIR="/tmp/beaver."$PID
SOURCE_DIR=$WORK_DIR"/source"
CONFIG_LOCATION=/etc/beaver
NO_ARGS=0 
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
BRANCH="trunk"
REVISION="head"

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":p:b:v:c:r:" Option
do
	case $Option in
		p	) echo "Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		#		v	) echo "Version Provided #2: option -$Option- [OPTIND=${OPTIND}] - [VERSION_NAME=${OPTARG}]"; VERSION_NAME=${OPTARG};;
		c   ) echo "Config Dir:${OPTARG}"; CONFIG_LOCATION=${OPTARG};;
		r	) echo "Revision: ${OPTARG}"; REVISION=${OPTARG};;
		b	) echo "Branch: ${OPTARG}"; BRANCH=${OPTARG};;
	esac
done

mkdir -p $SOURCE_DIR;

source $CONFIG_LOCATION/$PROJECT_NAME/source;

echo $SOURCE;
eval $SOURCE;

tar zcvf ../package.tgz *;

rm -rf $WORK_DIR; 