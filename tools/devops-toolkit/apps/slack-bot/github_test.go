package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestNewGitHubClient(t *testing.T) {
	token := "test-token"
	client := NewGitHubClient(token)

	if client.token != token {
		t.Errorf("expected token %q, got %q", token, client.token)
	}

	if client.baseURL != "https://api.github.com" {
		t.Errorf("expected baseURL %q, got %q", "https://api.github.com", client.baseURL)
	}

	if client.client.Timeout != 30*time.Second {
		t.Errorf("expected timeout %v, got %v", 30*time.Second, client.client.Timeout)
	}
}

func TestGitHubClient_TriggerWorkflow_Success(t *testing.T) {
	// Mock GitHub API server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Errorf("expected POST request, got %s", r.Method)
		}

		expectedPath := "/repos/testorg/testrepo/actions/workflows/test.yml/dispatches"
		if r.URL.Path != expectedPath {
			t.Errorf("expected path %s, got %s", expectedPath, r.URL.Path)
		}

		// Check headers
		if r.Header.Get("Authorization") != "Bearer test-token" {
			t.Errorf("expected Authorization header 'Bearer test-token', got %s", r.Header.Get("Authorization"))
		}

		if r.Header.Get("Accept") != "application/vnd.github.v3+json" {
			t.Errorf("expected Accept header 'application/vnd.github.v3+json', got %s", r.Header.Get("Accept"))
		}

		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	client := &GitHubClient{
		token:   "test-token",
		baseURL: server.URL,
		client:  &http.Client{Timeout: 30 * time.Second},
	}

	inputs := map[string]interface{}{
		"environment": "staging",
		"service":     "test-service",
	}

	err := client.TriggerWorkflow("testorg", "testrepo", "test.yml", "main", inputs)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
}

func TestGitHubClient_TriggerWorkflow_Error(t *testing.T) {
	// Mock GitHub API server that returns error
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"message": "Bad credentials", "documentation_url": "https://docs.github.com"}`))
	}))
	defer server.Close()

	client := &GitHubClient{
		token:   "invalid-token",
		baseURL: server.URL,
		client:  &http.Client{Timeout: 30 * time.Second},
	}

	err := client.TriggerWorkflow("testorg", "testrepo", "test.yml", "main", map[string]interface{}{})
	if err == nil {
		t.Error("expected error, got nil")
	}

	expectedErrorMsg := "workflow dispatch failed: Bad credentials"
	if err.Error() != expectedErrorMsg {
		t.Errorf("expected error message %q, got %q", expectedErrorMsg, err.Error())
	}
}

func TestGitHubClient_ListWorkflows_Success(t *testing.T) {
	// Mock GitHub API server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			t.Errorf("expected GET request, got %s", r.Method)
		}

		expectedPath := "/repos/testorg/testrepo/actions/workflows"
		if r.URL.Path != expectedPath {
			t.Errorf("expected path %s, got %s", expectedPath, r.URL.Path)
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{
			"total_count": 2,
			"workflows": [
				{
					"id": 161335,
					"name": "CI",
					"path": ".github/workflows/ci.yml",
					"state": "active",
					"badge_url": "https://github.com/testorg/testrepo/workflows/CI/badge.svg"
				},
				{
					"id": 161336,
					"name": "Deploy",
					"path": ".github/workflows/deploy.yml",
					"state": "active",
					"badge_url": "https://github.com/testorg/testrepo/workflows/Deploy/badge.svg"
				}
			]
		}`))
	}))
	defer server.Close()

	client := &GitHubClient{
		token:   "test-token",
		baseURL: server.URL,
		client:  &http.Client{Timeout: 30 * time.Second},
	}

	workflows, err := client.ListWorkflows("testorg", "testrepo")
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}

	if len(workflows) != 2 {
		t.Errorf("expected 2 workflows, got %d", len(workflows))
	}

	if workflows[0].Name != "CI" {
		t.Errorf("expected first workflow name 'CI', got %s", workflows[0].Name)
	}

	if workflows[1].Name != "Deploy" {
		t.Errorf("expected second workflow name 'Deploy', got %s", workflows[1].Name)
	}
}

func TestGitHubClient_ListWorkflows_Error(t *testing.T) {
	// Mock GitHub API server that returns error
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer server.Close()

	client := &GitHubClient{
		token:   "test-token",
		baseURL: server.URL,
		client:  &http.Client{Timeout: 30 * time.Second},
	}

	workflows, err := client.ListWorkflows("testorg", "nonexistent")
	if err == nil {
		t.Error("expected error, got nil")
	}

	if workflows != nil {
		t.Errorf("expected nil workflows, got %v", workflows)
	}
}
