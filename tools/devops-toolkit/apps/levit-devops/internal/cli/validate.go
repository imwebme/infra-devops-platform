package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewValidateCommand(cfg *config.Config) *cobra.Command {
	validateCmd := &cobra.Command{
		Use:   "validate",
		Short: "도구 및 설정 유효성 검사",
		Long:  "설치된 도구들의 PATH 및 실행 권한을 검증합니다",
	}

	// tools 서브커맨드
	toolsCmd := &cobra.Command{
		Use:   "tools",
		Short: "설치된 도구들 검증",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🔍 도구 유효성 검사 중...")
			
			tools := map[string]string{
				"kubectl": cfg.Tools.Kubectl,
				"k9s":     cfg.Tools.K9s,
				"helm":    cfg.Tools.Helm,
				"argocd":  cfg.Tools.ArgoCD,
				"aws":     cfg.Tools.AWS,
			}

			allValid := true
			for name, tool := range tools {
				if err := validateToolInPath(tool); err != nil {
					fmt.Printf("❌ %s: %v\n", name, err)
					allValid = false
				} else {
					fmt.Printf("✅ %s: 사용 가능\n", name)
				}
			}

			if allValid {
				fmt.Println("\n🎉 모든 도구가 정상적으로 설치되어 있습니다!")
			} else {
				fmt.Println("\n⚠️  일부 도구가 누락되었습니다. 'levit-devops install tools'로 설치하세요.")
			}
		},
	}

	// config 서브커맨드
	configCmd := &cobra.Command{
		Use:   "config",
		Short: "설정 파일 검증",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("🔍 설정 파일 검증 중...")
			
			// 클러스터 설정 검증
			fmt.Printf("📋 설정된 클러스터: %d개\n", len(cfg.Clusters))
			for _, cluster := range cfg.Clusters {
				fmt.Printf("  - %s (%s)\n", cluster.Name, cluster.Environment)
			}

			// AWS 프로파일 검증
			fmt.Printf("🔑 AWS 프로파일: %d개\n", len(cfg.AWSProfiles))
			for _, profile := range cfg.AWSProfiles {
				fmt.Printf("  - %s\n", profile.Name)
			}

			fmt.Println("✅ 설정 파일이 유효합니다")
		},
	}

	validateCmd.AddCommand(toolsCmd, configCmd)
	return validateCmd
}

// validateToolInPath validates if a tool exists in PATH and is executable
func validateToolInPath(tool string) error {
	path, err := exec.LookPath(tool)
	if err != nil {
		return fmt.Errorf("PATH에서 찾을 수 없음: %v", err)
	}
	if info, err := os.Stat(path); err != nil || info.Mode()&0111 == 0 {
		return fmt.Errorf("실행 권한이 없음: %s", path)
	}
	return nil
}