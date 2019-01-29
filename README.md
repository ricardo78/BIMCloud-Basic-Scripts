# BIMCloud Basic Scripts
Disclaimer: Use these at your own risk!

this is collection of bash scripts for preforming backup of a Graphisoft BIMCloud Basic server and checking connectivity to mounted network share. The scripts are based on the example script found in the [Graphisoft backup documentation](http://download.graphisoft.com/ftp/techsupport/downloads/BIMcloud/IH/Backup_Guides). My knowledge of bash scripting is limited, and I'm sure that there are more efficient ways of doing it, hence this share. I would really like to make them more efficient and robust.

To explain what I'm trying to achieve:
In order to do a proper backup of the entire BIMCloud Basic (BCB), you need to stop the BCB-manager and server.This is to avoid possible corruption of the data. Therefor you need to stop the server, preform the backup and restart the server again. You can use the TeamworkServerBackupTool to export backup files of individual projects, which is nice, but if your BCB-server is corrupted in some way, you need to build it up form the bottom, instead of just doing a clean install and copy the manager and server data to its respective places.

I perform both backup methods. Copy the BCB-manager and server data in its entirety and use the TeamworkServerBackupTool. This is because sometimes it is good to have a choice between a full server restore or just import a specific project without snapshots and history. All depends on timeframe at hand and the level of damage.

In my setup, we have BIMCloud Basic running on a Mac Pro, where the BCB stores its project files and Libraries on a network share. From there it does a cloud backup.

The script "v22BCBServerAndManagerBkUp.sh" basically does the following:
1. Check if the network share is mounted, if yes -
2. stops the BIM-manager and -server.
3. Copy the entire BIM-manager and -server data, using basic copy function and in addition running Graphisoft's TeamworkServerBackupTool (See [Graphisoft documentation](http://download.graphisoft.com/ftp/techsupport/downloads/BIMcloud/IH/Backup_Guides)). 
4. Check if necessary processes are running, if yes-
5. restart the BIM-manager and -server.
6. Send email about status. I have configured postfix to send e-mail notifications using [this method](https://codana.me/2014/11/23/sending-gmail-from-os-x-yosemite-terminal/).

The script "v22TestConnectivity.sh" check periodically if the network share is still mounted.

The script will run as follow:
Test if the share is mounted. If yes, exit. If no, stop manager and server and try to mount the share. If able to mount share, start manager and server and send email about the incident and exit. IF not able, send email en exit.

To run the scripts I have to plist files that I add to /Library/LaunchDeamons folder.
