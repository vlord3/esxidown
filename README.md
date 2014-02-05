ESXi Auto Maintenance Mode Script v1.0
======================================

This script can be used to help gracefully shut down virtual machines and enter your host into maintenance mode, for example, in the case of a patch update.

Deploy the scripts on an ESXi 5.1 (or greater) attached datastore.  Make sure they are executable (chmod +x) by the user who will be running the script.

Get the VM IDs using vim-cmd vmsvc/getallvms and customize the vm_maint.sh script.

By default, the script will shut down each guest VM gracefully. If it cannot it will loop indefinitely. You MUST have VMware tools installed on each of your vm's.

The script can be run via SSH.
