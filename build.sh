#!/bin/bash
PID=$$
WORK_DIR="/tmp/beaver."$PID
SOURCE_DIR=$WORK_DIR"/source"
CONFIG_LOCATION="/etc/beaver/source"
NO_ARGS=0 
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME="dev"
BRANCH="trunk"
REVISION="head"
ARCHIVE_COMMAND="deploy.sh"
DEPLOY_COMMAND="deploy.sh"
FLIP_COMMAND="flip.sh"
DEPLOY=false
FLIP=false


if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":p:b:v:c:r:e:df" Option
do
	case $Option in
		p	) echo "-Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		v	) echo "-Version ${OPTARG}"; VERSION_NAME=${OPTARG};;
		c   ) echo "-Config Dir:${OPTARG}"; CONFIG_LOCATION=${OPTARG};;
		r	) echo "-Revision: ${OPTARG}"; REVISION=${OPTARG}; 
				if [ -z $VERSION_NAME ] 
				then 
					echo "-Version Auto Set:${OPTARG}";VERSION_NAME=${OPTARG};
				fi 
				;;
		b	) echo "-Branch: ${OPTARG}"; BRANCH=${OPTARG};;
		e	) echo "-Enviorment ${OPTARG}"; ENV_NAME=${OPTARG};;
		d	) echo "-Exceute Deploy"; DEPLOY=true;;
		f	) echo "-Execute Flip"; FLIP=true;;
	esac
done

mkdir -p $SOURCE_DIR;

source $CONFIG_LOCATION/$PROJECT_NAME/source;

echo $SOURCE;
eval $SOURCE;

tar zcvf ../package.tgz *;

DESTINATION_ARCHIVE=`ssh $DESTINATION $ARCHIVE_COMMAND -d`;

DESTINATION_DIR=$DESTINATION_ARCHIVE/$PROJECT_NAME/$VERSION_NAME;

ssh $DESTINATION mkdir -p $DESTINATION_DIR
scp $WORK_DIR/package.tgz $DESTINATION:$DESTINATION_DIR
if $DEPLOY ; then
	echo "Deploying"; 
	DEP_COMM="ssh $DESTINATION $DEPLOY_COMMAND -p $PROJECT_NAME -v $VERSION_NAME -e $ENV_NAME"
	eval $DEP_COMM;
fi

if $FLIP ; then
	echo "Flipping";	
	ssh $DESTINATION $FLIP_COMMAND -p $PROJECT_NAME -v $VERSION_NAME -e $ENV_NAME;
fi
#rm -rf $WORK_DIR; 