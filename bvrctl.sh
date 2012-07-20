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
ARCHIVE_COMMAND="bvrdpl.sh"
DEPLOY_COMMAND="bvrdpl.sh"
FLIP_COMMAND="bvrflip.sh"
DEPLOY=false
FLIP=false
OVERWRITE=false
BUILD=true
REMOTE_ARCHIVE_HOOK=""
MESSAGE=""

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":p:b:v:c:r:e:dfRm:" Option
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
		R	) echo "-Overwrite archived package"; OVERWRITE=true;;
		m	) echo "-Message: ${OPTARG}"; MESSAGE=${OPTARG};;
	esac
done

mkdir -p $SOURCE_DIR;

source $CONFIG_LOCATION/$PROJECT_NAME/source;

echo "Rev: $REVISION"

DESTINATION_ARCHIVE=`ssh $DESTINATION $ARCHIVE_COMMAND -d`;

DESTINATION_DIR=$DESTINATION_ARCHIVE/$PROJECT_NAME/$VERSION_NAME;


EXIST=`ssh $DESTINATION test -d $DESTINATION_DIR || echo "0"`;
#EXIST=`ssh $DESTINATION ls -al $DESTINATION_DIR | wc -l`;
if [ "$EXIST" != "0" ]
then
	if ! $OVERWRITE ; then
		BUILD=false;
		echo "Project already archived, skipping pushing...";			
	fi	
fi
if $BUILD ; then
	# Building off github archive, while leaving a new tag
	echo $SOURCE;
	eval $SOURCE;
	if [ ! -z "REMOTE_ARCHIVE_HOOK" ]; then
		echo "-Tagging repo"
		cd $SOURCE_DIR;
		eval $REMOTE_ARCHIVE_HOOK;	
	fi	
	cd $SOURCE_DIR;		
	tar zcvf ../package.tgz *;		
	ssh $DESTINATION mkdir -p $DESTINATION_DIR
	scp $WORK_DIR/package.tgz $DESTINATION:$DESTINATION_DIR
fi
if $DEPLOY ; then	
	echo "Deploying"; 
	DEP_COMM="ssh $DESTINATION $DEPLOY_COMMAND -p $PROJECT_NAME -v $VERSION_NAME -e $ENV_NAME -R $OVERWRITE"
	echo $DEP_COMM;
	eval $DEP_COMM;
fi

if $FLIP ; then
	echo "Flipping";	
	ssh $DESTINATION $FLIP_COMMAND -p $PROJECT_NAME -v $VERSION_NAME -e $ENV_NAME;
fi
rm -rf $WORK_DIR; 