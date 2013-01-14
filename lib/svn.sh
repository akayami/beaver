function reset_source() {
	echo "Checking out from svn"
	dir=$1;
	url=$2
	branch=$3
	rev=$4
	if [ ! -d $dir ]; then
		mkdir -p $dir;
		svn checkout $url/$branch $dir;
	fi
	cd $dir;
	if [ ! -z $rev ]; then 
		echo "Revision provided";
		svn up -r $rev;
	else
		svn update;
	fi
}

function get_last_commit_id() {
	local old=`pwd`;
	cd $1;
	svn info | sed -rn 's/.*Revision:\s+([0-9]+).*/\1/p'	
	cd $old;
}

function copy_source_to_archive() {
	source=$1;
	archive=$2;
	branch=$3;
	rev=$4;
	mkdir -p $archive/payload/;
	cp -r $source/* $archive/payload;
	find $archive/payload/ -name ".svn" -type d -exec rm -rf {} \; > /dev/null 2>&1;	
	get_last_commit_id $source > $archive/commit_id;
	echo -e "BRANCH=$branch\nREVISION=$rev\nSTAMP=$STAMP" > $archive/release_info;	
}
