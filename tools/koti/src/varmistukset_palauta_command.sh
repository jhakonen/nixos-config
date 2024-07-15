kone="${args[kone]}"
palvelu="${args[palvelu]}"
kohde="${args[kohde]}"

mkdir -p "$kohde"
rsync -av --password-file=/var/run/agenix/rsyncbackup-password \
  "rsync-backup@nas::backups/normal/$kone/$palvelu/" "$kohde"
