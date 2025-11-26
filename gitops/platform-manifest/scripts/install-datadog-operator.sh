#!/bin/bash

# Check if API key is provided
if [ -z "$DD_API_KEY" ]; then
    echo "Error: DD_API_KEY environment variable is not set"
    echo "Usage: DD_API_KEY=your-api-key ./install-datadog.sh"
    exit 1
fi

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context)

# Show warning and ask for confirmation
echo "Warning: You are using kubernetes context: $CURRENT_CONTEXT"
echo "Do you want to proceed with this context? (y/n)"
read -r answer

# Convert answer to lowercase
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

if [ "$answer" != "y" ] && [ "$answer" != "yes" ]; then
    echo "Installation cancelled"
    echo "You can switch context using: kubectl config use-context <context-name>"
    echo "Available contexts:"
    kubectl config get-contexts
    exit 1
fi

echo "Proceeding with installation..."

# Add datadog helm repository
helm repo add datadog https://helm.datadoghq.com

# Install/upgrade datadog operator
helm upgrade --install -n datadog datadog-operator datadog/datadog-operator

# Create secret with API key
kubectl create secret generic datadog-secret --from-literal api-key=$DD_API_KEY 