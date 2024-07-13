function lopeta_tehtavat() {
  jobs -p | xargs -r kill
}

toiminto="${args[--toiminto]}"
debug=${args[--debug]}

koneet=()
eval "koneet=(${args[kone]:-})"
koneet=($(suodata_koneet "${koneet[@]}"))

komennot=()
for kone in "${koneet[@]}"; do
  komento="nixos-rebuild $toiminto --flake '.#$kone' --fast"

  if [ "$kone" != "$(hostname)" ]; then
    komento+=" --build-host root@$kone --target-host root@$kone"

    # Varmista että SSH-komento ei kysy että luotetaanko koneeseen
    ssh-keygen -R "$kone" >/dev/null
    ssh-keyscan "$kone" 2>/dev/null >> ~/.ssh/known_hosts
  elif [ "root" != "$(whoami)" ]; then
    echo "${PUNAINEN}Koneen '$kone' uudelleenrakennus vaatii sudo-oikeudet${NOLLAA}" >&2
    exit 1
  fi

  if [ $debug ]; then
    komento+=" --show-trace"
  fi
  komennot+=("$komento")
done

# Aja nixos-rebuild kullekkin koneelle
trap lopeta_tehtavat EXIT
cd /home/jhakonen/nixos-config/public
for i in "${!koneet[@]}"; do
  kone="${koneet[$i]}"
  komento="${komennot[$i]}"
  echo $komento
  # Aja nixos-rebuild taustalla jotta koneiden rebuild voidaan tehdä samaan
  # aikaan kaikille koneille rinnakkain
  ets -f "[%T.%L - $kone]" "$komento" 2>/dev/null &
done

# Odota nixos-rebuild komentojen valmistumista
while [ "$(jobs -p)" != "" ]; do
  if ! wait -n; then
    # Jokin tehtävistä epäonnistui, joten poistu ja trapin kautta lopeta muut
    # ajossa olevat tehtävät
    exit 1
  fi
done
