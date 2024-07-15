validate_on_taltio() {
  [[ "$1" =~ (^taltio:.+/.+$) ]] || echo "'$1' ei ole taltio"
}
