# Attempts to aquire lock, if fails, checks if previous lock owner is still alive, if not, takes over. 
# Self healing locking mechanism. Should be atomic as long as locking happens or real File System and not Network FS.

# args: path
function create_lock() {
	LOCK_PATH="$1"
	LOCK_FILE=${LOCK_PATH}.lock.d;
	if mkdir -p "${LOCK_FILE}"; then
		#echo "Created lock file for pid $$";
		echo "$$" > $LOCK_FILE/pid
		return 0;
	else
		LOCK_PID=`cat $LOCK_FILE/pid`;
		echo $LOCK_PID;
		if kill -s 0 $LOCK_PID; then 
			echo "Lock Failed - Another process $LOCK_PID is still running.. Wait till it is done";
			return 1;
		else
			echo "Zombi process $LOCK_PID hold lock... Cleaning up..";
			echo "$$" > $LOCK_FILE/pid
			return 0;
		fi
	fi	
}

# args: path
function remove_lock() {	
	LOCK_PATH="$1";
	LOCK_FILE=${LOCK_PATH}.lock.d;
	#rmdir "${LOCK_PATH}.lock.d"
	if ! rm -rf $LOCK_FILE; then
			echo "Failed to remove lock ?..: $LOCK_FILE"			
	fi
}