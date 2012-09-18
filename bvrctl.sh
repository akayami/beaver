#!/bin/bash
PID=$$
WORK_DIR="/tmp/beaver."$PID
SOURCE_DIR=$WORK_DIR"/source"
CONFIG_LOCATION=$HOME"./bvrconfig"
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
STATUS=false;
ARCHIVED=false;

function shutDown() {
	echo "End Of Program";
	rm -rf $WORK_DIR;
	exit 0; 		
}


if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
	echo "Usage: `basename $0` options (-pv)"
	exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":p:b:v:c:r:e:dfRm:sa" Option
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
		s	) echo "-Show Status"; STATUS=true;;
		a	) echo "-Show Archived List"; ARCHIVED=true;;
	esac
done

echo "-Rev: $REVISION"

EXIST=`test -d $CONFIG_LOCATION/$PROJECT_NAME || echo "false"`;

if [ -z "$PROJECT_NAME" -o "$EXIST" = "false" ]; then
	echo "Project name not provided or invalid. List of projects configured:"
	ls  $CONFIG_LOCATION;
	shutDown;
fi

mkdir -p $SOURCE_DIR;

source $CONFIG_LOCATION/$PROJECT_NAME/source;

if $STATUS -a [ -z "$VERSION_NAME" ]; then
	echo "Displaying Status:";
	ssh $DESTINATION bvrstat.sh -p $PROJECT_NAME -e $ENV_NAME;
fi

# Checking if the project is already deployed

DESTINATION_ARCHIVE=`ssh $DESTINATION $ARCHIVE_COMMAND -t`;

DESTINATION_DIR=$DESTINATION_ARCHIVE/$PROJECT_NAME/$VERSION_NAME;

if [ "$ARCHIVED" = "true" ]; then
	echo "### Listing Archived Versions";
	ssh $DESTINATION ls $DESTINATION_ARCHIVE/$PROJECT_NAME;
	echo "### Done listing Archived Versions";
fi

if [ -z "$VERSION_NAME" ]; then
	echo "Will not build - Revision not specific (HEAD) and version not specified";
	shutDown;
fi

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
	if [ ! -z "$REMOTE_ARCHIVE_HOOK" ]; then
		echo "-Tagging repo";
		cd $SOURCE_DIR;
		eval $REMOTE_ARCHIVE_HOOK;	
	fi	

	cd $SOURCE_DIR;

	if [ -f $SOURCE_DIR/post-checkout.sh ]; then
		echo "-Executing Post Checkout";
		source post-checkout.sh;
		echo "-Done Executing Post Checkout";
	fi
	
	if [ -f $CONFIG_LOCATION/$PROJECT_NAME/post-checkout.sh ]; then
		echo "-Executing Server Side Post Checkout";
		source $CONFIG_LOCATION/$PROJECT_NAME/post-checkout.sh;
		echo "-Done Executing Server Side Post Checkout"
	fi
					
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

if $STATUS ; then
	echo "Displaying Status:";
	ssh $DESTINATION bvrstat.sh -p $PROJECT_NAME -e $ENV_NAME;
fi
shutDown