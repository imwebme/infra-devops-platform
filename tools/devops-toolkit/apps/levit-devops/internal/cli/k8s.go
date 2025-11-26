package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewK8sCommand(cfg *config.Config) *cobra.Command {
	k8sCmd := &cobra.Command{
		Use:   "k8s",
		Short: "Kubernetes 관리 명령어",
		Long:  "kubectl, k9s 등 Kubernetes 도구를 래핑한 명령어",
	}

	// context 서브커맨드
	contextCmd := &cobra.Command{
		Use:   "context [cluster-name]",
		Short: "Kubernetes 컨텍스트 관리",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				// 현재 컨텍스트 목록 표시
				execCmd := exec.Command(cfg.Tools.Kubectl, "config", "get-contexts")
				execCmd.Stdout = os.Stdout
				execCmd.Stderr = os.Stderr
				if err := execCmd.Run(); err != nil {
					fmt.Printf("kubectl이 설치되지 않았거나 경로가 잘못되었습니다: %v\n", err)
				}
				return
			}

			// 컨텍스트 변경
			clusterName := args[0]
			cluster := findCluster(cfg, clusterName)
			if cluster == nil {
				fmt.Printf("클러스터 '%s'를 찾을 수 없습니다\n", clusterName)
				return
			}

			execCmd := exec.Command(cfg.Tools.Kubectl, "config", "use-context", cluster.Context)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				fmt.Printf("컨텍스트 변경 실패: %v\n", err)
			}
		},
	}

	// view 서브커맨드 (k9s 실행)
	viewCmd := &cobra.Command{
		Use:   "view [cluster-name]",
		Short: "k9s로 클러스터 보기",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var context string
			if len(args) > 0 {
				cluster := findCluster(cfg, args[0])
				if cluster == nil {
					fmt.Printf("클러스터 '%s'를 찾을 수 없습니다\n", args[0])
					return
				}
				context = cluster.Context
			}

			// k9s 실행
			fmt.Println("🚀 k9s를 실행합니다...")
			if context != "" {
				fmt.Printf("컨텍스트: %s\n", context)
			}
			
			var execCmd *exec.Cmd
			if context != "" {
				execCmd = exec.Command("k9s", "--context", context)
			} else {
				execCmd = exec.Command("k9s")
			}
			
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			if err := execCmd.Run(); err != nil {
				fmt.Printf("k9s 실행 실패: %v\n", err)
				fmt.Println("설치: levit-devops install tools k9s")
			}
		},
	}

	// nodes 서브커맨드
	nodesCmd := &cobra.Command{
		Use:   "nodes",
		Short: "노드 목록 조회",
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.Kubectl, "get", "nodes", "-o", "wide")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				fmt.Printf("노드 조회 실패: %v\n", err)
			}
		},
	}

	// pods 서브커맨드
	podsCmd := &cobra.Command{
		Use:   "pods [namespace]",
		Short: "파드 목록 조회",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			var execCmd *exec.Cmd
			if len(args) > 0 {
				execCmd = exec.Command(cfg.Tools.Kubectl, "get", "pods", "-n", args[0], "-o", "wide")
			} else {
				execCmd = exec.Command(cfg.Tools.Kubectl, "get", "pods", "--all-namespaces", "-o", "wide")
			}
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				fmt.Printf("파드 조회 실패: %v\n", err)
			}
		},
	}

	k8sCmd.AddCommand(contextCmd, viewCmd, nodesCmd, podsCmd)
	return k8sCmd
}

func findCluster(cfg *config.Config, name string) *config.Cluster {
	for _, cluster := range cfg.Clusters {
		if cluster.Name == name {
			return &cluster
		}
	}
	return nil
}