package main

import (
	"flag"
	"fmt"
	"github.com/jhakonen/koti/utils"
	"os"
	"os/exec"
	"slices"
	"strings"
)

var configDir = "/home/jhakonen/nixos-config"

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
		subcommands := []string{"switch", "boot", "test", "build", "repl", "info", "rollback"}
		var debug bool
		var subcommand string
		// Komentorivikäsittely
		fs := flag.NewFlagSet("rakenna", flag.ExitOnError)
		fs.StringVar(&subcommand, "t", "switch", fmt.Sprintf("Rebuild komennot: %s", strings.Join(subcommands, ", ")))
		fs.BoolVar(&debug, "debug", false, "Lisää --show-trace komentoon")
		fs.Parse(os.Args[2:])
		// Varmista että alikomento on oikein
		if !slices.Contains(subcommands, subcommand) {
			fmt.Printf("Tuntematon alikomento: %s\n", subcommand)
			os.Exit(1)
		}
		// Rakenna
		os.Exit(buildMachines(subcommand, fs.Args(), debug))
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

	hostname, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Hostnamen pyyntö epäonnistui: %v\n", err)
		return 1
	}

	knownMachines, err := utils.ReadKnownMachines(configDir)
	if err != nil {
		fmt.Printf("Koneiden määrittelyn lukeminen epäonnistui: %s\n", err)
		return 1
	}

	knownMachineNames := utils.Map(knownMachines, func (machine utils.Machine) string {
		return machine.Name
	})

	// Ensure that all provided machine names are known hosts
	for _, name := range arguments {
		if !slices.Contains(knownMachineNames, name) {
			fmt.Printf("Tuntematon kone: %s\n", name)
			return 1
		}
	}

	machineNames := arguments

	// Boot all machines by default if no machine names were given
	if len(machineNames) == 0 {
		machineNames = knownMachineNames
	}

	// All but current host is bootable
	machineNames = utils.Filter(machineNames, func(name string) bool {
		return name != hostname
	})

	machineNames = filterReachable(machineNames)
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
	cmd := exec.Command("subl", "--project", fmt.Sprintf("%s/nixos-config.sublime-project", configDir))
	err := cmd.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Tekstieditorin käynnistys epäonnistui: %v\n", err)
		return 1
	}
	return 0
}

func buildMachines(command string, arguments []string, debug bool) int {
	result := 0
	hostname, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Hostnamen pyyntö epäonnistui: %v\n", err)
		return 1
	}

	knownMachines, err := utils.ReadKnownMachines(configDir)
	if err != nil {
		fmt.Printf("Koneiden määrittelyn lukeminen epäonnistui: %s\n", err)
		return 1
	}

	knownMachineNames := utils.Map(knownMachines, func (machine utils.Machine) string {
		return machine.Name
	})

	// Ensure that all provided machine names are known hosts
	for _, name := range arguments {
		if !slices.Contains(knownMachineNames, name) {
			fmt.Printf("Tuntematon kone: %s\n", name)
			return 1
		}
	}

	machineNames := arguments

	// Build all machines by default if no hostnames were given
	if len(machineNames) == 0 {
		machineNames = knownMachineNames
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
		index := slices.IndexFunc(knownMachines, func (machine utils.Machine) bool {
			return machine.Name == machineName
		})
		entrypoint := knownMachines[index].Entry
		isRemote := machineName != hostname
		err := buildMachine(command, machineName, entrypoint, isRemote, debug)
		if err != nil {
			return 1
		}
	}
	return result
}

// ============================================================================
//      Util functions
// ============================================================================

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

func buildMachine(command string, machineName string, entrypoint string, isRemote bool, debug bool) error {
	configFile := configDir
	if entrypoint != "default" {
		configFile = fmt.Sprintf("%s/%s.nix", configDir, entrypoint)
	}
	args := []string{
		"systemd-inhibit",
		"--who", fmt.Sprintf("nixos-rebuild %s", machineName),
		"--why", fmt.Sprintf("Rakennetaan %s konetta", machineName),
		"nh", "os", command,
		"--file", configFile,
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

	if debug {
		args = append(args, "--", "--show-trace")
	}

	// Print out the command that's going to be executed so that we can run it
	// manually if necessary
	fmt.Printf("%v\n", strings.Join(utils.Map(args, func(arg string) string {
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
