package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/slack-go/slack"
	"github.com/slack-go/slack/slackevents"
)

type Config struct {
	SlackBotToken          string
	SlackSigningSecret     string
	SlackClientID          string
	SlackClientSecret      string
	SlackVerificationToken string
	GitHubToken            string
	GitHubOrg              string
	Port                   string
}

type App struct {
	config       Config
	slack        *slack.Client
	githubClient *GitHubClient
}

func main() {
	config := Config{
		SlackBotToken:          getEnv("SLACK_BOT_TOKEN", ""),
		SlackSigningSecret:     getEnv("SLACK_SIGNING_SECRET", ""),
		SlackClientID:          getEnv("SLACK_CLIENT_ID", ""),
		SlackClientSecret:      getEnv("SLACK_CLIENT_SECRET", ""),
		SlackVerificationToken: getEnv("SLACK_VERIFICATION_TOKEN", ""),
		GitHubToken:            getEnv("GITHUB_TOKEN", ""),
		GitHubOrg:              getEnv("GITHUB_ORG", "wetripod"),
		Port:                   getEnv("PORT", "8080"),
	}

	// Validate required environment variables
	var missingVars []string

	if config.SlackBotToken == "" {
		missingVars = append(missingVars, "SLACK_BOT_TOKEN")
	}

	if config.SlackSigningSecret == "" && config.SlackVerificationToken == "" {
		missingVars = append(missingVars, "SLACK_SIGNING_SECRET or SLACK_VERIFICATION_TOKEN")
	}

	if config.GitHubToken == "" {
		missingVars = append(missingVars, "GITHUB_TOKEN")
	}

	if len(missingVars) > 0 {
		log.Fatalf("Required environment variables are missing: %v", missingVars)
	}

	// Log configuration (without sensitive data)
	log.Printf("Starting with config:")
	log.Printf("- Port: %s", config.Port)
	log.Printf("- GitHub Org: %s", config.GitHubOrg)
	log.Printf("- GitHub Token: %s...%s", config.GitHubToken[:10], config.GitHubToken[len(config.GitHubToken)-4:])
	log.Printf("- Slack Bot Token: %s...%s", config.SlackBotToken[:10], config.SlackBotToken[len(config.SlackBotToken)-4:])
	if config.SlackSigningSecret != "" {
		log.Printf("- Using Slack Signing Secret (recommended)")
	} else if config.SlackVerificationToken != "" {
		log.Printf("- Using Slack Verification Token (legacy)")
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

	srv := &http.Server{
		Addr:         ":" + config.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s", config.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Printf("Received shutdown signal. Shutting down server on port %s...", config.Port)

	// Create a deadline for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Disable keep-alives to speed up shutdown
	srv.SetKeepAlivesEnabled(false)

	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
		os.Exit(1)
	}

	log.Printf("Server on port %s exited gracefully", config.Port)
}

func (a *App) handleSlackEvents(w http.ResponseWriter, r *http.Request) {
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error reading request body: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	body, err := slackevents.ParseEvent(json.RawMessage(bodyBytes), slackevents.OptionVerifyToken(&slackevents.TokenComparator{VerificationToken: a.config.SlackSigningSecret}))
	if err != nil {
		log.Printf("Error parsing event: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	switch body.Type {
	case slackevents.URLVerification:
		var r *slackevents.ChallengeResponse
		err := json.Unmarshal(bodyBytes, &r)
		if err != nil {
			log.Printf("Error unmarshaling challenge: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "text")
		w.Write([]byte(r.Challenge))
	case slackevents.CallbackEvent:
		innerEvent := body.InnerEvent
		switch ev := innerEvent.Data.(type) {
		case *slackevents.AppMentionEvent:
			a.handleAppMention(ev)
		}
	}
}

func (a *App) handleSlackCommands(w http.ResponseWriter, r *http.Request) {
	// Skip verification in development mode
	skipVerification := getEnv("SKIP_SLACK_VERIFICATION", "false") == "true"

	if !skipVerification {
		// Read body first for verification
		bodyBytes, err := io.ReadAll(r.Body)
		if err != nil {
			log.Printf("Error reading request body: %v", err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		// Replace the body for further processing
		r.Body = io.NopCloser(bytes.NewReader(bodyBytes))

		// Try signing secret first (recommended method)
		if a.config.SlackSigningSecret != "" {
			verifier, err := slack.NewSecretsVerifier(r.Header, a.config.SlackSigningSecret)
			if err != nil {
				log.Printf("Error creating verifier: %v", err)
				w.WriteHeader(http.StatusBadRequest)
				return
			}

			// Verify the request
			if _, err := verifier.Write(bodyBytes); err != nil {
				log.Printf("Error writing to verifier: %v", err)
				w.WriteHeader(http.StatusUnauthorized)
				return
			}

			if err := verifier.Ensure(); err != nil {
				log.Printf("Request signature verification failed: %v", err)
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
		} else if a.config.SlackVerificationToken != "" {
			// Fallback to verification token (legacy method)
			r.ParseForm()
			token := r.FormValue("token")
			if token != a.config.SlackVerificationToken {
				log.Printf("Verification token mismatch")
				w.WriteHeader(http.StatusUnauthorized)
				return
			}
		}

		// Reset body for further processing
		r.Body = io.NopCloser(bytes.NewReader(bodyBytes))
	}

	r.Body = http.MaxBytesReader(w, r.Body, 1024*1024)
	if err := r.ParseForm(); err != nil {
		log.Printf("Error parsing form: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	command := r.PostForm.Get("command")
	text := r.PostForm.Get("text")
	userID := r.PostForm.Get("user_id")
	channelID := r.PostForm.Get("channel_id")

	response := a.processSlashCommand(command, text, userID, channelID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (a *App) handleAppMention(event *slackevents.AppMentionEvent) {
	text := strings.TrimSpace(strings.Replace(event.Text, fmt.Sprintf("<@%s>", event.BotID), "", 1))
	response := a.processCommand(text, event.User, event.Channel)

	if response != "" {
		_, _, err := a.slack.PostMessage(event.Channel, slack.MsgOptionText(response, false))
		if err != nil {
			log.Printf("Error posting message: %v", err)
		}
	}
}

func (a *App) processSlashCommand(command, text, userID, channelID string) map[string]interface{} {
	switch command {
	case "/devops-action":
		return a.handleGitHubActionCommand(text, userID, channelID)
	default:
		return map[string]interface{}{
			"text": "Unknown command",
		}
	}
}

func (a *App) processCommand(text, userID, channelID string) string {
	parts := strings.Fields(text)
	if len(parts) == 0 {
		return "Please provide a command. Available commands: `deploy`, `build`, `test`"
	}

	command := parts[0]
	args := parts[1:]

	switch command {
	case "deploy":
		return a.handleDeployCommand(args, userID, channelID)
	case "build":
		return a.handleBuildCommand(args, userID, channelID)
	case "test":
		return a.handleTestCommand(args, userID, channelID)
	case "help":
		return a.getHelpMessage()
	default:
		return fmt.Sprintf("Unknown command: %s. Type `help` for available commands.", command)
	}
}

func (a *App) handleGitHubActionCommand(text, userID, channelID string) map[string]interface{} {
	parts := strings.Fields(text)
	if len(parts) < 2 {
		return map[string]interface{}{
			"text": "Usage: `/devops-action <repository> <workflow> [parameters...]`",
		}
	}

	repo := parts[0]
	workflow := parts[1]

	inputs := make(map[string]interface{})
	for i := 2; i < len(parts); i += 2 {
		if i+1 < len(parts) {
			inputs[parts[i]] = parts[i+1]
		}
	}

	err := a.githubClient.TriggerWorkflow(a.config.GitHubOrg, repo, workflow, "main", inputs)
	if err != nil {
		log.Printf("Error triggering GitHub action: %v", err)
		return map[string]interface{}{
			"text": fmt.Sprintf("Failed to trigger GitHub Action: %v", err),
		}
	}

	return map[string]interface{}{
		"text": fmt.Sprintf("✅ GitHub Action `%s` triggered for repository `%s`", workflow, repo),
	}
}

func (a *App) handleDeployCommand(args []string, userID, channelID string) string {
	if len(args) < 2 {
		return "Usage: `deploy <environment> <service>`"
	}

	environment := args[0]
	service := args[1]

	inputs := map[string]interface{}{
		"environment": environment,
		"service":     service,
	}

	err := a.githubClient.TriggerWorkflow(a.config.GitHubOrg, service, "deploy.yml", "main", inputs)
	if err != nil {
		log.Printf("Error triggering deploy: %v", err)
		return fmt.Sprintf("❌ Failed to trigger deployment: %v", err)
	}

	return fmt.Sprintf("🚀 Deployment of `%s` to `%s` environment has been triggered!", service, environment)
}

func (a *App) handleBuildCommand(args []string, userID, channelID string) string {
	if len(args) < 1 {
		return "Usage: `build <service>`"
	}

	service := args[0]

	inputs := map[string]interface{}{
		"service": service,
	}

	err := a.githubClient.TriggerWorkflow(a.config.GitHubOrg, service, "build.yml", "main", inputs)
	if err != nil {
		log.Printf("Error triggering build: %v", err)
		return fmt.Sprintf("❌ Failed to trigger build: %v", err)
	}

	return fmt.Sprintf("🔨 Build for `%s` has been triggered!", service)
}

func (a *App) handleTestCommand(args []string, userID, channelID string) string {
	if len(args) < 1 {
		return "Usage: `test <service>`"
	}

	service := args[0]

	inputs := map[string]interface{}{
		"service": service,
	}

	err := a.githubClient.TriggerWorkflow(a.config.GitHubOrg, service, "test.yml", "main", inputs)
	if err != nil {
		log.Printf("Error triggering test: %v", err)
		return fmt.Sprintf("❌ Failed to trigger tests: %v", err)
	}

	return fmt.Sprintf("🧪 Tests for `%s` have been triggered!", service)
}

func (a *App) getHelpMessage() string {
	return "🤖 *GitHub Action Bot Commands*\n\n" +
		"*Available Commands:*\n" +
		"• `deploy <environment> <service>` - Deploy a service to an environment\n" +
		"• `build <service>` - Build a service\n" +
		"• `test <service>` - Run tests for a service\n" +
		"• `help` - Show this help message\n\n" +
		"*Slash Commands:*\n" +
		"• `/devops-action <repository> <workflow> [parameters...]` - Trigger a specific GitHub Action\n\n" +
		"*Examples:*\n" +
		"• `@bot deploy staging user-service`\n" +
		"• `@bot build payment-service`\n" +
		"• `@bot test notification-service`\n" +
		"• `/devops-action user-service deploy.yml environment staging`\n\n" +
		"*Need help?* Contact the DevOps team! 🚀"
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "healthy",
		"time":   time.Now().UTC().Format(time.RFC3339),
	})
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
