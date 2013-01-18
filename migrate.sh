#!/bin/bash

APP_HOME=$HOME/.bvrconfig;
PID=$$;
echo "## Backign up bvr to:";
echo $HOME/.bvrconfig $HOME/.bvrconfig-$PID;
echo "## Delete this if no errors reported!";
 
cp -r $HOME/.bvrconfig $HOME/.bvrconfig-$PID;


#echo "## Migrating Archives:";
#
#for dir in `ls "$APP_HOME/archive/"`
#do
#	if [ -d "$APP_HOME/archive/$dir" ]; then
#		for ver in `ls "$APP_HOME/archive/$dir"`
#		do
#			if [ -d "$APP_HOME/archive/$dir/$ver" ]; then				
#				tar zxvf "$APP_HOME/archive/$dir/$ver/package.tgz" -C "$APP_HOME/archive/$dir/$ver/";
#				rm -rf "$APP_HOME/archive/$dir/$ver/package.tgz";
#			fi
#		done
#	fi	
#done
#echo "## Archives done";

echo "## Migrating configs";
mkdir -p $APP_HOME/conf/sources
for dir in `ls "$APP_HOME/source/"`
do
	if [ -d "$APP_HOME/source/$dir" ]; then
		if grep -q "git clone" $APP_HOME/source/$dir/source
		then
			echo "Git Repo";
			mkdir -p $APP_HOME/conf/sources/$dir/;
			rm $APP_HOME/conf/sources/$dir/source;
			echo "REPO_TYPE=\"git\"" >> $APP_HOME/conf/sources/$dir/source;
			REPO_URL=`sed -nr 's|.*git\s+clone\s+(.+)\s\\$SOURCE_DIR\;\s+cd.*|\1|p' $APP_HOME/source/$dir/source`;
			echo $REPO_URL;
			echo "REPO_URL=\"$REPO_URL\"" >>  $APP_HOME/conf/sources/$dir/source;
			echo "DEFAULT_BRANCH=\"master\"" >> $APP_HOME/conf/sources/$dir/source; 

			#cat $APP_HOME/source/$dir/source | sed -r 's#.*(.*)\s+.*#\1#';
		else
			echo "SVN Repo";
			mkdir -p $APP_HOME/conf/sources/$dir/;
			rm $APP_HOME/conf/sources/$dir/source;
			echo "REPO_TYPE=\"svn\"" >> $APP_HOME/conf/sources/$dir/source;			
			#cat $APP_HOME/source/$dir/source;
			REPO_URL=`sed -nr 's|.*\\$REVISON\s(.+://.+)/\\$BRANCH.*|\1|p' $APP_HOME/source/$dir/source`;
			echo $REPO_URL;
			echo "REPO_URL=\"$REPO_URL\"" >>  $APP_HOME/conf/sources/$dir/source;
			echo "DEFAULT_BRANCH=\"trunk\"" >> $APP_HOME/conf/sources/$dir/source;
		fi 
	fi	
done
cp -r $APP_HOME/servers $APP_HOME/conf/
 
echo "## Configs Done";