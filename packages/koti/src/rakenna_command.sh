toiminto="${args[--toiminto]}"
debug=${args[--debug]}

koneet=()
eval "koneet=(${args[kone]:-})"
mapfile -t koneet < <(suodata_koneet "${koneet[@]}")

cd /home/jhakonen/nixos-config
for kone in "${koneet[@]}"; do
  komento=("nixos-rebuild-ng" "$toiminto" "--flake" ".#$kone" "--no-reexec")

  if [ "$kone" != "$(hostname)" ]; then
    komento+=("--build-host" "root@$kone" "--target-host" "root@$kone")

    # Varmista että SSH-komento ei kysy että luotetaanko koneeseen
    ssh-keygen -R "$kone" >/dev/null
    ssh-keyscan "$kone" 2>/dev/null >> ~/.ssh/known_hosts
  elif [ "root" != "$(whoami)" ]; then
    echo "${PUNAINEN}Koneen '$kone' uudelleenrakennus vaatii sudo-oikeudet${NOLLAA}" >&2
    exit 1
  fi

  if [ "$debug" ]; then
    komento+=("--show-trace")
  fi

  echo "${komento[@]}"
  apu_komento=("systemd-inhibit" "--who" "nixos-rebuild $kone" "--why" "Rakennetaan $kone konetta")
  apu_komento+=("ets" "-f" "[%T.%L - $kone]")
  apu_komento+=("${komento[@]}")
  eval "${apu_komento[*]@Q}"
done
