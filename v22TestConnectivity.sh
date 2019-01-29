#!/bin/bash
# Define variables
ManagerDaemon="/Library/LaunchDaemons/com.graphisoft.PortalServerService-v22.0(Manager-installation-date).plist"
ServerDaemon="/Library/LaunchDaemons/com.graphisoft.TeamworkApplicationServerMonitor-v22.0(Server-installation-date).plist"
ConnectivityLog="/Path/to/log/file"
check_process=( "TeamworkApplicationServerMonitor" "TeamworkServiceProcessManagerAgent" "TeamworkServiceProcessManagerAgent" "TeamworkPortalServerManager" "TeamworkApplicationServer" "BIMcloudMonitor" "BIMcloudMonitor Helper")
Share01='afp://USER:PASSWORD@ASERVER/SHARE'
MountPoint01="/Volumes/SHARE"
ShareName="NameOfShare"
User01="USER"
email="yourEmail"

## Delete yesterdays Connectivity log.
rm -rf "${ConnectivityLog}"
# Create ConnectivityLog.
touch "${ConnectivityLog}"
# Check if disks are mounted.
if mount | grep -q "${MountPoint01}"; then
  echo "Share \"${ShareName}\" it still mounted at "$(date -u)", No furhter action needed." 2>&1 | tee -a "${ConnectivityLog}" ; mail -s "The share \"${ShareName}\" is still mounted" "${email}" < "${ConnectivityLog}"
  exit 1
else
    # If share is not mounted, stop BIM-server and BIM-manager
    launchctl unload "${ServerDaemon}"
    launchctl unload "${ManagerDaemon}"
    # When the BIM-server and BIM-manager is stopped, try to mount share
    # Make mount point for share
    mkdir "${MountPoint01}"
    # Set the correct permissions to user. Needs to be staff.
    chown "${User01}":staff "${MountPoint01}"
    # This script is run by root, therfore the mount mounting of the share must be done by a regular user. Unless you have no acces to share.
    sudo -u "${User01}" mount_afp "${Share01}" "${MountPoint01}"
    # Then check if share is mounted
    if mount | grep -q "${MountPoint01}"; then
        # If share is mounted, restart BIM-server and BIM-manager
        launchctl load "${ServerDaemon}"
        launchctl load "${ManagerDaemon}"
        # Check if the needed processes are running
        for check_process in "${check_process_names[@]}"; do
            if pgrep -q "${check_process}"; then
                echo "Process \"${check_proces}\" is running"  2>&1 | tee -a "${ConnectivityLog}"
            else
                echo "Process \"${check_process}\" is NOT running"  2>&1 | tee -a "${ConnectivityLog}"
            fi
        done
    else
        # If share was not mounted, send logfile by email and exit. Need to take action
        echo "I'm at "$(date -u)" unable to mount share \"${ShareName}\". You need to take action." 2>&1 | tee -a "${ConnectivityLog}" ; mail -s "Unable to mount Share \"${ShareName}\"" "${email}" < "${ConnectivityLog}"
        exit 1
    fi
    # If share & processes are running, send email about the insident.
    echo "Share \"${ShareName}\" went offline around "$(date -u)". Everything seems to be ok now, but you should investigate." 2>&1 | tee -a "${ConnectivityLog}" ; mail -s "Share \"${ShareName}\" is back on line" "${email}" < "${ConnectivityLog}"
fi
# end sctipt
