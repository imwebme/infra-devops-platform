package config

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Clusters    []Cluster    `yaml:"clusters"`
	AWSProfiles []AWSProfile `yaml:"aws_profiles"`
	Tools       Tools        `yaml:"tools"`
}

type Cluster struct {
	Name        string `yaml:"name"`
	Context     string `yaml:"context"`
	Environment string `yaml:"environment"`
}

type AWSProfile struct {
	Name    string `yaml:"name"`
	Profile string `yaml:"profile"`
}

type Tools struct {
	K9s     string `yaml:"k9s"`
	Kubectl string `yaml:"kubectl"`
	AWS     string `yaml:"aws"`
	ArgoCD  string `yaml:"argocd"`
	Helm    string `yaml:"helm"`
	Gonzo   string `yaml:"gonzo"`
}

func Load() (*Config, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	configPath := filepath.Join(homeDir, ".levit-devops", "config.yaml")
	
	// 기본 설정 생성
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return createDefaultConfig(configPath)
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	// 도구 유효성 검사 (누락된 도구가 있을 때만 경고)
	if err := validateTools(&config); err != nil {
		fmt.Printf("⚠️  도구 검증 경고: %v\n", err)
	}

	return &config, nil
}

func createDefaultConfig(configPath string) (*Config, error) {
	config := &Config{
		Clusters: []Cluster{
			{Name: "alwayz-dev-eks", Context: "alwayz-dev-eks", Environment: "dev"},
			{Name: "alwayz-prod-eks", Context: "alwayz-prod-eks", Environment: "prod"},
			{Name: "data-dev-eks", Context: "data-dev-eks", Environment: "dev"},
			{Name: "data-prod-eks", Context: "data-prod-eks", Environment: "prod"},
		},
		AWSProfiles: []AWSProfile{
			{Name: "alwayz-dev", Profile: "alwayz-dev"},
			{Name: "alwayz-prod", Profile: "alwayz-prod"},
		},
		Tools: Tools{
			K9s:     "k9s",
			Kubectl: "kubectl",
			AWS:     "aws",
			ArgoCD:  "argocd",
			Helm:    "helm",
			Gonzo:   "gonzo",
		},
	}

	// 도구 유효성 검사 (누락된 도구가 있을 때만 경고)
	if err := validateTools(config); err != nil {
		fmt.Printf("⚠️  도구 검증 경고: %v\n", err)
	}

	// 디렉터리 생성
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		return nil, err
	}

	// 설정 파일 저장
	data, err := yaml.Marshal(config)
	if err != nil {
		return nil, err
	}

	if err := os.WriteFile(configPath, data, 0644); err != nil {
		return nil, err
	}

	return config, nil
}

// validateToolInPath validates if a tool exists in PATH and is executable
func validateToolInPath(tool string) error {
	path, err := exec.LookPath(tool)
	if err != nil {
		return fmt.Errorf("%s not found in PATH: %v", tool, err)
	}
	if info, err := os.Stat(path); err != nil || info.Mode()&0111 == 0 {
		return fmt.Errorf("%s exists but is not executable", tool)
	}
	return nil
}

// validateTools validates all configured tools
func validateTools(config *Config) error {
	tools := []string{
		config.Tools.K9s,
		config.Tools.Kubectl,
		config.Tools.AWS,
		config.Tools.ArgoCD,
		config.Tools.Helm,
		config.Tools.Gonzo,
	}
	
	var missingTools []string
	for _, tool := range tools {
		if tool != "" && validateToolInPath(tool) != nil {
			missingTools = append(missingTools, tool)
		}
	}
	
	if len(missingTools) > 0 {
		return fmt.Errorf("누락된 도구: %v. 'levit-devops install tools'로 설치하세요", missingTools)
	}
	
	return nil
}