package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type GitHubClient struct {
	token   string
	baseURL string
	client  *http.Client
}

type WorkflowDispatchPayload struct {
	Ref    string                 `json:"ref"`
	Inputs map[string]interface{} `json:"inputs"`
}

type GitHubError struct {
	Message          string `json:"message"`
	DocumentationURL string `json:"documentation_url"`
}

func NewGitHubClient(token string) *GitHubClient {
	return &GitHubClient{
		token:   token,
		baseURL: "https://api.github.com",
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (gc *GitHubClient) TriggerWorkflow(org, repo, workflowID string, ref string, inputs map[string]interface{}) error {
	url := fmt.Sprintf("%s/repos/%s/%s/actions/workflows/%s/dispatches", gc.baseURL, org, repo, workflowID)

	payload := WorkflowDispatchPayload{
		Ref:    ref,
		Inputs: inputs,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+gc.token)
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "wetripod-slack-bot/1.0")

	resp, err := gc.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		var githubErr GitHubError
		if err := json.NewDecoder(resp.Body).Decode(&githubErr); err != nil {
			return fmt.Errorf("workflow dispatch failed with status %d", resp.StatusCode)
		}
		return fmt.Errorf("workflow dispatch failed: %s", githubErr.Message)
	}

	return nil
}

func (gc *GitHubClient) ListWorkflows(org, repo string) ([]Workflow, error) {
	url := fmt.Sprintf("%s/repos/%s/%s/actions/workflows", gc.baseURL, org, repo)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+gc.token)
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("User-Agent", "wetripod-slack-bot/1.0")

	resp, err := gc.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to list workflows: status %d", resp.StatusCode)
	}

	var workflowsResp WorkflowsResponse
	if err := json.NewDecoder(resp.Body).Decode(&workflowsResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return workflowsResp.Workflows, nil
}

type Workflow struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Path     string `json:"path"`
	State    string `json:"state"`
	BadgeURL string `json:"badge_url"`
}

type WorkflowsResponse struct {
	TotalCount int        `json:"total_count"`
	Workflows  []Workflow `json:"workflows"`
}
