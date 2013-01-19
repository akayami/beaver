function reset_source() {
	echo "Checking out from svn"
	dir=$1;
	url=$2
	branch=$3
	rev=$4
    if [ ! -d $dir ]; then
    	mkdir -p $dir;
    fi
    if [ ! -d $dir/.svn ]; then
		svn checkout $url $dir;
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
	local source=$1;
	local archive=$2;
	local branch=$3;
	local rev=$4;
	mkdir -p $archive/payload/;
	cp -r $source/* $archive/payload;
	if [ -f $archive/payload/post-checkout.sh ]; then
		echo "# Executing post checkout";
		local old=`pwd`;
		cd $archive/payload/;
		bash post-checkout.sh $source $archive $branch $rev;
		cd $old;
	fi
	get_last_commit_id $source > $archive/commit_id;
	echo -e "BRANCH=$branch\nREVISION=$rev\nSTAMP=$STAMP" > $archive/release_info;	
}
