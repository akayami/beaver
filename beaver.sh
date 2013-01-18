#!/bin/bash

# Determines the script location
pushd . > /dev/null
SELF_DIR="${BASH_SOURCE[0]}";
if ([ -h "${SELF_DIR}" ]) then
  while([ -h "${SELF_DIR}" ]) do cd `dirname "$SELF_DIR"`; SELF_DIR=`readlink "${SELF_DIR}"`; done
fi
cd `dirname ${SELF_DIR}` > /dev/null
SELF_DIR=`pwd`;
popd  > /dev/null
# Done

# Including some libs
source $SELF_DIR/lib/bootstrap.sh;
source $SELF_DIR/lib/tools.sh;
source $SELF_DIR/lib/archive.sh;

# Configure App Home

APP_HOME=$HOME/.bvrconfig;
#APP_HOME=$HOME/dev/workspace/beaver2;

BVR_HOME=$APP_HOME/conf;
BVR_REPO_HOME=$APP_HOME/repos;
BVR_ARCHIVE_HOME=$APP_HOME/archives;

source $SELF_DIR/lib/validation.sh;

source $BVR_HOME/sources/$PROJECT_NAME/source;

[ -z $BRANCH ] && BRANCH="$DEFAULT_BRANCH";
if [ -z $BRANCH ]; then 
	echo "Branch not provided, and no default set in $BVR_HOME/sources/$PROJECT_NAME/source"; exit;
fi 

#echo $REPO_TYPE;
#echo $REPO_URL;
#echo $VERSION_NAME;
#echo $BRANCH;

LOCK="/tmp/lockfile."$PROJECT_NAME"_"$BRANCH;
REPO_SOURCE=$BVR_REPO_HOME/$PROJECT_NAME/$BRANCH;

if create_lock $LOCK; then 
	
	trap "remove_lock $LOCK; exit" INT TERM EXIT
	# Code 	
	case $REPO_TYPE in
		git	) source $SELF_DIR/lib/git.sh;;
		svn	) source $SELF_DIR/lib/svn.sh;;
		*	) echo "Undefined repo type"; exit;;
	esac
	
	source $SELF_DIR/lib/validation.sh;	

	if $ARCHIVED ; then				
		print_archives $BVR_ARCHIVE_HOME/$PROJECT_NAME		
	fi
	
	if $INFO ; then
		if [ -z $VERSION_NAME ]; then
			echo "Error: Version name (-v name) is required to show details of version.";
			echo "Use -a to list version names archived.";
			exit; 
		fi
		printe_archive_info $BVR_ARCHIVE_HOME/$PROJECT_NAME $VERSION_NAME
	fi
	
	if $BUILD ; then
		[ -z $VERSION_NAME ] && VERSION_NAME=$STAMP;		
		if [ ! -d $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME ]; then
			echo "# Building new package..."
			reset_source $REPO_SOURCE $REPO_URL $BRANCH $REVISION;
			copy_source_to_archive $REPO_SOURCE $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME $BRANCH $REVISION
			echo "# Done building and archiving new version: $VERSION_NAME";
		else
			echo "# Archived version '$VERSION_NAME' of package '$PROJECT_NAME' already exists !";
		fi
	fi
	
	#source $BVR_HOME/$PROJECT_NAME/env/$ENV_NAME/servers;
	#source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers;
	
	if $DEPLOY ; then
		source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers;
		archive_code=$BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME/payload
		remote_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME;
		current_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current
				
		for DEST in "${SERVERS[@]}"
		do			
			if [ ! `ssh $DEST test -d $remote_path || echo 0` ]; then
				echo "# Version '$VERSION_NAME' of package '$PROJECT_NAME' already deployed on $DEST";
			else
				if [ ! `ssh $DEST test -d $current_path || echo 0` ]; then
					echo "Copying ...";
					ssh $DEST mkdir -p $remote_path; cp -r $current_path/* $remote_path;
				else
					mkdir -p $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME;
				fi
				#echo "rsync -avz --delete -e ssh $archive_code/ $DEST:$remote_path/";
				rsync -avz --delete -e ssh $archive_code/ $DEST:$remote_path/
			fi
		done
	fi
	
	if $FLIP ; then
		source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers;
		remote_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME;
		current_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current
		is_present_on_all_servers=true;
		for DEST in "${SERVERS[@]}"
		do
			if [ `ssh $DEST test -d $remote_path || echo 0` ]; then
				echo "# Server '$DEST' does not contain '$VERSION_NAME' of package '$PROJECT_NAME'";
				is_present_on_all_servers=false;
			fi
		done
		if ! $is_present_on_all_servers ; then
			echo "# Version '$VERSION_NAME' is not present on all server. Aborting flip...";
			exit 1;
		fi
		for DEST in "${SERVERS[@]}"
		do
			echo "# Flipping '$DEST' to '$VERSION_NAME'";
			echo $remote_path;
			echo $current_path;			
			if [ ! `ssh $DEST test -d $current_path || echo 0` ]; then
				ssh $DEST rm $current_path; ln -s $remote_path $current_path;
			else
				ssh $DEST ln -s $remote_path $current_path;
			fi 
		done
	fi
	if $STATUS ; then 
		source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers;
		for DEST in "${SERVERS[@]}"
		do
			#echo `ssh $DEST "ls -al $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current | sed -nr 's|.*/(.*)|\1|p'"`;
			remote_ver=`ssh $DEST "ls -al $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current | sed -nr 's|.*/(.*)|\1|p'"`;
			echo "$DEST => $remote_ver";
		done
	fi
	if [ ! -z "$EMAIL_LIST" ]
	then
		if $BUILD -o $DEPLOY -o $FLIP ; then 
			if $BUILD ; then
				EMAIL_MESSAGE=" $EMAIL_MESSAGE Build ";
			fi
			if $DEPLOY ; then
				EMAIL_MESSAGE=" $EMAIL_MESSAGE Deployment "; 
			fi
			if $FLIP ; then
				EMAIL_MESSAGE=" $EMAIL_MESSAGE Flip ";
			fi
			echo "Email: $EMAIL_LIST - FROM: $EMAIL_FROM";
			EMAIL_MESSAGE="$EMAIL_MESSAGE Completed For: $PROJECT_NAME - $ENV_NAME - $VERSION_NAME\n\n\n----";
			echo -e $EMAIL_MESSAGE | mail -s "Deployment Completed - Beaver Deployment Tool" -a=FROM:$EMAIL_FROM "$EMAIL_LIST"
		fi	
	fi
else
	echo "Lock Aquisition Failed - Quitting";
fi