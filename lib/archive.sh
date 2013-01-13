function print_archives() {
	echo -e "\n# Showing archived releases\n";
	IFS=$'\n';
	local arr=(`ls -t $1`);
	local len=${#arr[*]}
	local index=1;
	for item in "${arr[@]}"
	do
		echo $item;
		index=$(($index+1));
		if [ ! -z $LENGTH ]; then
			if [ "$LENGTH" -lt "$index" ]; then
				echo "# Reached limit $LENGTH. A total of $len available";
	 			break;
	 		fi
		fi			
	done
	echo -e "\n# End of archives\n";
}

function find_revision() {
	local current=`pwd`;
	local path=$1;
	local rev=$2;
	IFS=$'\n';
	cd $path;
	local arr=(`ls -td $(grep -R $rev . | grep commit_id | sed -r 's/\.\/(.+)\/.*/\1/')`);
	local len=${#arr[*]}
	NEWEST_MATCHING_VERSION=""
	if [ $len -gt 0 ]; then
		echo "# Found archived versions with same commit id: $rev"
		for item in "${arr[@]}"
		do
			if [ -z $NEWEST_MATCHING_VERSION ]; then
				NEWEST_MATCHING_VERSION=$item;
			fi
			echo $item;
		done
	fi
	cd $current;
	if [ $len -gt 0 ]; then 
		return 0;
	else 
		return 1;
	fi
}

function printe_archive_info() {
	path=$1;
	version=$2
	cat $path/$version/commit_id
	cat $path/$version/release_info
}