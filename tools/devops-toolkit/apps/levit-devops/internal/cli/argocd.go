package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewArgoCDCommand(cfg *config.Config) *cobra.Command {
	argocdCmd := &cobra.Command{
		Use:   "argocd",
		Short: "ArgoCD 관리 명령어",
		Long:  "ArgoCD 로그인, 앱 관리 등",
	}

	// login 서브커맨드
	loginCmd := &cobra.Command{
		Use:   "login [server]",
		Short: "ArgoCD 서버에 로그인",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			server := "argocd.example.com"  // 기본 서버
			if len(args) > 0 {
				server = args[0]
			}

			fmt.Printf("ArgoCD 서버 '%s'에 로그인 중...\n", server)
			
			execCmd := exec.Command("argocd", "login", server, "--sso")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("로그인 실패: %v\n", err)
				fmt.Println("수동 로그인: argocd login " + server + " --sso")
			} else {
				fmt.Println("✅ ArgoCD 로그인 성공!")
			}
		},
	}

	// context 서브커맨드
	contextCmd := &cobra.Command{
		Use:   "context",
		Short: "현재 ArgoCD 컨텍스트 확인",
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command("argocd", "context")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	argocdCmd.AddCommand(loginCmd, contextCmd)
	return argocdCmd
}