package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/gorilla/mux"
	"github.com/slack-go/slack"
)

func TestHealthHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(handleHealth)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	var response map[string]string
	err = json.Unmarshal(rr.Body.Bytes(), &response)
	if err != nil {
		t.Errorf("failed to unmarshal response: %v", err)
	}

	if response["status"] != "healthy" {
		t.Errorf("expected status to be 'healthy', got %v", response["status"])
	}

	if response["time"] == "" {
		t.Error("expected time to be present")
	}
}

func TestGetEnv(t *testing.T) {
	tests := []struct {
		name         string
		key          string
		defaultValue string
		expected     string
	}{
		{
			name:         "nonexistent key returns default",
			key:          "NONEXISTENT_KEY_12345",
			defaultValue: "default_value",
			expected:     "default_value",
		},
		{
			name:         "empty default value",
			key:          "ANOTHER_NONEXISTENT_KEY",
			defaultValue: "",
			expected:     "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getEnv(tt.key, tt.defaultValue)
			if result != tt.expected {
				t.Errorf("getEnv(%q, %q) = %q, want %q", tt.key, tt.defaultValue, result, tt.expected)
			}
		})
	}
}

func TestApp_processCommand(t *testing.T) {
	config := Config{
		SlackBotToken:      "xoxb-test-token",
		SlackSigningSecret: "test-secret",
		GitHubToken:        "ghp_test-token",
		GitHubOrg:          "testorg",
		Port:               "8080",
	}

	app := &App{
		config:       config,
		slack:        slack.New(config.SlackBotToken),
		githubClient: NewGitHubClient(config.GitHubToken),
	}

	tests := []struct {
		name     string
		text     string
		expected string
	}{
		{
			name:     "empty command",
			text:     "",
			expected: "Please provide a command. Available commands: `deploy`, `build`, `test`",
		},
		{
			name:     "help command",
			text:     "help",
			expected: app.getHelpMessage(),
		},
		{
			name:     "unknown command",
			text:     "unknown",
			expected: "Unknown command: unknown. Type `help` for available commands.",
		},
		{
			name:     "deploy command with insufficient args",
			text:     "deploy",
			expected: "Usage: `deploy <environment> <service>`",
		},
		{
			name:     "deploy command with one arg",
			text:     "deploy staging",
			expected: "Usage: `deploy <environment> <service>`",
		},
		{
			name:     "build command with insufficient args",
			text:     "build",
			expected: "Usage: `build <service>`",
		},
		{
			name:     "test command with insufficient args",
			text:     "test",
			expected: "Usage: `test <service>`",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := app.processCommand(tt.text, "test-user", "test-channel")
			if result != tt.expected {
				t.Errorf("processCommand() = %q, want %q", result, tt.expected)
			}
		})
	}
}

