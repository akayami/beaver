#!/bin/bash

set -o errexit
#set -o nounset

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


if [ -z "$PROJECT_NAME" -o ! -d $BVR_HOME/sources/$PROJECT_NAME ]; then
	echo "Error: Project does not exist. Available projects:";
	ls $BVR_HOME/sources;
	exit;
fi

if [ ! -f $BVR_HOME/sources/$PROJECT_NAME/source ]; then
	echo "Project source config missing in: $BVR_HOME/sources/$PROJECT_NAME/source !";
	exit;
fi

#source $SELF_DIR/lib/validation.sh;

source $BVR_HOME/sources/$PROJECT_NAME/source;

if [ -z $BRANCH ]; then
	BRANCH="$DEFAULT_BRANCH";
	source $BVR_HOME/sources/$PROJECT_NAME/source;
fi
if [ -z $BRANCH ]; then
	echo "Branch not provided, and no default set in $BVR_HOME/sources/$PROJECT_NAME/source"; exit;
fi

#echo $REPO_TYPE;
#echo $REPO_URL;
#echo $VERSION_NAME;
#echo $BRANCH;

LOCK="/tmp/lockfile."$PROJECT_NAME;
REPO_SOURCE=$BVR_REPO_HOME/$PROJECT_NAME;

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
		exit 0
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
		#		[ -z $VERSION_NAME ] && VERSION_NAME=$STAMP;
		if ! $USE_ARCHIVE ; then
			echo "# Using no-archive method";
			reset_source $REPO_SOURCE $REPO_URL $BRANCH $REVISION;
			[ -z $VERSION_NAME ] && VERSION_NAME=$(get_last_commit_id $REPO_SOURCE);
		else
			echo "# Using archive method";
			reset_source $REPO_SOURCE $REPO_URL $BRANCH $REVISION;
			[ -z $VERSION_NAME ] && VERSION_NAME=$(get_last_commit_id $REPO_SOURCE);
			if [ ! -d $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME ] || $OVERWRITE ; then
				echo "# Creating Build/Archive Copy..."
				copy_source_to_archive $REPO_SOURCE $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME $BRANCH $REVISION

				if [ -f $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME/payload/post-build.sh ]; then
					echo "# Running post-build hook (project)"
					cd $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME/payload/
					./post-build.sh
				else
					echo "# No post-build hoook found '$BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME/post-build.sh'"
				fi
				if [ -f $BVR_HOME/sources/$PROJECT_NAME/post-build.sh ]; then
					echo "# Running post-build hook (global)"
					$BVR_HOME/sources/$PROJECT_NAME/post-build.sh $REPO_SOURCE $BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME || true
				else
					echo "# No post-build hoook found '$BVR_HOME/sources/$PROJECT_NAME/post-build.sh'"
				fi

				echo "# Done building and archiving new version: $VERSION_NAME";
			else
				echo "# Archived version '$VERSION_NAME' of package '$PROJECT_NAME' already exists !";
			fi
		fi
	fi

	if $DEPLOY || $FLIP || $STATUS ; then
		if [ "$ENV_NAME" != "" ]; then
			source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers || true;
			echo $SERVER_DEPLOY_HOME
		else
			echo "You need to provide enviroment to execute Deploy, Flip or Status"
			exit 0
		fi
	else
		echo "# Not Deploying, Flipping or Status checking."
	fi

	if $DEPLOY ; then

		[ -z $VERSION_NAME ] && VERSION_NAME=$(get_last_commit_id $REPO_SOURCE);

		if ! $ENV_PROVIDED ; then
			echo "# Missing enviroment paramter. Use -e to specify enviroment"
			exit 1
		fi
		if  ! $USE_ARCHIVE ; then
			archive_code=$REPO_SOURCE
		else
			archive_code=$BVR_ARCHIVE_HOME/$PROJECT_NAME/$VERSION_NAME/payload
		fi

		remote_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME;
		current_path=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current

		for DEST in "${SERVERS[@]}"
		do
			if ! $OVERWRITE ; then
				if [ ! `ssh $DEST test -d $remote_path || echo 0` ]; then
					# echo $OVERWRITE;
					echo "# Version '$VERSION_NAME' of package '$PROJECT_NAME' already deployed on $DEST";
					continue;
				fi
			fi

			if [ ! `ssh $DEST test -d $current_path || echo 0` ]; then
				echo "Copying ...";
				ssh $DEST "mkdir -p $remote_path; cp -r $current_path/* $remote_path";
			else
				echo $remote_path;
				ssh $DEST "mkdir -p $remote_path";
			fi
			#echo "rsync -avz --delete -e ssh $archive_code/ $DEST:$remote_path/";
			#rsync -avz --exclude-from=$BVR_HOME/rsync-exclude-list --delete -e ssh $archive_code/ $DEST:$remote_path/
			if [ -f $BVR_HOME/sources/$PROJECT_NAME/rsync-exclude ]; then
				echo "Using exclude-from:";
				#exit;
				rsync -avz --exclude='.svn' --exclude='.git' --exclude-from=$BVR_HOME/sources/$PROJECT_NAME/rsync-exclude --delete -e ssh $archive_code/ $DEST:$remote_path/
			else
				echo "Stadard exclude:";
				#exit;\
				echo rsync -avz --exclude='.svn' --exclude='.git' --delete -e ssh $archive_code/ $DEST:$remote_path/
				rsync -avz --exclude='.svn' --exclude='.git' --delete -e ssh $archive_code/ $DEST:$remote_path/
			fi
			echo "Executing remote postdeploy '$ENV_NAME' - '$ENV_NAME_CONFIG'";
			ssh $DEST "cd $remote_path; bash post-deploy.sh $ENV_NAME $ENV_NAME_CONFIG;" || true
			echo "Done";

		done
	fi

	if $FLIP ; then

		[ -z $VERSION_NAME ] && VERSION_NAME=$(get_last_commit_id $REPO_SOURCE);

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
			echo "# Version '$VERSION_NAME' is not present on all servers. Aborting flip...";
			exit 1;
		fi
		for DEST in "${SERVERS[@]}"
		do
			echo "# Flipping '$DEST' to '$VERSION_NAME'";
			ssh $DEST "cd $remote_path; bash pre-flip.sh $ENV_NAME" || true;

			if [ ! `ssh $DEST test -d $current_path || echo 0` ]; then
				ssh $DEST "rm $current_path; ln -s $remote_path $current_path";
			else
				ssh $DEST "ln -s $remote_path $current_path";
			fi
			ssh $DEST "cd $current_path; bash post-flip.sh $ENV_NAME $SERVER_APP_LOCAL_CONFIG" || true;

			if [ -n "$SERVER_POST_FLIP_COMMAND"  ]; then
			#if [ -z ${var+SERVER_POST_FLIP_COMMAND}  ]; then
				echo "#Executing Post-Flip Server Command"
				ssh $DEST "$SERVER_POST_FLIP_COMMAND"
			else
				echo "# Skipping Post-Flip Sever Command, SERVER_POST_FLIP_COMMAND not defined in conf/servers/{project}/{env}/servers"
			fi
		done
		echo "# Executing deploy server post flip";
		if [ -d $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/post-flip.sh ]; then
			$BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/post-flip.sh $VERSION_NAME || true;
		fi
		echo "# Flip Completed !"

	fi


	if $STATUS ; then
		if [ -z $ENV_NAME ]; then
			echo "Missing enviroment. Please specify enviroment using -e";
			exit 1;
		fi
		source $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME/servers;
		for DEST in "${SERVERS[@]}"
		do
			#echo `ssh $DEST "ls -al $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current | sed -nr 's|.*/(.*)|\1|p'"`;
			remote_ver=`ssh $DEST "ls -al $SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/current | sed -nr 's|.*/(.*)|\1|p'"`;
			echo "$DEST => $remote_ver";
		done
	fi


	if $BUILD -o $DEPLOY -o $FLIP ; then
		if $BUILD ; then
			FINAL_MSG="$FINAL_MSG [Build]";
		fi
		if $DEPLOY ; then
			FINAL_MSG="$FINAL_MSG [Deployment]";
		fi
		if $FLIP ; then
			FINAL_MSG="$FINAL_MSG [Flip]";
		fi
		echo "Email: $EMAIL_LIST - FROM: $EMAIL_FROM";
		FINAL_MSG="$FINAL_MSG Completed For: $PROJECT_NAME/$ENV_NAME/$VERSION_NAME";

		if [ ! -z "$EMAIL_LIST" ]
		then

			if [ ! -z "$EMAIL_FROM" ]; then
				echo -e "$FINAL_MSG\n\n\n----" | mail -r $EMAIL_FROM -s "Deployment Completed - Beaver Deployment Tool" $EMAIL_LIST
			else
				echo -e "$FINAL_MSG\n\n\n----" | mail -s "Deployment Completed - Beaver Deployment Tool" $EMAIL_LIST
			fi
		fi

		mkdir -p $APP_HOME/logs/;
		DATE=`date`;
		echo -e "$DATE: $FINAL_MSG" >> $APP_HOME/logs/actions.log
	fi
else
	echo "Lock Aquisition Failed - Quitting";
fi
