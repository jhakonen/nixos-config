function suodata_koneet() {
  koneet=()
  for kone in "$@"; do
    if ping -W1 -c1 "$kone" 1>/dev/null 2>/dev/null; then
      koneet+=("$kone")
    else
      echo "${PUNAINEN}Kone '$kone' ei vastaa${NOLLAA}" >&2
    fi
  done
  echo "${koneet[@]}"
}
