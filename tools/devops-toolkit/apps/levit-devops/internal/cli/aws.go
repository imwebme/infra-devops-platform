package cli

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewAWSCommand(cfg *config.Config) *cobra.Command {
	awsCmd := &cobra.Command{
		Use:   "aws",
		Short: "AWS 관리 명령어",
		Long:  "AWS CLI를 래핑한 명령어",
	}

	// profile 서브커맨드
	profileCmd := &cobra.Command{
		Use:   "profile [profile-name]",
		Short: "AWS 프로파일 관리",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				// 프로파일 목록 표시
				execCmd := exec.Command(cfg.Tools.AWS, "configure", "list-profiles")
				execCmd.Stdout = os.Stdout
				execCmd.Stderr = os.Stderr
				execCmd.Run()
				return
			}

			// 프로파일 설정
			profileName := args[0]
			profile := findAWSProfile(cfg, profileName)
			if profile == nil {
				fmt.Printf("프로파일 '%s'를 찾을 수 없습니다\n", profileName)
				return
			}

			os.Setenv("AWS_PROFILE", profile.Profile)
			fmt.Printf("AWS 프로파일이 '%s'로 설정되었습니다\n", profile.Profile)
		},
	}

	// ec2 서브커맨드
	ec2Cmd := &cobra.Command{
		Use:   "ec2",
		Short: "EC2 인스턴스 조회",
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.AWS, "ec2", "describe-instances",
				"--query", "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key=='Name'].Value|[0]]",
				"--output", "table")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	// rds 서브커맨드
	rdsCmd := &cobra.Command{
		Use:   "rds",
		Short: "RDS 인스턴스 조회",
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.AWS, "rds", "describe-db-instances",
				"--query", "DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]",
				"--output", "table")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	// s3 서브커맨드
	s3Cmd := &cobra.Command{
		Use:   "s3",
		Short: "S3 버킷 조회",
		Run: func(cmd *cobra.Command, args []string) {
			execCmd := exec.Command(cfg.Tools.AWS, "s3", "ls")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}

	awsCmd.AddCommand(profileCmd, ec2Cmd, rdsCmd, s3Cmd)
	return awsCmd
}

func findAWSProfile(cfg *config.Config, name string) *config.AWSProfile {
	for _, profile := range cfg.AWSProfiles {
		if profile.Name == name {
			return &profile
		}
	}
	return nil
}