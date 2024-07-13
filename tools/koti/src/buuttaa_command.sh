koneet=()
eval "koneet=(${args[kone]:-})"
koneet=($(suodata_koneet "${koneet[@]}"))

for kone in "${koneet[@]}"; do
  echo "Käynnistä kone '$kone' uudelleen"
  ssh "root@$kone" reboot
done
