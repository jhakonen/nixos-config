toiminto="${args[--toiminto]}"
debug=${args[--debug]}

koneet=()
eval "koneet=(${args[kone]:-})"
koneet=($(suodata_koneet "${koneet[@]}"))

tehtavat=()
for kone in "${koneet[@]}"; do
  if [ $debug ]; then
    tehtavat+=("$kone:rebuild-debug")
  else
    tehtavat+=("$kone")
  fi
done

if [ ${#tehtavat[@]} != 0 ]; then
  cd /home/jhakonen/nixos-config/public
  REBUILD_ACTION="$toiminto" nix run '.' -- --parallel "${tehtavat[@]}"
fi
