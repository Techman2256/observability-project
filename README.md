Observability Platform on AWS EKS
A production-grade observability stack deployed on Amazon EKS using Terraform for infrastructure provisioning and ArgoCD for GitOps-based application delivery. The platform provides full cluster and application monitoring via Prometheus and Grafana.

Architecture
GitHub Repo (source of truth)
└── ArgoCD (GitOps controller)
    └── AWS EKS Cluster
        ├── VPC (public + private subnets, NAT Gateway)
        └── monitoring namespace
            ├── Prometheus        ← metrics collection + alerting
            ├── Grafana           ← dashboards + visualization
            ├── Alertmanager      ← alert routing
            ├── Node Exporter     ← node-level metrics (x2)
            ├── Kube State        ← Kubernetes object metrics
            └── podinfo           ← sample app with live metrics
                ├── ServiceMonitor  ← Prometheus scrape config
                └── PrometheusRule  ← custom alert rules

Tech Stack
LayerToolCloud ProviderAWS (EKS, VPC, IAM, EC2)Infrastructure as CodeTerraformGitOps ControllerArgoCDMonitoringPrometheus (kube-prometheus-stack)VisualizationGrafanaPackage ManagementHelmSample ApplicationpodinfoKubernetes Version1.32

Prerequisites

AWS CLI configured with valid credentials
Terraform >= 1.5.0
kubectl
Helm
Git


Project Structure
observability-project/
├── terraform/
│   ├── main.tf           # Provider config
│   ├── variables.tf      # Input variables
│   ├── vpc.tf            # VPC, subnets, NAT Gateway
│   ├── eks.tf            # EKS cluster + managed node group
│   └── outputs.tf        # Cluster endpoint, kubectl command
├── argocd/
│   ├── install/
│   │   └── namespace.yaml
│   └── apps/
│       └── prometheus-stack.yaml   # ArgoCD Application manifest
├── manifests/
│   ├── podinfo.yaml                # Sample app deployment
│   ├── podinfo-service.yaml        # Service for podinfo
│   ├── servicemonitor.yaml         # Prometheus scrape config
│   └── alert-rule.yaml             # Custom PrometheusRules
└── README.md

Deployment Guide
Phase 1 — Provision EKS Cluster with Terraform
bashcd terraform/
terraform init
terraform plan
terraform apply
Once complete, configure kubectl:
bashaws eks update-kubeconfig --region us-east-1 --name observability-cluster
kubectl get nodes
Expected output: 2 nodes in Ready status running Kubernetes 1.32.

Phase 2 — Bootstrap ArgoCD
bashkubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
Get the admin password:
bashkubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
Access the ArgoCD UI:
bashkubectl port-forward svc/argocd-server -n argocd 8080:443
Open https://localhost:8080 — username: admin

Phase 3 — Deploy Prometheus + Grafana via ArgoCD
bashkubectl create namespace monitoring
kubectl apply -f argocd/apps/prometheus-stack.yaml
ArgoCD will pull the kube-prometheus-stack Helm chart from the Prometheus community repo and deploy the full monitoring stack automatically.
Verify all pods are running:
bashkubectl get pods -n monitoring
Access Grafana:
bashkubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80
Open http://localhost:3000 — username: admin, password: observability123

Phase 4 — Deploy Sample App with Metrics
bashkubectl apply -f manifests/
This deploys podinfo with a ServiceMonitor that tells Prometheus to scrape its /metrics endpoint every 15 seconds.
Generate traffic to produce real metrics:
bashkubectl port-forward svc/podinfo -n monitoring 9898:9898
for i in {1..50}; do curl http://localhost:9898; sleep 0.5; done

Phase 5 — Alerts + Dashboards
Custom alert rules are applied via:
bashkubectl apply -f manifests/alert-rule.yaml
Alerts configured:

PodInfoHighRequestRate — fires when request rate exceeds 0.5 req/sec for 1 minute
PodRestartingTooMuch — fires when a pod restarts repeatedly over 15 minutes

View alerts in the Prometheus UI:
bashkubectl port-forward svc/prometheus-stack-kube-prom-prometheus -n monitoring 9090:9090
Open http://localhost:9090 → click Alerts

Grafana Dashboards
DashboardIDDescriptionKubernetes Cluster Monitoring6417Node, pod, container metricsKubernetes Cluster (Prometheus)315Network I/O, CPU, memorypodinfo MetricsCustomLive HTTP request rate per pod
Screenshots
Kubernetes Cluster Dashboard
<!-- Add screenshot here -->
podinfo Request Rate
<!-- Add screenshot here -->
Prometheus Alerts
<!-- Add screenshot here -->

Key Concepts Demonstrated
GitOps — All application deployments are driven by Git. Pushing a manifest to the repo triggers ArgoCD to sync the cluster state automatically. No manual helm install commands needed.
Infrastructure as Code — The entire AWS environment (VPC, subnets, NAT Gateway, EKS cluster, IAM roles, node groups) is defined in Terraform and reproducible with a single terraform apply.
Observability — The platform follows the three pillars approach: metrics via Prometheus, visualization via Grafana, and alerting via Alertmanager. A ServiceMonitor CRD tells Prometheus which services to scrape without manual configuration.
Self-Healing — ArgoCD is configured with selfHeal: true meaning if someone manually changes the cluster state, ArgoCD will automatically revert it back to what is defined in Git.

Teardown
To avoid AWS charges, destroy all resources when done:
bashcd terraform/
terraform destroy
This removes all 60 provisioned AWS resources including the EKS cluster, VPC, subnets, NAT Gateway, and EC2 nodes.

What I Learned

How to provision a production-grade EKS cluster using Terraform modules
How ArgoCD implements the GitOps pattern to replace traditional CI/CD push deployments
The difference between Prometheus (metrics collection) and Grafana (visualization) and how they work together
How ServiceMonitor and PrometheusRule CRDs extend Kubernetes to make apps observable
How kube-prometheus-stack bundles an entire observability platform into a single Helm chart
How Prometheus, Grafana, and Alertmanager compare to AWS CloudWatch and when to use each


Author
Manuel — Cloud/DevOps Engineer
GitHub
