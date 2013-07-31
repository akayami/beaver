function reset_source() {
	echo "Checking out from git"
	dir=$1;
	url=$2
	branch=$3
	rev=$4
	if [ ! -d $dir ]; then
		mkdir -p $dir;
	fi
	if [ ! -d $dir/.git ]; then
		git clone $url $dir;
	fi
	cd $dir;
	git pull
	git checkout $branch
	git fetch $url $branch
	git pull
	if [ ! -z $rev ]; then 
		echo "Revision provided";
		git reset --hard $rev
	fi
}

function get_last_commit_id() {
	local old=`pwd`;
	cd $1;
	git log --max-count=1 | sed -rn '/commit/ s/commit (.+)/\1/p'
	cd $old;
}

function show_full_info() {
	pushd . >/dev/null
	
	# Find base of git directory
	while [ ! -d .git ] && [ ! `pwd` = "/" ]; do cd ..; done
	
	# Show various information about this git directory
	if [ -d .git ]; then
	  echo "== Remote URL: `git remote -v`"
	
	  echo "== Remote Branches: "
	  git branch -r
	  echo
	
	  echo "== Local Branches:"
	  git branch
	  echo
	
	  echo "== Configuration (.git/config)"
	  cat .git/config
	  echo
	
	  echo "== Most Recent Commit"
	  git log --max-count=1
	else
	  echo "Not a git repository."
	fi
	
	popd >/dev/null
}

function copy_source_to_archive() {
	source=$1
	archive=$2
	branch=$3
	rev=$4
	mkdir -p $archive/payload/
	cp -r $source/* $archive/payload
	if [ -f $archive/payload/post-checkout.sh ]; then
		echo "# Executing post checkout";
		local old=`pwd`;
		cd $archive/payload/;
		bash post-checkout.sh $source $archive $branch $rev;
		cd $old;
	fi
	get_last_commit_id $source > $archive/commit_id
	echo -e "BRANCH=$branch\nREVISION=$REVISION\nSTAMP=$STAMP" > $archive/release_info 
}