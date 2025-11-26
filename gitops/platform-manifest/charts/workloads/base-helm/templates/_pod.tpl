{{- define "base-helm.podSpec" -}}
{{- if hasKey .Values "topologySpreadConstraints" }}
topologySpreadConstraints:
  {{- toYaml .Values.topologySpreadConstraints | nindent 2 }}
{{- else }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: "topology.kubernetes.io/zone"
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        {{- include "base-helm.selectorLabels" . | nindent 8 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
affinity:
  {{- if .Values.affinity }}
  {{- toYaml .Values.affinity | nindent 2 }}
  {{- else }}
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 99
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: "app.kubernetes.io/name"
              operator: In
              values:
              - {{ include "base-helm.realname" . }}
          topologyKey: "kubernetes.io/hostname"
  {{- end }}
{{- with .Values.deployment.volumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{ if .Values.sa.enabled }}
serviceAccountName: {{ default (include "base-helm.realname" .) .Values.sa.name }}
{{- end }}
containers:
  - name: {{ include "base-helm.realname" . }}
    image: {{ .Values.deployment.image.repository | default "nginx" }}:{{ .Values.deployment.image.tag | default "1.14.2" }}
    imagePullPolicy: {{ .Values.deployment.image.pullPolicy | default "IfNotPresent" | quote }}
    {{ if .Values.deployment.securityContext -}}
    securityContext:
      {{- toYaml .Values.deployment.securityContext | nindent 6 }}
    {{- end }}
    {{- with .Values.deployment.command }}
    command:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.deployment.args }}
    args:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    env:
      {{- if .Values.deployment.env }}
      {{- toYaml .Values.deployment.env | nindent 6 }}
      {{- end }}
      {{- if .Values.datadog.enabled }}
      {{- include "base-helm.datadog.envs" . | nindent 6 }}
      {{- if .Values.datadog.profile.enabled }}
      - name: DD_PROFILING_ENABLED
        value: "true"
      - name: DD_PROFILING_TIMELINE_ENABLED
        value: "true"
      {{- end }}
      {{- end }}
      {{- if .Values.externalSecrets.enabled }}
      {{- range $index, $value := .Values.externalSecrets.env }}
      - name: {{ default $value.key $value.alias }}
        valueFrom:
          secretKeyRef:
            name: {{ include "base-helm.realname" $ }}
            key: {{ $value.key }}
      {{- end }}
      {{- end }}
    ports:
      - name: {{ .Values.service.portName | default "http" }}
        containerPort: {{ .Values.deployment.port }}
        protocol: TCP
      {{- range .Values.additionalPorts }}
      - name: {{ .portName }}
        containerPort: {{ .targetPort }}
        protocol: TCP
      {{- end }}
    {{ if .Values.deployment.livenessProbe -}}
    livenessProbe:
      {{- toYaml .Values.deployment.livenessProbe | nindent 6 }}
    {{- end }}
    {{ if .Values.deployment.readinessProbe -}}
    readinessProbe:
      {{- toYaml .Values.deployment.readinessProbe | nindent 6 }}
    {{- end }}
    {{ if .Values.deployment.startupProbe -}}
    startupProbe:
      {{- toYaml .Values.deployment.startupProbe | nindent 6 }}
    {{- end }}
    resources:
      {{ if .Values.deployment.resources -}}
      {{- .Values.deployment.resources | toYaml | trim | nindent 6 }}
      {{ else -}}
      requests:
        memory: "1024Mi"
        cpu: "250m"
      limits:
        memory: "1024Mi"
        cpu: "2000m"
    {{- end }}
    {{- with .Values.deployment.volumeMounts}}
    volumeMounts:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    
    lifecycle:
      {{ if .Values.deployment.lifecycle -}}
      {{- .Values.deployment.lifecycle | toYaml | trim | nindent 6 }}
      {{ else -}}
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 80"]
      {{- end }}
{{- end -}}