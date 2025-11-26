package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewGitOpsCommand(cfg *config.Config) *cobra.Command {
	gitopsCmd := &cobra.Command{
		Use:   "gitops",
		Short: "GitOps 관리 명령어",
		Long:  "ArgoCD, Helm 등 GitOps 도구 명령어",
	}

	// argocd 서브커맨드
	argocdCmd := &cobra.Command{
		Use:   "argocd",
		Short: "ArgoCD 관리",
	}

	// argocd apps
	appsCmd := &cobra.Command{
		Use:   "apps [filter]",
		Short: "ArgoCD 애플리케이션 목록",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var execCmd *exec.Cmd
			if len(args) > 0 {
				// 필터링된 목록
				execCmd = exec.Command(cfg.Tools.ArgoCD, "app", "list", "-o", "name")
			} else {
				// 전체 목록
				execCmd = exec.Command(cfg.Tools.ArgoCD, "app", "list")
			}
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				fmt.Printf("ArgoCD 연결 실패: %v\n", err)
				fmt.Println("ArgoCD CLI가 설치되어 있고 로그인되어 있는지 확인하세요")
				fmt.Println("  brew install argocd")
				fmt.Println("  argocd login <server>")
			}
		},
	}

	// argocd sync
	syncCmd := &cobra.Command{
		Use:   "sync [app-name]",
		Short: "ArgoCD 애플리케이션 동기화",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.ArgoCD, "app", "sync", args[0])
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	// argocd status
	statusCmd := &cobra.Command{
		Use:   "status [app-name]",
		Short: "ArgoCD 애플리케이션 상태",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.ArgoCD, "app", "get", args[0])
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	argocdCmd.AddCommand(appsCmd, syncCmd, statusCmd)

	// helm 서브커맨드
	helmCmd := &cobra.Command{
		Use:   "helm",
		Short: "Helm 관리",
	}

	// helm list
	listCmd := &cobra.Command{
		Use:   "list [namespace]",
		Short: "Helm 릴리스 목록",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var execCmd *exec.Cmd
			if len(args) > 0 {
				// 특정 네임스페이스
				execCmd = exec.Command(cfg.Tools.Helm, "list", "-n", args[0])
			} else {
				// 전체 네임스페이스
				execCmd = exec.Command(cfg.Tools.Helm, "list", "--all-namespaces")
			}
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				fmt.Printf("Helm 명령 실패: %v\n", err)
				fmt.Println("Helm이 설치되어 있는지 확인하세요: brew install helm")
			}
		},
	}

	// helm template
	templateCmd := &cobra.Command{
		Use:   "template [chart-path]",
		Short: "Helm 템플릿 검증",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.Helm, "template", args[0])
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	helmCmd.AddCommand(listCmd, templateCmd)
	gitopsCmd.AddCommand(argocdCmd, helmCmd)
	return gitopsCmd
}