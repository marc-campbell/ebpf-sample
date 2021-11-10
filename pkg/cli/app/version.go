package app

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/marc-campbell/ebpf-sample/pkg/version"
)

func Version() *cobra.Command {
	cmd := &cobra.Command{
		Use:           "version",
		Short:         "app version information",
		Long:          `Prints the current version of the App CLI. This may or may not match the version in the cluster.`,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Printf("App %s\n", version.Version())
			return nil
		},
	}

	return cmd
}
