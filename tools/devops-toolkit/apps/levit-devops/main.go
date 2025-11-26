package main

import (
	"fmt"
	"os"

	"levit-devops/internal/cli"
	"levit-devops/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fmt.Printf("Error loading config: %v\n", err)
		os.Exit(1)
	}

	rootCmd := cli.NewRootCommand(cfg)
	if err := rootCmd.Execute(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
}