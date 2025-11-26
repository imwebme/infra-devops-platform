{{/*
Expand the name of the chart.
*/}}
{{- define "base-helm.name" -}}
{{- default .Chart.Name .Values.appName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
This is the actual name set in the chart's metadata name.
*/}}
{{- define "base-helm.realname" -}}
  {{- if and .Values.rollout.enabled .Values.rollout.blue_green.enabled }}
    {{- printf "%s-bluegreen" (.Values.appName | default .Chart.Name) | trunc 63 }}
  {{- else if and .Values.rollout.enabled .Values.rollout.canary.enabled }}
    {{- printf "%s-canary" (.Values.appName | default .Chart.Name) | trunc 63 }}
  {{- else }}
    {{- default .Chart.Name .Values.appName | trunc 63 }}
  {{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
{{- define "base-helm.namespace" -}}
{{- if eq .Release.Namespace "default" }}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}
    {{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "base-helm.fullname" -}}
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
{{- define "base-helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base-helm.labels" -}}
helm.sh/chart: {{ include "base-helm.chart" . }}
{{ include "base-helm.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "base-helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "base-helm.namespace" . }}
app.kubernetes.io/instance: {{ include "base-helm.fullname" . }}
{{- end }}

{{/*
Datadog deployment labels
*/}}
{{- define "base-helm.datadog.labels" -}}
tags.datadoghq.com/env: {{ .Values.env }}
tags.datadoghq.com/service: {{ include "base-helm.fullname" . }}
# tags.datadoghq.com/version: 2.2.67
{{- end }}

{{/*
Datadog annotations
*/}}
{{- define "base-helm.datadog.annotations" -}}
tags.datadoghq.com/env: {{ .Values.env }}
tags.datadoghq.com/service: {{ include "base-helm.fullname" . }}
# tags.datadoghq.com/version: 2.2.67
{{- end }}

{{/*
Deployment labels
*/}}
{{- define "base-helm.deployment.labels" -}}
{{- range $key, $val := (merge .Values.deployment.labels .Values.global.deployment.labels) }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
Deployment annotations
*/}}
{{- define "base-helm.deployment.annotations" -}}
{{- range $key, $val := (merge .Values.deployment.annotations .Values.global.deployment.annotations) }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
ServiceAccount annotations
*/}}
{{- define "base-helm.sa.annotations" -}}
{{- range $key, $val := (merge .Values.sa.annotations .Values.global.sa.annotations) }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
HPA annotations
*/}}
{{- define "base-helm.hpa.annotations" -}}
{{- range $key, $val := (merge .Values.hpa.annotations .Values.global.hpa.annotations) }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
ALB Ingress annotations
*/}}
{{- define "base-helm.alb.annotations" -}}
alb.ingress.kubernetes.io/backend-protocol: HTTP
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
alb.ingress.kubernetes.io/manage-backend-security-group-rules: 'true'
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/ssl-redirect: '443'
alb.ingress.kubernetes.io/tags: 'Environment=hub,GitOps=true'
alb.ingress.kubernetes.io/target-type: ip
{{- end}}

{{/*
Create the name of the service account to use
*/}}
{{- define "base-helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "base-helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/* Fix KubeVersion with bad pre-release. */}}
{{- define "base-app.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version (regexFind "v[0-9]+\\.[0-9]+\\.[0-9]+" .Capabilities.KubeVersion.Version) -}}
{{- end -}}

{{/*
Create the previewHost for blue / green deploy
*/}}
{{- define "base-helm.previewHost" -}}
{{- $restHost := list }}
{{- $previewHost := "" }}
{{- range .Values.ingress.host }}
  {{- if or ( . | contains ".dev." ) ( . | contains ".qa." ) ( . | contains ".stage." ) ( . | contains ".prod." ) }}
    {{- $host := . }}
    {{- $splitHost := split "." $host }}
    {{- range $index, $value := $splitHost }}
      {{- if eq $index "_0" }}
        {{- $restHost = append $restHost (printf "%s-preview" $value) }}
      {{- else }}
        {{- $restHost = append $restHost ($value) }}
      {{- end }}
    {{- end }}
    {{- $previewHost = join "." $restHost }}
  {{- end}}
{{- end }}
{{- printf "%s" $previewHost}}
{{- end -}}

{{/*
Check the activation status of the additionalPort for multi-port."
*/}}
{{- define "base-helm.additionalPort.enabled" -}}
{{- if and .Values.additionalPort.portName .Values.additionalPort.containerPort -}}
  true
{{- else -}}
  false
{{- end -}}
{{- end -}}

{{/*
Check the activation status of the hpa."
*/}}
{{- define "base-helm.hpa.enabled" -}}
{{- if or .Values.global.hpa.enabled .Values.hpa.enabled -}}
{{- if (eq .Values.hpa.enabled false) -}}
  false
{{- else -}}
  true
{{- end -}}
{{- else -}}
  false
{{- end -}}
{{- end -}}

{{/*
Create the additionalPortHosts for blue / green deploy
*/}}
{{- define "base-helm.additionalPortHosts" -}}
{{- $modifiedHosts := "" -}}
{{- range $i, $host := .Values.ingress.host -}}
  {{- $splitHost := splitList "." $host -}}
  {{- $subDomain := index $splitHost 0 -}}
  {{- $modifiedHost := printf "%s-%s.%s" $subDomain ($.Values.additionalPort.portName | default "http" ) (join "." (slice $splitHost 1)) -}}
    {{- if $i -}}
      {{- $modifiedHosts = printf "%s,%s" $modifiedHosts $modifiedHost -}}
    {{- else -}}
      {{- $modifiedHosts = $modifiedHost -}}
    {{- end -}}
  {{- end -}}
{{- $modifiedHosts -}}
{{- end -}}

{{/*
Datadog Envs
*/}}
{{- define "base-helm.datadog.envs" -}}
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_LOGS_CONFIG_AUTO_MULTI_LINE_DETECTION
  value: "true"
- name: DD_RUNTIME_METRICS_ENABLED
  value: "true"
{{- end }}