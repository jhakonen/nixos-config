function lopeta_tehtavat() {
  jobs -p | xargs -r kill
}

function suodata_stderr() {
  # Tämä tulee ets-komennosta kun se ajetaan taustalla
  sed 's/error resizing pty: bad address//g'
}

toiminto="${args[--toiminto]}"
debug=${args[--debug]}

koneet=()
eval "koneet=(${args[kone]:-})"
mapfile -t koneet < <(suodata_koneet "${koneet[@]}")

# Aja nixos-rebuild kullekkin koneelle
trap lopeta_tehtavat EXIT
cd /home/jhakonen/nixos-config/public
for kone in "${koneet[@]}"; do
  komento=("nixos-rebuild" "$toiminto" "--flake" ".#$kone" "--fast")

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
  eval "${apu_komento[*]@Q}" 2> >(suodata_stderr >&2) &
done

# Odota nixos-rebuild komentojen valmistumista
while [ "$(jobs -p)" != "" ]; do
  if ! wait -n; then
    # Jokin tehtävistä epäonnistui, joten poistu ja trapin kautta lopeta muut
    # ajossa olevat tehtävät
    exit 1
  fi
done
