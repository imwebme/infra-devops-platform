package cli

import (
	"fmt"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewSecurityCommand(cfg *config.Config) *cobra.Command {
	securityCmd := &cobra.Command{
		Use:   "security",
		Short: "종합 보안 분석 도구",
		Long:  "RBAC, 네트워크 정책, 시크릿 관리 등 포괄적인 보안 검사",
	}

	// rbac 서브커맨드
	rbacCmd := &cobra.Command{
		Use:   "rbac",
		Short: "RBAC 설정 분석",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🔐 RBAC 설정 분석 중...")
			
			execCmd := exec.Command("popeye", "--sections", "rbac")
			execCmd.Stdout = cmd.OutOrStdout()
			execCmd.Stderr = cmd.ErrOrStderr()
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("RBAC 분석 실패: %v\n", err)
			}
		},
	}

	// secrets 서브커맨드
	secretsCmd := &cobra.Command{
		Use:   "secrets",
		Short: "시크릿 관리 분석",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🔑 시크릿 관리 분석 중...")
			
			execCmd := exec.Command("popeye", "--sections", "secrets")
			execCmd.Stdout = cmd.OutOrStdout()
			execCmd.Stderr = cmd.ErrOrStderr()
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("시크릿 분석 실패: %v\n", err)
			}
		},
	}

	// network 서브커맨드
	networkCmd := &cobra.Command{
		Use:   "network",
		Short: "네트워크 정책 분석",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🌐 네트워크 정책 분석 중...")
			
			execCmd := exec.Command("popeye", "--sections", "networkpolicies")
			execCmd.Stdout = cmd.OutOrStdout()
			execCmd.Stderr = cmd.ErrOrStderr()
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("네트워크 정책 분석 실패: %v\n", err)
			}
		},
	}

	securityCmd.AddCommand(rbacCmd, secretsCmd, networkCmd)
	return securityCmd
}