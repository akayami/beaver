function check_enviorment() {
	local ENV_NAME=$1;
	local dir=$2;
	if [[ ! -d "$dir/$ENV_NAME" || -z $ENV_NAME ]] ; then
		return 0;
	else
		return 1;
	fi
}

#if $DEPLOY ; then
	#echo "Deploying...";
	#	if [ -z $VERSION_NAME ] ; then 
		#	id=$(get_last_commit_id $REPO_SOURCE);
		#VERSION_NAME=$id;
	#fi
#fi

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