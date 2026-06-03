#!/usr/bin/env pwsh

param(
  [string]$DatadogApiKey,
  [string]$DatadogAppKey,
  [string]$DatadogSite = "datadoghq.com",
  [string]$ClusterName = "productapi-aks"
)

if (-not $DatadogApiKey) {
  Write-Error "DatadogApiKey is required. Pass it using -DatadogApiKey <key>"
  exit 1
}

Write-Host "Installing Datadog Agent on AKS cluster $ClusterName..."

# Add the Datadog Helm repository
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Install the Datadog Agent
helm install datadog datadog/datadog `
  --set datadog.apiKey=$DatadogApiKey `
  --set datadog.appKey=$DatadogAppKey `
  --set datadog.site=$DatadogSite `
  --set datadog.logs.enabled=true `
  --set datadog.logs.containerCollectAll=true `
  --set datadog.apm.portEnabled=true `
  --set datadog.kubelet.tlsVerify=false `
  --set clusterAgent.enabled=true `
  --set clusterAgent.metricsProvider.enabled=true

Write-Host "Datadog Agent installed successfully."
