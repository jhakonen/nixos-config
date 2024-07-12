koneet=()
eval "koneet=(${args[kone]:-})"
koneet=($(suodata_koneet "${koneet[@]}"))

tehtavat=()
for kone in "${koneet[@]}"; do
  tehtavat+=("$kone:reboot")
done

if [ ${#tehtavat[@]} != 0 ]; then
  cd /home/jhakonen/nixos-config/public
  nix run '.' -- "${tehtavat[@]}"
fi
