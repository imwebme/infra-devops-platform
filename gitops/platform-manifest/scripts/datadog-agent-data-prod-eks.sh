kubectl -n datadog apply -f - <<EOF
apiVersion: datadoghq.com/v2alpha1
kind: DatadogAgent
metadata:
  name: datadog
spec:
  features:
    dogstatsd:
      hostPortConfig:
          enabled: true
    apm:
      enabled: true
      hostPortConfig:
        enabled: true
    admissionController:
      enabled: true
      agentCommunicationMode: service
      mutateUnlabelled: true
    externalMetricsServer:
      enabled: false
      useDatadogMetrics: false
    logCollection:
      enabled: true
      containerCollectAll: true
    usm:
      enabled: false
    npm:
      enabled: false
  global:
    registry: public.ecr.aws/datadog
    clusterName: data-prod-eks
    site: datadoghq.com.
    credentials:
      apiSecret:
        secretName: datadog-secret
        keyName: api-key
    criSocketPath: /run/dockershim.sock
    tags:
      - env:prod
      - team:example-org_data
  override:
    clusterAgent:
      image:
        name: public.ecr.aws/datadog/cluster-agent:7.60.0
    nodeAgent:
      image:
        name: public.ecr.aws/datadog/agent:7.60.0
      priorityClassName: daemonset
      tolerations:
       - effect: NoSchedule
         key: mlops-service-bs
         operator: Equal
         value: "true"
       - effect: NoSchedule
         key: mlops-service-ms
         operator: Equal
         value: "true"
       - effect: NoSchedule
         key: eks.taints.example-org.data/service
         operator: Equal
         value: "mgmt-amd"
EOF