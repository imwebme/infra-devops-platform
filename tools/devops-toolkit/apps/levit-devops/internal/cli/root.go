package cli

import (
	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewRootCommand(cfg *config.Config) *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "levit-devops",
		Short: "DevOps 팀을 위한 통합 CLI 도구",
		Long:  "Kubernetes, AWS, GitOps 등 DevOps 도구들을 통합 관리하는 CLI",
		Run: func(cmd *cobra.Command, args []string) {
			printBanner()
			cmd.Help()
		},
	}

	// 서브 커맨드 추가
	rootCmd.AddCommand(
		NewListCommand(cfg),
		NewInstallCommand(cfg),
		NewUpdateCommand(cfg),
		NewValidateCommand(cfg),
		NewAnalyzeCommand(cfg),
		NewSecurityCommand(cfg),
		NewK8sCommand(cfg),
		NewAWSCommand(cfg),
		NewGitOpsCommand(cfg),
		NewArgoCDCommand(cfg),
		NewGonzoCommand(cfg),
		NewLogsCommand(cfg),
		NewTunnelCommand(cfg),
		NewDebugCommand(cfg),
	)

	return rootCmd
}