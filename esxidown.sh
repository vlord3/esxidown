#!/bin/sh
# ESXi 5.1 host automated vm shutdown - enter maintenance mode script

# these are the VM IDs to shutdown in the order specified
# use the SSH shell, run "vim-cmd vmsvc/getallvms" to get ID numbers
# specify IDs separated by a space
SERVERIDS=$(vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' | awk '$1 ~ /^[0-9]+$/ {print $1}')

# read each line as a server ID and shutdown/poweroff
for SRVID in $SERVERIDS
do
    vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
    STATUS=$?

    if [ $STATUS -ne 0 ]; then
        echo "Attempting shutdown of guest VM ID $SRVID..."
        vim-cmd vmsvc/power.shutdown $SRVID
    else
        echo "Guest VM ID $SRVID already off..."
    fi
done

# guest vm shutdown complete

for SRVID in $SERVERIDS
do
	vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
    STATUS=$?
	if [ $STATUS -ne 0 ]; then
		while [ $STATUS -ne 0 ]; do
			echo "Waiting for VM ID $SRVID to shutdown."
			sleep 5
			vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
      	  STATUS=$?
		done
		echo "Guest VM $SRVID shutdown complete."
	fi
done

# enter maintenance mode immediately

esxcli system maintenanceMode get | grep -i "Disabled" > /dev/null 2<&1
STATUS=$?
    if [ $STATUS -eq 0 ]; then
		echo "Entering maintenance mode..."
		esxcli system maintenanceMode set -e true -t 30 &
	else
		echo "System is already in maintenance mode."
	fi
			
# exit the session
echo "Done!"
exit