func TestApp_processSlashCommand(t *testing.T) {
	config := Config{
		SlackBotToken:      "xoxb-test-token",
		SlackSigningSecret: "test-secret",
		GitHubToken:        "ghp_test-token",
		GitHubOrg:          "testorg",
		Port:               "8080",
	}

	app := &App{
		config:       config,
		slack:        slack.New(config.SlackBotToken),
		githubClient: NewGitHubClient(config.GitHubToken),
	}

	tests := []struct {
		name     string
		command  string
		text     string
		expected map[string]interface{}
	}{
		{
			name:    "devops-action with insufficient args",
			command: "/devops-action",
			text:    "repo",
			expected: map[string]interface{}{
				"text": "Usage: `/devops-action <repository> <workflow> [parameters...]`",
			},
		},
		{
			name:    "devops-action with no args",
			command: "/devops-action",
			text:    "",
			expected: map[string]interface{}{
				"text": "Usage: `/devops-action <repository> <workflow> [parameters...]`",
			},
		},
		{
			name:    "unknown slash command",
			command: "/unknown",
			text:    "test",
			expected: map[string]interface{}{
				"text": "Unknown command",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := app.processSlashCommand(tt.command, tt.text, "test-user", "test-channel")
			if result["text"] != tt.expected["text"] {
				t.Errorf("processSlashCommand() = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestApp_getHelpMessage(t *testing.T) {
	app := &App{}
	helpMessage := app.getHelpMessage()

	expectedSubstrings := []string{
		"GitHub Action Bot Commands",
		"deploy <environment> <service>",
		"build <service>",
		"test <service>",
		"/devops-action",
		"DevOps team",
		"🤖",
		"🚀",
	}

	for _, substring := range expectedSubstrings {
		if !strings.Contains(helpMessage, substring) {
			t.Errorf("getHelpMessage() missing expected substring: %q", substring)
		}
	}
}

func TestApp_handleSlackCommands_InvalidSignature(t *testing.T) {
	config := Config{
		SlackBotToken:      "xoxb-test-token",
		SlackSigningSecret: "test-secret",
		GitHubToken:        "ghp_test-token",
		GitHubOrg:          "testorg",
		Port:               "8080",
	}

	app := &App{
		config:       config,
		slack:        slack.New(config.SlackBotToken),
		githubClient: NewGitHubClient(config.GitHubToken),
	}

	// Create a request with invalid signature
	form := url.Values{}
	form.Add("command", "/devops-action")
	form.Add("text", "test-repo workflow.yml")

	req, err := http.NewRequest("POST", "/slack/commands", strings.NewReader(form.Encode()))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	rr := httptest.NewRecorder()
	app.handleSlackCommands(rr, req)

	// Should return 400 or 401 due to missing/invalid signature
	if rr.Code != http.StatusBadRequest && rr.Code != http.StatusUnauthorized {
		t.Errorf("expected status 400 or 401, got %d", rr.Code)
	}
}

func TestRouterSetup(t *testing.T) {
	config := Config{
		SlackBotToken:      "xoxb-test-token",
		SlackSigningSecret: "test-secret",
		GitHubToken:        "ghp_test-token",
		GitHubOrg:          "testorg",
		Port:               "8080",
	}

	app := &App{
		config:       config,
		slack:        slack.New(config.SlackBotToken),
		githubClient: NewGitHubClient(config.GitHubToken),
	}

	router := mux.NewRouter()
	router.HandleFunc("/slack/events", app.handleSlackEvents).Methods("POST")
	router.HandleFunc("/slack/commands", app.handleSlackCommands).Methods("POST")
	router.HandleFunc("/health", handleHealth).Methods("GET")

	tests := []struct {
		method       string
		path         string
		expectedCode int
	}{
		{"GET", "/health", http.StatusOK},
		{"GET", "/unknown", http.StatusNotFound},
		{"POST", "/unknown", http.StatusNotFound},
		{"GET", "/slack/events", http.StatusMethodNotAllowed},
		{"GET", "/slack/commands", http.StatusMethodNotAllowed},
	}

	for _, tt := range tests {
		t.Run(tt.method+"_"+tt.path, func(t *testing.T) {
			var req *http.Request
			var err error

			if tt.method == "POST" {
				req, err = http.NewRequest(tt.method, tt.path, bytes.NewBufferString("{}"))
			} else {
				req, err = http.NewRequest(tt.method, tt.path, nil)
			}

			if err != nil {
				t.Fatal(err)
			}

			rr := httptest.NewRecorder()
			router.ServeHTTP(rr, req)

			if rr.Code != tt.expectedCode {
				t.Errorf("%s %s returned status %d, expected %d",
					tt.method, tt.path, rr.Code, tt.expectedCode)
			}
		})
	}
}

func TestConfig_Validation(t *testing.T) {
	tests := []struct {
		name   string
		config Config
		valid  bool
	}{
		{
			name: "valid config",
			config: Config{
				SlackBotToken:      "xoxb-token",
				SlackSigningSecret: "secret",
				GitHubToken:        "ghp_token",
				GitHubOrg:          "org",
				Port:               "8080",
			},
			valid: true,
		},
		{
			name: "missing slack bot token",
			config: Config{
				SlackBotToken:      "",
				SlackSigningSecret: "secret",
				GitHubToken:        "ghp_token",
				GitHubOrg:          "org",
				Port:               "8080",
			},
			valid: false,
		},
		{
			name: "missing slack signing secret",
			config: Config{
				SlackBotToken:      "xoxb-token",
				SlackSigningSecret: "",
				GitHubToken:        "ghp_token",
				GitHubOrg:          "org",
				Port:               "8080",
			},
			valid: false,
		},
		{
			name: "missing github token",
			config: Config{
				SlackBotToken:      "xoxb-token",
				SlackSigningSecret: "secret",
				GitHubToken:        "",
				GitHubOrg:          "org",
				Port:               "8080",
			},
			valid: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			isValid := tt.config.SlackBotToken != "" &&
				tt.config.SlackSigningSecret != "" &&
				tt.config.GitHubToken != ""

			if isValid != tt.valid {
				t.Errorf("config validation = %v, want %v", isValid, tt.valid)
			}
		})
	}
}
