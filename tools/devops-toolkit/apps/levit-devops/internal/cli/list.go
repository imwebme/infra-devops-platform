package cli

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewListCommand(cfg *config.Config) *cobra.Command {
	listCmd := &cobra.Command{
		Use:   "list",
		Short: "전체 리소스 목록 조회",
		Long:  "클러스터, 앱, 서비스 등 전체 리소스를 한번에 조회",
	}

	// clusters 서브커맨드
	clustersCmd := &cobra.Command{
		Use:   "clusters [filter]",
		Short: "사용 가능한 클러스터 목록",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("=== 설정된 클러스터 목록 ===")
			filter := ""
			if len(args) > 0 {
				filter = strings.ToLower(args[0])
			}

			for _, cluster := range cfg.Clusters {
				if filter == "" || strings.Contains(strings.ToLower(cluster.Name), filter) {
					fmt.Printf("- %s (%s) [%s]\n", cluster.Name, cluster.Context, cluster.Environment)
				}
			}

			fmt.Println("\n=== kubectl 컨텍스트 목록 ===")
			execCmd := exec.Command(cfg.Tools.Kubectl, "config", "get-contexts")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	// all 서브커맨드
	allCmd := &cobra.Command{
		Use:   "all [filter]",
		Short: "모든 리소스 요약 조회",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			filter := ""
			if len(args) > 0 {
				filter = args[0]
			}

			fmt.Println("=== DevOps 리소스 요약 ===")
			
			// 현재 컨텍스트
			fmt.Println("\n[현재 Kubernetes 컨텍스트]")
			execCmd := exec.Command(cfg.Tools.Kubectl, "config", "current-context")
			execCmd.Stdout = os.Stdout
			execCmd.Run()

			// 노드 상태
			fmt.Println("\n[노드 상태]")
			execCmd = exec.Command(cfg.Tools.Kubectl, "get", "nodes", "--no-headers")
			execCmd.Stdout = os.Stdout
			execCmd.Run()

			// 네임스페이스별 파드 수
			fmt.Println("\n[네임스페이스별 파드 수]")
			execCmd = exec.Command(cfg.Tools.Kubectl, "get", "pods", "--all-namespaces", "--no-headers")
			output, err := execCmd.Output()
			if err == nil {
				lines := strings.Split(string(output), "\n")
				nsCount := make(map[string]int)
				for _, line := range lines {
					if line != "" {
						parts := strings.Fields(line)
						if len(parts) > 0 {
							nsCount[parts[0]]++
						}
					}
				}
				for ns, count := range nsCount {
					if filter == "" || strings.Contains(ns, filter) {
						fmt.Printf("  %s: %d pods\n", ns, count)
					}
				}
			}

			// ArgoCD 앱 (설치되어 있는 경우)
			fmt.Println("\n[ArgoCD 애플리케이션]")
			
			// argocd 명령어 경로 확인
			argoCmdPath := cfg.Tools.ArgoCD
			if _, err := exec.LookPath("argocd"); err == nil {
				argoCmdPath = "argocd"
			}
			
			execCmd = exec.Command(argoCmdPath, "app", "list", "-o", "name")
			output, err = execCmd.Output()
			if err == nil {
				apps := strings.Split(strings.TrimSpace(string(output)), "\n")
				count := 0
				for _, app := range apps {
					if app != "" && (filter == "" || strings.Contains(app, filter)) {
						if count < 10 { // 처음 10개만 표시
							fmt.Printf("  - %s\n", app)
						}
						count++
					}
				}
				if count > 10 {
					fmt.Printf("  ... 총 %d개 앱 (처음 10개만 표시)\n", count)
				} else if count == 0 {
					fmt.Println("  애플리케이션이 없거나 ArgoCD에 로그인되지 않음")
				}
			} else {
				// 에러 메시지에서 로그인 문제인지 확인
				errorMsg := string(err.(*exec.ExitError).Stderr)
				if strings.Contains(errorMsg, "oauth2") || strings.Contains(errorMsg, "invalid_request") {
					fmt.Println("  ArgoCD CLI는 설치되어 있지만 로그인이 필요합니다")
					fmt.Println("  로그인: argocd login <server>")
				} else {
					fmt.Println("  ArgoCD CLI가 설치되지 않음")
					fmt.Println("  설치: levit-devops install tools argocd")
				}
			}
		},
	}

	listCmd.AddCommand(clustersCmd, allCmd)
	return listCmd
}