{{/*
Expand the name of the chart.
*/}}
{{- define "base-cronjobs.name" -}}
{{- default .Chart.Name .Values.appName | trunc 60 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified name for cpa comp.
*/}}
{{- define "base-cronjobs.fullname" -}}
{{- if .Values.appName }}
{{- .Values.appName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.appName }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "base-cronjobs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base-cronjobs.labels" -}}
helm.sh/chart: {{ include "base-cronjobs.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "base-cronjobs.env-section" -}}
{{- with .env }}
{{- toYaml . }}
{{- end }}
{{- range .secrets }}
- name: {{ .secretKey | default .vaultKey }}
  valueFrom:
    secretKeyRef:
      name: {{ $.cronJobFullName }}
      key: {{ .secretKey }}
{{- end }}
{{- end }}

{{/*
Datadog deployment labels
*/}}
{{- define "base-cronjobs.datadog.labels" -}}
tags.datadoghq.com/env: {{ .Values.env }}
tags.datadoghq.com/service: {{ include "base-cronjobs.fullname" . }}
{{- end }}

{{/*
Datadog Envs
*/}}
{{- define "base-cronjobs.datadog.envs" -}}
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_LOGS_CONFIG_AUTO_MULTI_LINE_DETECTION
  value: "true"
{{- end }}