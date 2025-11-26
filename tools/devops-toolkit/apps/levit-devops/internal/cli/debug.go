package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewDebugCommand(cfg *config.Config) *cobra.Command {
	debugCmd := &cobra.Command{
		Use:   "debug",
		Short: "디버깅 명령어",
		Long:  "파드 접속, 네트워크 테스트 등 디버깅 도구",
	}

	// pod 서브커맨드
	podCmd := &cobra.Command{
		Use:   "pod [pod-name] [namespace]",
		Short: "파드에 접속",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			podName := args[0]
			namespace := "default"
			if len(args) > 1 {
				namespace = args[1]
			}

			fmt.Printf("파드 '%s'에 접속 중...\n", podName)
			
			execCmd := exec.Command(cfg.Tools.Kubectl, "exec", "-it", podName, "-n", namespace, "--", "/bin/bash")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			
			// bash가 없으면 sh 시도
			if err := execCmd.Run(); err != nil {
				execCmd = exec.Command(cfg.Tools.Kubectl, "exec", "-it", podName, "-n", namespace, "--", "/bin/sh")
				execCmd.Stdout = os.Stdout
				execCmd.Stderr = os.Stderr
				execCmd.Stdin = os.Stdin
				execCmd.Run()
			}
		},
	}

	// network 서브커맨드
	networkCmd := &cobra.Command{
		Use:   "network [service-name] [namespace]",
		Short: "네트워크 연결 테스트",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			serviceName := args[0]
			namespace := "default"
			if len(args) > 1 {
				namespace = args[1]
			}

			fmt.Printf("서비스 '%s' 네트워크 테스트 중...\n", serviceName)
			
			// 임시 파드로 네트워크 테스트
			execCmd := exec.Command(cfg.Tools.Kubectl, "run", "network-test", 
				"--image=busybox", "--rm", "-it", "--restart=Never", 
				"--", "nslookup", serviceName+"."+namespace+".svc.cluster.local")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	// describe 서브커맨드
	describeCmd := &cobra.Command{
		Use:   "describe [resource-type] [resource-name] [namespace]",
		Short: "리소스 상세 정보 조회",
		Args:  cobra.RangeArgs(2, 3),
		Run: func(cmd *cobra.Command, args []string) {
			resourceType := args[0]
			resourceName := args[1]
			
			var execCmd *exec.Cmd
			if len(args) > 2 {
				namespace := args[2]
				execCmd = exec.Command(cfg.Tools.Kubectl, "describe", resourceType, resourceName, "-n", namespace)
			} else {
				execCmd = exec.Command(cfg.Tools.Kubectl, "describe", resourceType, resourceName)
			}
			
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	debugCmd.AddCommand(podCmd, networkCmd, describeCmd)
	return debugCmd
}