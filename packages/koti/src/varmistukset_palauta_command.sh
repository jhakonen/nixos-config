taltio="${args[taltio]}"
kohde="$(realpath "${args[kohde]}")"

lahde="rsync-backup@nas::backups/normal/${taltio//taltio:/}/"

echo "Palautetaan '$lahde' kansioon '$kohde/'"
if [[ "$(read -r -e -p 'Jatketaanko? [k/E]> '; echo "$REPLY")" == [KkYy]* ]]; then
  mkdir -p "$kohde"
  rsync -av --password-file=/var/run/agenix/jhakonen-rsyncbackup-password "$lahde" "$kohde"
fi
