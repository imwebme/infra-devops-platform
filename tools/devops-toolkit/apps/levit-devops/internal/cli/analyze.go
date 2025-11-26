package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewAnalyzeCommand(cfg *config.Config) *cobra.Command {
	analyzeCmd := &cobra.Command{
		Use:   "analyze",
		Short: "클러스터 분석 도구",
		Long:  "Popeye, KRR 등을 사용한 클러스터 리소스 분석",
	}

	// 도구 버전 확인 함수
	checkToolVersion := func(tool, minVersion string) error {
		cmd := exec.Command(tool, "version")
		if tool == "krr" {
			cmd = exec.Command(tool, "version")
		}
		output, err := cmd.Output()
		if err != nil {
			return fmt.Errorf("%s가 설치되지 않음", tool)
		}
		// 간단한 버전 체크 (실제 버전 파싱은 복잡하므로 설치 여부만 확인)
		if len(output) == 0 {
			return fmt.Errorf("%s 버전 정보를 가져올 수 없음", tool)
		}
		return nil
	}

	// popeye 서브커맨드
	popeyeCmd := &cobra.Command{
		Use:   "popeye [namespace]",
		Short: "Popeye로 클러스터 상태 분석",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			// Popeye 버전 확인
			if err := checkToolVersion("popeye", "0.10.0"); err != nil {
				fmt.Printf("Popeye 버전 확인 실패: %v\n", err)
				fmt.Println("최소 버전 0.10.0 이상이 필요합니다")
				fmt.Println("설치: levit-devops install tools popeye")
				return
			}
			
			var execCmd *exec.Cmd
			if len(args) > 0 {
				execCmd = exec.Command("popeye", "-n", args[0])
			} else {
				execCmd = exec.Command("popeye")
			}
			
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("Popeye 실행 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools popeye")
			}
		},
	}

	// krr 서브커맨드
	krrCmd := &cobra.Command{
		Use:   "krr [namespace]",
		Short: "KRR로 리소스 사용량 분석",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			// KRR 버전 확인
			if err := checkToolVersion("krr", "1.0.0"); err != nil {
				fmt.Printf("KRR 버전 확인 실패: %v\n", err)
				fmt.Println("최소 버전 1.0.0 이상이 필요합니다")
				fmt.Println("설치: levit-devops install tools krr")
				return
			}
			
			var execCmd *exec.Cmd
			if len(args) > 0 {
				execCmd = exec.Command("krr", "simple", "-n", args[0])
			} else {
				execCmd = exec.Command("krr", "simple")
			}
			
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("KRR 실행 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools krr")
			}
		},
	}

	// security 서브커맨드
	securityCmd := &cobra.Command{
		Use:   "security",
		Short: "보안 분석 (Popeye 보안 체크)",
		Run: func(cmd *cobra.Command, args []string) {
			// Popeye 버전 확인
			if err := checkToolVersion("popeye", "0.10.0"); err != nil {
				fmt.Printf("Popeye 버전 확인 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools popeye")
				return
			}
			
			fmt.Println("🔒 클러스터 보안 분석 중...")
			fmt.Println("🔍 검사 항목: 보안, RBAC, 시크릿, 네트워크 정책")
			
			execCmd := exec.Command("popeye", 
				"--sections", "security,rbac,secrets,networkpolicies",
				"--output-options", "score,sanitize",
				"--save-report", "/tmp/security-report.json")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("보안 분석 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools popeye")
			} else {
				fmt.Println("\n✅ 보안 분석 완료!")
				fmt.Println("📊 상세 리포트: /tmp/security-report.json")
			}
		},
	}

	// resources 서브커맨드
	resourcesCmd := &cobra.Command{
		Use:   "resources",
		Short: "리소스 사용량 분석 (KRR)",
		Run: func(cmd *cobra.Command, args []string) {
			// KRR 버전 확인
			if err := checkToolVersion("krr", "1.0.0"); err != nil {
				fmt.Printf("KRR 버전 확인 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools krr")
				return
			}
			
			fmt.Println("📊 리소스 사용량 분석 중...")
			
			execCmd := exec.Command("krr", "simple", "--format", "table")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			
			if err := execCmd.Run(); err != nil {
				fmt.Printf("리소스 분석 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools krr")
			}
		},
	}

	analyzeCmd.AddCommand(popeyeCmd, krrCmd, securityCmd, resourcesCmd)
	return analyzeCmd
}