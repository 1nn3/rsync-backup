#
# Regular cron jobs for the rsync-backup package
#

# maintenance
0 4	* * *	root	[ -x /usr/bin/rsync-backup_maintenance ] && /usr/bin/rsync-backup_maintenance

0 0	1 * *	root	mail -s "It's time for a Backup! Isn't it?" root%Run rsync-backup(1) now!%GO! GO! GO!

0 4	* * *	root	[ -x /usr/bin/smartcheck ] && /usr/bin/smartcheck

