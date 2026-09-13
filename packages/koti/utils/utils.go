package utils

import (
	"encoding/json"
	"fmt"
	"os"
)

func Filter[T any](list []T, fn func(T) bool) []T {
	values := []T{}
	for _, value := range list {
		if fn(value) {
			values = append(values, value)
		}
	}
	return values
}

func Map[T any, E any](list []T, fn func(T) E) []E {
	values := []E{}
	for _, value := range list {
		values = append(values, fn(value))
	}
	return values
}

func ReadKnownMachineNames(configDir string) ([]string, error) {
	contents, err := os.ReadFile(fmt.Sprintf("%s/hosts.json", configDir))
	if err != nil {
		return nil, err
	}
	var hosts []string
	err = json.Unmarshal(contents, &hosts)
	if err != nil {
		return nil, err
	}
	return hosts, nil
}
