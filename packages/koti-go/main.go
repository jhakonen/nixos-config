package main

import (
	"fmt"
	"os"
	"os/exec"
	"github.com/jhakonen/koti-go/koti"
)

type machineSpec struct {
	name string
	boot bool
}

var allMachineSpecs = []machineSpec{
	machineSpec{name: "dellxps13", boot: false},
	machineSpec{name: "kanto", boot: true},
	machineSpec{name: "mervi", boot: true},
	machineSpec{name: "nassuvm", boot: true},
	machineSpec{name: "tunneli", boot: true},
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Käyttö: koti <komento> [valinnat]")
		fmt.Fprintln(os.Stderr, "Komennot: buuttaa, muokkaa, rakenna")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "buuttaa":
		bootMachines(os.Args[2:])
	case "muokkaa":
		modifyConfig()
	case "rakenna":
		buildMachines(os.Args[2:])
	default:
		fmt.Fprintf(os.Stderr, "Tuntematon komento: %v\n", os.Args[1])
		os.Exit(1)
	}
}

func bootMachines(arguments []string) {
	koneet := filterReachable(filterBootable(arguments))
	for _, kone := range koneet {
		fmt.Printf("Käynnistä kone '%v' uudelleen\n", kone)
		cmd := exec.Command("ssh", fmt.Sprintf("root@%v", kone), "reboot")
		err := cmd.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Koneen '%v' uudelleenkäynnistys epäonnistui: %v\n", kone, err)
		}
	}
}

func modifyConfig() {
	fmt.Println("TODO: Ei toteutettu")
}

func buildMachines(arguments []string) {
	fmt.Println("TODO: Ei toteutettu")
}

func filterBootable(machineNames []string) []string {
	specs := koti.Filter(allMachineSpecs, func(machine machineSpec) bool {
		return machine.boot
	})
	if len(machineNames) != 0 {
		specs = koti.Filter(specs, func(machine machineSpec) bool {
			for _, machineName := range machineNames {
				if machine.name == machineName {
					return true
				}
			}
			return false
		})
	}
	return koti.Map(specs, getMachineName)
}

func filterReachable(machineNames []string) []string {
	result := []string{}
	for _, machineName := range machineNames {
		cmd := exec.Command("ping", "-W1", "-c1", machineName)
		err := cmd.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Kone '%v' ei vastaa\n", machineName)
			continue
		}
		result = append(result, machineName)
	}
	return result
}

func getMachineName(machine machineSpec) string {
	return machine.name
}
