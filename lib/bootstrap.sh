PID=$$
TMP="/tmp"
NO_ARGS=0 
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
ENV_PROVIDED=false
BRANCH=""
REVISION=""
#ARCHIVE_COMMAND="bvrdpl.sh"
#DEPLOY_COMMAND="bvrdpl.sh"
#FLIP_COMMAND="bvrflip.sh"
DEPLOY=false
FLIP=false
OVERWRITE=false
BUILD=false
REMOTE_ARCHIVE_HOOK=""
MESSAGE=""
STATUS=false;
ARCHIVED=false;
INFO=false;
BVR_HOME=$HOME/.beaver;
LENGTH=""
STAMP=`date +"%Y-%m-%dT%H:%M:%S"`;

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
	echo "Usage: `basename $0` options (-pv)"
	exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi

while getopts ":p:b:v:c:r:e:dfBRim:sal:" Option
do
	case $Option in
		p	) PROJECT_NAME=${OPTARG};;
		v	) VERSION_NAME=${OPTARG};;
		c   ) CONFIG_LOCATION=${OPTARG};;
		r	) REVISION=${OPTARG};; 
		b	) BRANCH=${OPTARG};;
		e	) ENV_PROVIDED=true;ENV_NAME=${OPTARG};;
		d	) DEPLOY=true;;
		f	) FLIP=true;;
		R	) OVERWRITE=true;;
		m	) MESSAGE=${OPTARG};;
		s	) STATUS=true;;
		a	) ARCHIVED=true;;
		i	) INFO=true;;
		B	) BUILD=true;;
		l	) LENGTH=${OPTARG};;
		\?	) echo "Unrecognized option -$OPTARG"; exit 1;;	
		:	) 
				case $OPTARG in
					e	) ENV_PROVIDED=true;;
					*	) echo "Option -$OPTARG requires an argument"; exit 1;;
				esac
			;;
		
		
	esac
done
<<COMMENT1
while getopts ":p:b:v:c:r:e:dfRim:sa" Option
do
	case $Option in
		p	) echo "-Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		v	) echo "-Version: ${OPTARG}"; VERSION_NAME=${OPTARG};;
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
		i	) echo "-Incremental Deployment"; INCREMENTAL=true;;
	esac
done
COMMENT1