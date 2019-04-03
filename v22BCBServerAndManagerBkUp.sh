#!/bin/bash
# Adjust path for the below components. Projects, Libraries and Manager Data folders can be in special locations!
ManagerDir="/The/Installation/Directory/of/BIMcloud/Manager-<installation-date>"
ManagerDataDir="/The/Installation/Directory/of/BIMcloud/Manager-<installation-date>/Data"
ServerDir="/The/Installation/Directory/of/BIMcloud/Server-<installation-date>"
ProjectDir="/The/Installation/Directory/of/BIMcloud/Server-<installation-date>/Projects"
LibraryDir="/The/Installation/Directory/of/BIMcloud/Server-<installation-date>/Attachments"
localBkUp="/Backup/Folder/Location"
ManagerDaemon="/Library/LaunchDaemons/com.graphisoft.PortalServerService-v22.0(Manager-installation-date).plist"
ServerDaemon="/Library/LaunchDaemons/com.graphisoft.TeamworkApplicationServerMonitor-v22.0(Server-installation-date).plist"
# Check if necessary processes are running
check_process=( "TeamworkApplicationServerMonitor" "TeamworkServiceProcessManagerAgent" "TeamworkServiceProcessManagerAgent" "TeamworkPortalServerManager" "TeamworkApplicationServer" "BIMcloudMonitor" "BIMcloudMonitor Helper")
# Log-files. Should be stored locally on the BIMserver and not on the network share
BkUpLog="/Path/to/logfiles"
# Connected network share
ShareName="NameOfShare"
MountPoint01="/Volumes/NameOfShare"
# The SingleRestoreProjectBackup uses the TeamworkServerBackupTool in addition to copying the manager and server.
SingleRestoreProjectBackup="/Path/to/store/backup/files"
email="yourEmail"

# Delete yesterdays backup log file.
rm -rf "${BkUpLog}"
# Create the backup log file.
touch "${BkUpLog}"

# Then check if the network share is mounted.
if mount | grep -q "${MountPoint01}"; then
  echo "The share \"${ShareName}\" is at "$(date)" mounted" 2>&1 | tee -a "${BkUpLog}"
else
  launchctl unload "${ServerDaemon}"
  launchctl unload "${ManagerDaemon}"
  echo "The share \"${ShareName}\" is at "$(date -u)" NOT mounted. I have shut down BIMCloud Basic. You need to take action!" 2>&1 | tee -a "${BkUpLog}" ; mail -s "BIMCloud BAsic is shut down" "${email}" < "${BkUpLog}"
  exit 1
fi

# Checking if manager or server directory or the backup folder does not exist
if [[ ! -d ${ManagerDir} ]] || [[ ! -d ${ServerDir} ]] ; then
  echo "The manager or server directory does not exist at "$(date -u)"" 2>&1 | tee -a "${BkUpLog}" ; mail -s "The manager or server directory of \"${ShareName}\" is missing" "${email}" < "${BkUpLog}"
  exit 1
elif [[ ! -dw ${localBkUp} ]] ; then
  echo "${localBkUp}"" folder does not exist or the folder is not writable at "$(date -u)"" 2>&1 | tee -a "${BkUpLog}" ; mail -s "The Backupfolder of \"${ShareName}\" is missing" "${email}" < "${BkUpLog}"
  exit 1
fi

# Cleaning the backup folder
rm -rf "${localBkUp}/Manager"
rm -rf "${localBkUp}/Server"

# Creating folders for the Backup
mkdir -pv "${localBkUp}/Manager"
mkdir -pv "${localBkUp}/Server"

# Checking if the subfolders cannot be created
if [[ ! -dw "${localBkUp}/Manager" ]] || [[ ! -dw "${localBkUp}/Server" ]] ; then
  echo "The subfolders in ${localBkUp} cannot be created or the folders are not writable at "$(date -u)"" ; mail -s "Subfolders cannot be created for share \"${ShareName}\"" "${email}" < "${BkUpLog}"
  exit 1
fi

# Stopping Server and Manager
launchctl unload "${ServerDaemon}"
launchctl unload "${ManagerDaemon}"

# Copying the Manager's data
cp -R "${ManagerDir}/Config" "${localBkUp}/Manager"
cp -R "${ManagerDataDir}" "${localBkUp}/Manager"

# Copying the Server's data
cp -R "${LibraryDir}" "${localBkUp}/Server"
cp -R "${ServerDir}/Config" "${localBkUp}/Server"
cp -R "${ServerDir}/Mailboxes" "${localBkUp}/Server"
cp -R "${ProjectDir}" "${localBkUp}/Server"
cp -R "${ServerDir}/Sessions" "${localBkUp}/Server"

# Start the BackupTool and create project resotre files. Will create BIMProject and BIMLibrary files
"${ServerDir}/TeamworkServerBackupTool" "${SingleRestoreProjectBackup}" 2>&1 | tee -a "${BkUpLog}"

# Restarting Server service
launchctl load "${ServerDaemon}"
launchctl load "${ManagerDaemon}"

# Check if the needed processes are running
for check_process in "${check_process[@]}"; do
    if pgrep -q "${check_process}"; then
        echo "Process \"${check_process}\" is running"  2>&1 | tee -a "${BkUpLog}"
    else
        echo "Process \"${check_process}\" is NOT running"  2>&1 | tee -a "${BkUpLog}"
    fi
done
mail -s "Backup report for \"${ShareName}\"" "${email}" < "${BkUpLog}"
# end sctipt
