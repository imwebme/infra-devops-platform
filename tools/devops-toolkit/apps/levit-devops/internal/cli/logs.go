package cli

import (
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewLogsCommand(cfg *config.Config) *cobra.Command {
	logsCmd := &cobra.Command{
		Use:   "logs",
		Short: "로그 조회 명령어",
		Long:  "애플리케이션 및 인프라 로그 조회",
	}

	// app 서브커맨드
	appCmd := &cobra.Command{
		Use:   "app [app-name] [namespace]",
		Short: "애플리케이션 로그 조회",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			appName := args[0]
			namespace := "default"
			if len(args) > 1 {
				namespace = args[1]
			}

			var execCmd *exec.Cmd
			execCmd = exec.Command(cfg.Tools.Kubectl, "logs", "-l", "app="+appName, "-n", namespace, "--tail=100", "-f")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			execCmd.Run()
		},
	}

	// pod 서브커맨드
	podCmd := &cobra.Command{
		Use:   "pod [pod-name] [namespace]",
		Short: "특정 파드 로그 조회",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			podName := args[0]
			namespace := "default"
			if len(args) > 1 {
				namespace = args[1]
			}

			execCmd := exec.Command(cfg.Tools.Kubectl, "logs", podName, "-n", namespace, "--tail=100", "-f")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			execCmd.Run()
		},
	}

	// infra 서브커맨드
	infraCmd := &cobra.Command{
		Use:   "infra [component]",
		Short: "인프라 컴포넌트 로그 조회",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			component := args[0]
			var namespace string

			switch component {
			case "argocd":
				namespace = "argocd"
			case "cert-manager":
				namespace = "cert-manager"
			case "ingress-nginx":
				namespace = "ingress-nginx"
			case "monitoring":
				namespace = "monitoring"
			default:
				namespace = "kube-system"
			}

			execCmd := exec.Command(cfg.Tools.Kubectl, "logs", "-l", "app.kubernetes.io/name="+component, "-n", namespace, "--tail=100", "-f")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			execCmd.Run()
		},
	}

	logsCmd.AddCommand(appCmd, podCmd, infraCmd)
	return logsCmd
}