rsync \
  --recursive \
  --exclude '*/*/*' \
  --password-file=/var/run/agenix/jhakonen-rsyncbackup-password \
  "rsync-backup@nas::backups/normal/" \
    | grep '^d' | awk '{print $NF}' | grep -v '^.$' | grep '/' | sed -e 's/^/taltio:/'
