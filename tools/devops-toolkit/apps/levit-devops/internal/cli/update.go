package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

type GitHubRelease struct {
	TagName string `json:"tag_name"`
	Name    string `json:"name"`
}

func NewUpdateCommand(cfg *config.Config) *cobra.Command {
	updateCmd := &cobra.Command{
		Use:   "update",
		Short: "도구 버전 확인 및 업데이트",
		Long:  "설치된 도구들의 현재 버전과 최신 버전을 확인하고 업데이트",
	}

	// check 서브커맨드
	checkCmd := &cobra.Command{
		Use:   "check",
		Short: "현재 버전과 최신 버전 확인",
		Run: func(cmd *cobra.Command, args []string) {
			checkVersions()
		},
	}

	// tools 서브커맨드
	toolsCmd := &cobra.Command{
		Use:   "tools [tool-name]",
		Short: "도구 업데이트",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				updateAllTools()
			} else {
				updateTool(args[0])
			}
		},
	}

	updateCmd.AddCommand(checkCmd, toolsCmd)
	return updateCmd
}

func checkVersions() {
	fmt.Println("=== 도구 버전 확인 ===\n")
	
	tools := map[string]string{
		"kubectl": "kubernetes/kubernetes",
		"k9s":     "derailed/k9s", 
		"helm":    "helm/helm",
		"argocd":  "argoproj/argo-cd",
		"aws":     "", // AWS CLI는 별도 처리
	}

	for tool, repo := range tools {
		fmt.Printf("📦 %s:\n", tool)
		
		// 현재 설치된 버전
		currentVersion := getCurrentVersion(tool)
		if currentVersion == "" {
			fmt.Printf("  ❌ 설치되지 않음\n")
		} else {
			fmt.Printf("  현재: %s\n", currentVersion)
		}
		
		// 최신 버전
		if repo != "" {
			latestVersion := getLatestVersion(repo)
			if latestVersion != "" {
				fmt.Printf("  최신: %s\n", latestVersion)
				
				if currentVersion != "" && currentVersion != latestVersion {
					fmt.Printf("  🔄 업데이트 가능\n")
				} else if currentVersion == latestVersion {
					fmt.Printf("  ✅ 최신 버전\n")
				}
			}
		}
		fmt.Println()
	}
}

func getCurrentVersion(tool string) string {
	var cmd *exec.Cmd
	
	// 명령어 존재 여부 확인
	if _, err := exec.LookPath(tool); err != nil {
		return ""
	}
	
	switch tool {
	case "kubectl":
		cmd = exec.Command("kubectl", "version", "--client", "--short")
	case "k9s":
		cmd = exec.Command("k9s", "version", "--short")
	case "helm":
		cmd = exec.Command("helm", "version", "--short")
	case "argocd":
		cmd = exec.Command("argocd", "version", "--client", "--short")
	case "aws":
		cmd = exec.Command("aws", "--version")
	default:
		return ""
	}
	
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	
	version := strings.TrimSpace(string(output))
	
	// 버전 정보에서 실제 버전 번호만 추출
	if strings.Contains(version, "v") {
		parts := strings.Fields(version)
		for _, part := range parts {
			if strings.HasPrefix(part, "v") {
				return part
			}
		}
	}
	
	return version
}

func getLatestVersion(repo string) string {
	url := fmt.Sprintf("https://api.github.com/repos/%s/releases/latest", repo)
	
	resp, err := http.Get(url)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return ""
	}
	
	var release GitHubRelease
	if err := json.Unmarshal(body, &release); err != nil {
		return ""
	}
	
	return release.TagName
}

func updateAllTools() {
	tools := []string{"kubectl", "k9s", "helm", "argocd", "aws", "popeye", "krr"}
	
	fmt.Println("모든 도구를 업데이트합니다...\n")
	
	for _, tool := range tools {
		updateTool(tool)
	}
}

func updateTool(tool string) {
	fmt.Printf("🔄 %s 업데이트 중...\n", tool)
	
	var cmd *exec.Cmd
	switch tool {
	case "kubectl":
		cmd = exec.Command("brew", "upgrade", "kubectl")
	case "k9s":
		cmd = exec.Command("brew", "upgrade", "k9s")
	case "helm":
		cmd = exec.Command("brew", "upgrade", "helm")
	case "argocd":
		cmd = exec.Command("brew", "upgrade", "argocd")
	case "aws":
		cmd = exec.Command("brew", "upgrade", "awscli")
	case "popeye":
		cmd = exec.Command("brew", "upgrade", "popeye")
	case "krr":
		fmt.Println("KRR 업데이트 중...")
		installKRR()
		return
	default:
		fmt.Printf("❌ 지원하지 않는 도구: %s\n", tool)
		return
	}
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		if strings.Contains(string(output), "already installed") {
			fmt.Printf("✅ %s는 이미 최신 버전입니다\n", tool)
		} else {
			fmt.Printf("❌ %s 업데이트 실패: %v\n", tool, err)
		}
	} else {
		fmt.Printf("✅ %s 업데이트 완료\n", tool)
	}
	fmt.Println()
}