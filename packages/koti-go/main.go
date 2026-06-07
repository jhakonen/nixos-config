package main

import (
	"fmt"
	"os"
	"os/exec"
)

type kone_speksi struct {
	nimi    string
	buuttaa bool
}

var kaikki_kone_speksit = []kone_speksi{
	kone_speksi{nimi: "dellxps13", buuttaa: false},
	kone_speksi{nimi: "kanto", buuttaa: true},
	kone_speksi{nimi: "mervi", buuttaa: true},
	kone_speksi{nimi: "nassuvm", buuttaa: true},
	kone_speksi{nimi: "tunneli", buuttaa: true},
}

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
	koneet := suodataKoneet(selvitäBuutattavatKoneet(argumentit))
	fmt.Printf("TODO: Ei toteutettu, koneet: %v\n", koneet)
}

func muokkaa() {
	fmt.Println("TODO: Ei toteutettu")
}

func rakenna(argumentit []string) {
	fmt.Println("TODO: Ei toteutettu")
}

func selvitäBuutattavatKoneet(koneNimet []string) []string {
	kone_speksit := suodata(kaikki_kone_speksit, func(kone kone_speksi) bool {
		return kone.buuttaa
	})
	if len(koneNimet) != 0 {
		kone_speksit = suodata(kone_speksit, func(kone kone_speksi) bool {
			for _, koneNimi := range koneNimet {
				if kone.nimi == koneNimi {
					return true
				}
			}
			return false
		})
	}
	return muunna(kone_speksit, haeKoneenNimi)
}

func suodataKoneet(koneNimet []string) []string {
	tulokset := []string{}
	for _, koneNimi := range koneNimet {
		cmd := exec.Command("ping", "-W1", "-c1", koneNimi)
		err := cmd.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Kone '%v' ei vastaa\n", koneNimi)
			continue
		}
		tulokset = append(tulokset, koneNimi)
	}
	return tulokset
}

func suodata[T any](lista []T, fn func(T) bool) []T {
	arvot := []T{}
	for _, arvo := range lista {
		if fn(arvo) {
			arvot = append(arvot, arvo)
		}
	}
	return arvot
}

func muunna[T any, E any](lista []T, fn func(T) E) []E {
	arvot := []E{}
	for _, arvo := range lista {
		arvot = append(arvot, fn(arvo))
	}
	return arvot
}

func haeKoneenNimi(kone kone_speksi) string {
	return kone.nimi
}
