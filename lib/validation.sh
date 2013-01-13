if [ -z "$PROJECT_NAME" -o ! -d $BVR_HOME/sources/$PROJECT_NAME ]; then
	echo "Error: Project does not exist. Available projects:";
	ls $BVR_HOME/sources;
	exit;
fi

if [ ! -f $BVR_HOME/sources/$PROJECT_NAME/source ]; then 
	echo "Project source config missing in: $BVR_HOME/sources/$PROJECT_NAME/source !";
	exit;
fi


function check_enviorment() {
	local ENV_NAME=$1;
	local dir=$2;
	if [[ ! -d "$dir/$ENV_NAME" || -z $ENV_NAME ]] ; then
		return 0;
	else
		return 1;
	fi
}

if $DEPLOY ; then
	#echo "Deploying...";
	if [ -z $VERSION_NAME ] ; then 
		id=`get_last_commit_id $REPO_SOURCE`;
		if find_revision $BVR_ARCHIVE_HOME $id ; then
			echo "# Specific version tag was not provided, therefore the latest existing version will be used: $NEWEST_MATCHING_VERSION";
			VERSION_NAME=$NEWEST_MATCHING_VERSION;
			BUILD=false;
		else
			BUILD=true;  			  			  			
		fi
	fi
fi

if $ENV_PROVIDED ; then	
	while check_enviorment $ENV_NAME "$BVR_HOME/servers/$PROJECT_NAME" ; do
		echo "Error: Enviroment '$ENV_NAME' is not configured for project $PROJECT_NAME";
		echo "Looking for: $BVR_HOME/servers/$PROJECT_NAME/$ENV_NAME";
		echo "Available Enviroments:";
		ls $BVR_HOME/servers/$PROJECT_NAME/;
		exit;
		#echo -n "Please provide a valid enviorment name:";
		#read ENV_NAME;
	done
fi