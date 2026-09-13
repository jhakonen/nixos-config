package main

import (
	"fmt"
	"github.com/jhakonen/koti-go/koti"
	"os"
	"os/exec"
	"strings"
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

// ============================================================================
//      Main
// ============================================================================

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Käyttö: koti <komento> [valinnat]")
		fmt.Fprintln(os.Stderr, "Komennot: buuttaa, muokkaa, rakenna")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "buuttaa":
		os.Exit(bootMachines(os.Args[2:]))
	case "muokkaa":
		os.Exit(modifyConfig())
	case "rakenna":
		os.Exit(buildMachines(os.Args[2:]))
	default:
		fmt.Fprintf(os.Stderr, "Tuntematon komento: %v\n", os.Args[1])
		os.Exit(1)
	}
}

// ============================================================================
//      Subcommand handlers
// ============================================================================

func bootMachines(arguments []string) int {
	result := 0
	machineNames := filterReachable(filterBootable(arguments))
	for _, machineName := range machineNames {
		fmt.Printf("Käynnistä kone '%v' uudelleen\n", machineName)
		cmd := exec.Command("ssh", fmt.Sprintf("root@%v", machineName), "reboot")
		err := cmd.Run()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Koneen '%v' uudelleenkäynnistys epäonnistui: %v\n", machineName, err)
			result = 1
		}
	}
	return result
}

func modifyConfig() int {
	cmd := exec.Command("subl", "--project", "~/nixos-config/nixos-config.sublime-project")
	err := cmd.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Tekstieditorin käynnistys epäonnistui: %v\n", err)
		return 1
	}
	return 0
}

func buildMachines(arguments []string) int {
	result := 0
	hostname, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Hostnamen pyyntö epäonnistui: %v\n", err)
		return 1
	}

	machineNames := arguments

	// Build all machines by default if no hostnames were given
	if len(machineNames) == 0 {
		machineNames = koti.Map(allMachineSpecs, getMachineName)
	}

	machineNames = filterReachable(machineNames)

	for _, machineName := range machineNames {
		isRemote := machineName != hostname
		if isRemote {
			continue
		}

		// Ensure that machine's key is at ~/.ssh/known_hosts so that SSH will not
		// prompt to accept connection attempt
		err := removeMachineFromKnownHosts(machineName)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			result = 1
			continue
		}
		err = addMachineToKnownHosts(machineName)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			result = 1
			continue
		}
	}
	for _, machineName := range machineNames {
		isRemote := machineName != hostname
		err := buildMachine(machineName, isRemote)
		if err != nil {
			return 1
		}
	}
	return result
}

// ============================================================================
//      Util functions
// ============================================================================

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

func removeMachineFromKnownHosts(machineName string) error {
	cmd := exec.Command("ssh-keygen", "-R", machineName)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Koneen '%v' poistaminen known_hosts tiedostosta epäonnistui: %v\n", machineName, err)
	}
	return nil
}

func addMachineToKnownHosts(machineName string) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("Kotikansion haku epäonnistui: %v\n", err)
	}

	file, err := os.OpenFile(homeDir+"/.ssh/known_hosts", os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return fmt.Errorf("Tiedoston known_hosts avaaminen epäonnistui: %v\n", err)
	}
	defer file.Close()

	cmd := exec.Command("ssh-keyscan", "-q", machineName)
	cmd.Stdout = file
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("Koneen '%v' lisääminen known_hosts tiedostoon epäonnistui: %v\n", machineName, err)
	}

	return nil
}

func buildMachine(machineName string, isRemote bool) error {
	args := []string{
		"systemd-inhibit",
		"--who", fmt.Sprintf("nixos-rebuild %s", machineName),
		"--why", fmt.Sprintf("Rakennetaan %s konetta", machineName),
		"nh", "os", "switch",
		"--file", "/home/jhakonen/nixos-config",
		fmt.Sprintf("flake.nixosConfigurations.%s", machineName),
	}
	if isRemote {
		args = append(
			args,
			"--hostname", machineName,
			"--target-host", fmt.Sprintf("root@%s", machineName),
			"--elevation-strategy", "none",
			"--ask",
		)
	}

	// Print out the command that's going to be executed so that we can run it
	// manually if necessary
	fmt.Printf("%v\n", strings.Join(koti.Map(args, func(arg string) string {
		if strings.Contains(arg, " ") {
			return fmt.Sprintf("\"%s\"", arg)
		}
		return arg
	}), " "))

	// Execute the rebuild command
	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
