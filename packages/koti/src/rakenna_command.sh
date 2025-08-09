toiminto="${args[--toiminto]}"
debug=${args[--debug]}

koneet=()
eval "koneet=(${args[kone]:-})"
mapfile -t koneet < <(suodata_koneet "${koneet[@]}")

cd /home/jhakonen/nixos-config
for kone in "${koneet[@]}"; do
  komento=("nh" "os" "$toiminto")

  if [ "$kone" != "$(hostname)" ]; then
    komento+=("--hostname" "$kone" "--build-host" "root@$kone" "--target-host" "root@$kone")

    # Varmista että SSH-komento ei kysy että luotetaanko koneeseen
    ssh-keygen -R "$kone" >/dev/null
    ssh-keyscan "$kone" 2>/dev/null >> ~/.ssh/known_hosts
  fi

  komento+=(".")

  if [ "$debug" ]; then
    komento+=("--" "--show-trace")
  fi

  # HACK: https://github.com/nix-community/nh/issues/308#issuecomment-3170507744
  if [ "$kone" == "toukka" ]; then
    komento=("nixos-rebuild-ng" "$toiminto" "--flake" ".#$kone" "--no-reexec" "--build-host" "root@$kone" "--target-host" "root@$kone")
  fi

  echo "${komento[@]}"
  apu_komento=("systemd-inhibit" "--who" "nixos-rebuild $kone" "--why" "Rakennetaan $kone konetta")
  apu_komento+=("${komento[@]}")
  eval "${apu_komento[*]@Q}"
  rm -f ./result
done
