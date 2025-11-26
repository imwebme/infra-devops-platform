package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
	"levit-devops/internal/config"
)

func NewInstallCommand(cfg *config.Config) *cobra.Command {
	installCmd := &cobra.Command{
		Use:   "install",
		Short: "CLI 도구 설치 및 설정",
		Long:  "levit-devops 및 관련 도구들을 자동 설치",
	}

	// self 서브커맨드 (levit-devops 자체 설치)
	selfCmd := &cobra.Command{
		Use:   "self",
		Short: "levit-devops를 시스템에 설치",
		Run: func(cmd *cobra.Command, args []string) {
			installSelf()
		},
	}

	// tools 서브커맨드
	toolsCmd := &cobra.Command{
		Use:   "tools [tool-name] [version]",
		Short: "필수 도구들 자동 설치",
		Args:  cobra.MaximumNArgs(2),
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				installAllTools()
			} else {
				version := "latest"
				if len(args) > 1 {
					version = args[1]
				}
				installTool(args[0], version)
			}
		},
	}

	installCmd.AddCommand(selfCmd, toolsCmd)
	return installCmd
}

func installSelf() {
	fmt.Println("levit-devops 설치 중...")
	
	// 현재 실행 파일 경로
	execPath, err := os.Executable()
	if err != nil {
		fmt.Printf("실행 파일 경로를 찾을 수 없습니다: %v\n", err)
		return
	}

	// /usr/local/bin에 복사 시도
	targetPath := "/usr/local/bin/levit-devops"
	if err := copyFile(execPath, targetPath); err != nil {
		fmt.Printf("/usr/local/bin 설치 실패, ~/.local/bin에 설치합니다\n")
		
		// ~/.local/bin 디렉터리 생성
		homeDir, _ := os.UserHomeDir()
		localBinDir := filepath.Join(homeDir, ".local", "bin")
		os.MkdirAll(localBinDir, 0755)
		
		targetPath = filepath.Join(localBinDir, "levit-devops")
		if err := copyFile(execPath, targetPath); err != nil {
			fmt.Printf("설치 실패: %v\n", err)
			return
		}
		
		// PATH에 추가
		addToPath(localBinDir)
	}

	fmt.Printf("✅ levit-devops가 %s에 설치되었습니다\n", targetPath)
}

func installAllTools() {
	tools := []string{"kubectl", "k9s", "helm", "argocd", "aws", "popeye", "krr", "gonzo"}
	
	fmt.Println("필수 도구들을 설치합니다...")
	for _, tool := range tools {
		installTool(tool, "latest")
	}
	
	// Amazon Q 안내
	fmt.Println("\n📝 Amazon Q IDE 플러그인 설치 안내:")
	installTool("amazonq", "latest")
}

func installTool(tool, version string) {
	fmt.Printf("📦 %s 설치 중...\n", tool)
	
	// 보안 경고
	if version == "latest" {
		fmt.Println("⚠️  보안 주의: latest 버전 사용 시 공급망 공격 위험이 있습니다.")
	}
	
	// 이미 설치되어 있는지 확인
	if _, err := exec.LookPath(tool); err == nil && version == "latest" {
		fmt.Printf("✅ %s가 이미 설치되어 있습니다\n", tool)
		return
	}

	var cmd *exec.Cmd
	switch tool {
	case "kubectl":
		cmd = exec.Command("brew", "install", "kubectl")
	case "k9s":
		cmd = exec.Command("brew", "install", "k9s")
	case "helm":
		cmd = exec.Command("brew", "install", "helm")
	case "argocd":
		cmd = exec.Command("brew", "install", "argocd")
	case "aws":
		cmd = exec.Command("brew", "install", "awscli")
	case "popeye":
		cmd = exec.Command("brew", "install", "popeye")
	case "krr":
		// KRR은 GitHub에서 직접 설치
		fmt.Println("KRR 설치 중... (GitHub Release에서 다운로드)")
		installKRR()
		return
	case "gonzo":
		cmd = exec.Command("brew", "install", "gonzo")
	case "amazonq":
		fmt.Println("Amazon Q는 IDE 플러그인으로 설치하세요:")
		fmt.Println("  VS Code: https://marketplace.visualstudio.com/items?itemName=AmazonWebServices.amazon-q-vscode")
		fmt.Println("  IntelliJ: https://plugins.jetbrains.com/plugin/24267-amazon-q")
		return
	default:
		fmt.Printf("❌ 지원하지 않는 도구: %s\n", tool)
		return
	}

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	if err := cmd.Run(); err != nil {
		fmt.Printf("❌ %s 설치 실패: %v\n", tool, err)
		fmt.Printf("수동 설치: brew install %s\n", tool)
	} else {
		fmt.Printf("✅ %s 설치 완료\n", tool)
	}
}

func copyFile(src, dst string) error {
	input, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	
	err = os.WriteFile(dst, input, 0755)
	if err != nil {
		return err
	}
	
	return nil
}

func addToPath(dir string) {
	homeDir, _ := os.UserHomeDir()
	
	// macOS 기본 zsh 사용
	shellPath := filepath.Join(homeDir, ".zshrc")
	pathLine := fmt.Sprintf("\n# levit-devops PATH\nexport PATH=\"$PATH:%s\"\n", dir)
	
	file, err := os.OpenFile(shellPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		file.WriteString(pathLine)
		file.Close()
		fmt.Printf("✅ .zshrc에 PATH가 추가되었습니다\n")
		fmt.Println("새 터미널을 열거나 'source ~/.zshrc'를 실행하세요")
	} else {
		fmt.Printf("⚠️  PATH 추가 실패: %v\n", err)
	}
}

func installKRR() {
	fmt.Println("🐍 Python pip로 KRR 설치 시도 중...")
	
	pipCmd := exec.Command("pip3", "install", "robusta-krr")
	if err := pipCmd.Run(); err != nil {
		fmt.Println("🍺 Homebrew로 KRR 설치 시도 중...")
		
		brewCmd := exec.Command("brew", "install", "robusta-dev/homebrew-krr/krr")
		if err := brewCmd.Run(); err != nil {
			fmt.Printf("❌ KRR 설치 실패: %v\n", err)
			fmt.Println("📝 수동 설치:")
			fmt.Println("  pip3 install robusta-krr")
			fmt.Println("  또는")
			fmt.Println("  brew tap robusta-dev/homebrew-krr")
			fmt.Println("  brew install krr")
			return
		}
	}
	
	fmt.Println("✅ KRR 설치 완료")
}