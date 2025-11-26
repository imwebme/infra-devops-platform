package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewGonzoCommand(cfg *config.Config) *cobra.Command {
	gonzoCmd := &cobra.Command{
		Use:   "gonzo",
		Short: "실시간 로그 분석 터미널 UI",
		Long:  "Gonzo를 사용하여 로그 스트림을 분석하고 시각화합니다",
		Run: func(cmd *cobra.Command, args []string) {
			runGonzoCommand(args)
		},
	}

	// Gonzo 서브커맨드들
	gonzoCmd.AddCommand(
		newGonzoVersionCommand(),
		newGonzoLogsCommand(),
		newGonzoFollowCommand(),
	)

	return gonzoCmd
}

func newGonzoVersionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Gonzo 버전 정보 출력",
		Run: func(cmd *cobra.Command, args []string) {
			runGonzoCommand(append([]string{"version"}, args...))
		},
	}
}

func newGonzoLogsCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "logs [flags]",
		Short: "로그 파일 분석",
		Long:  "로그 파일을 읽어서 실시간으로 분석합니다. 예: levit-devops gonzo logs -f /var/log/app.log",
		Run: func(cmd *cobra.Command, args []string) {
			runGonzoCommand(args)
		},
	}
}

func newGonzoFollowCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "follow [file]",
		Short: "로그 파일 실시간 추적",
		Long:  "tail -f처럼 로그 파일을 실시간으로 추적합니다",
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) > 0 {
				runGonzoCommand([]string{"-f", args[0], "--follow"})
			} else {
				fmt.Println("로그 파일 경로를 지정해주세요")
			}
		},
	}
}

func runGonzoCommand(args []string) {
	if _, err := exec.LookPath("gonzo"); err != nil {
		fmt.Println("Error: 'gonzo' not found in PATH. Please install it first:")
		fmt.Println("  levit-devops install tools gonzo")
		os.Exit(1)
	}
	
	cmd := exec.Command("gonzo", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("Error running gonzo command: %v\n", err)
		os.Exit(1)
	}
}