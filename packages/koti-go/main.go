package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Käyttö: koti <komento> [valinnat]")
		fmt.Fprintln(os.Stderr, "Komennot: buuttaa, muokkaa, rakenna")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "buuttaa":
		buuttaa(os.Args[2:])
	case "muokkaa":
		muokkaa()
	case "rakenna":
		rakenna(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "Tuntematon komento: %v\n", os.Args[1])
		os.Exit(1)
	}
}

func buuttaa(argumentit []string) {
	fmt.Println("TODO: Ei toteutettu")
}

func muokkaa() {
	fmt.Println("TODO: Ei toteutettu")
}

func rakenna(argumentit []string) {
	fmt.Println("TODO: Ei toteutettu")
}
