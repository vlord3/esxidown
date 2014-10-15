#!/bin/sh

errormessage(){
    echo
    echo "Valid input parameters are:"
    echo -e "\e[1;33m--shutdown\e[0m - shutdown all vm's and place into maintenance mode."
    echo -e "\e[1;33m--startup\e[0m - exit maintenance mode and startup all vm's."
    echo
    exit 1 # terminate on input error
}

#check to see if we have a valid input parameter or asking for some help
if [[ -z "$1" || "$1" == "--help" ]]; then
    clear
    if [ -z "$1" ]; then 
        echo -e "\n\e[1;31mError: Input parameter empty.\e[0m"
    fi
    errormessage
fi

if [[ "$1" != "--shutdown" && "$1" != "--startup" ]]; then
    clear
    echo 
    echo -e "\e[1;31mError: Invalid input parameter.\e[0m"
    errormessage
fi

SERVERIDS=$(vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' | awk '$1 ~ /^[0-9]+$/ {print $1}')

if [ "$1" == "--shutdown" ]; then

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
fi

if [ "$1" == "--startup" ]; then

    # enter maintenance mode immediately

    esxcli system maintenanceMode get | grep -i "enabled" > /dev/null 2<&1
    STATUS=$?
        if [ $STATUS -eq 0 ]; then
            echo "Exiting maintenance mode..."
            esxcli system maintenanceMode set -e false -t 30 &
        else
            echo "System is not in maintenance mode."
        fi

    # read each line as a server ID and shutdown/poweroff
    for SRVID in $SERVERIDS
    do
        vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
        STATUS=$?

        if [ $STATUS -eq 0 ]; then
            echo "Attempting power-on guest VM ID $SRVID..."
            vim-cmd vmsvc/power.on $SRVID
        else
            echo "Guest VM ID $SRVID already powered on..."
        fi
    done

    # guest vm shutdown complete

    for SRVID in $SERVERIDS
    do
        vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
        STATUS=$?
        if [ $STATUS -eq 0 ]; then
            while [ $STATUS -eq 0 ]; do
                echo "Waiting for VM ID $SRVID to power-on."
                sleep 5
                vim-cmd vmsvc/power.getstate $SRVID | grep -i "off" > /dev/null 2<&1
              STATUS=$?
            done
            echo "Guest VM $SRVID power-on complete."
        fi
    done
              
    # exit the session
    echo "Done!"
    exit
fi
