function rsync_listaa() {
  rsync --password-file=/var/run/agenix/rsyncbackup-password "rsync-backup@nas::backups/normal/$1"
}

function vain_tiedostojen_nimet() {
  grep '^d' | awk '{print $NF}' | grep -v '^.$'
}

kone=${args[kone]}
palvelu=${args[palvelu]}

if [ "$kone" == "" ]; then
  rsync_listaa | vain_tiedostojen_nimet
elif [ "$palvelu" == "" ]; then
  rsync_listaa "$kone/" | vain_tiedostojen_nimet
else
  rsync_listaa "$kone/$palvelu/"
fi
