package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewTunnelCommand(cfg *config.Config) *cobra.Command {
	tunnelCmd := &cobra.Command{
		Use:   "tunnel",
		Short: "터널링 명령어",
		Long:  "데이터베이스 및 서비스 포트 포워딩",
	}

	// db 서브커맨드
	dbCmd := &cobra.Command{
		Use:   "db [db-name]",
		Short: "데이터베이스 터널링",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			dbName := args[0]
			
			// 일반적인 DB 포트 매핑
			var localPort, remotePort string
			switch {
			case contains(dbName, "mysql") || contains(dbName, "aurora"):
				localPort = "3306"
				remotePort = "3306"
			case contains(dbName, "postgres") || contains(dbName, "rds"):
				localPort = "5432"
				remotePort = "5432"
			case contains(dbName, "mongo"):
				localPort = "27017"
				remotePort = "27017"
			case contains(dbName, "redis"):
				localPort = "6379"
				remotePort = "6379"
			default:
				localPort = "3306"
				remotePort = "3306"
			}

			fmt.Printf("데이터베이스 터널링 시작: %s (로컬 포트: %s)\n", dbName, localPort)
			
			execCmd := exec.Command(cfg.Tools.Kubectl, "port-forward", 
				"service/"+dbName, localPort+":"+remotePort)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			execCmd.Run()
		},
	}

	// service 서브커맨드
	serviceCmd := &cobra.Command{
		Use:   "service [service-name] [local-port:remote-port]",
		Short: "서비스 포트 포워딩",
		Args:  cobra.RangeArgs(1, 2),
		Run: func(cmd *cobra.Command, args []string) {
			serviceName := args[0]
			portMapping := "8080:80"
			if len(args) > 1 {
				portMapping = args[1]
			}

			fmt.Printf("서비스 포트 포워딩 시작: %s (%s)\n", serviceName, portMapping)
			
			execCmd := exec.Command(cfg.Tools.Kubectl, "port-forward", 
				"service/"+serviceName, portMapping)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Stdin = os.Stdin
			execCmd.Run()
		},
	}

	tunnelCmd.AddCommand(dbCmd, serviceCmd)
	return tunnelCmd
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || 
		(len(s) > len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr)))
}