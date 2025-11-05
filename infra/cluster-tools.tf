# ============================================================================
# Kubernetes Cluster Tools
# 
# This file contains all the essential cluster-level tools installed via Helm:
# - Prometheus Stack: Monitoring, metrics, and alerting
# - Nginx Ingress: Ingress controller
# - CSI Secrets Store: Azure KeyVault integration
# ============================================================================

# -----------------------------------------------------------------------------
# Prometheus Stack - Monitoring, Metrics, and Alerting
# -----------------------------------------------------------------------------
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "55.5.0"

  values = [
    yamlencode({
      # Prometheus Configuration
      prometheus = {
        prometheusSpec = {
          retention    = var.environment == "prod" ? "30d" : "7d"
          replicas     = var.environment == "prod" ? 2 : 1
          resources = {
            requests = {
              cpu    = var.environment == "prod" ? "500m" : "200m"
              memory = var.environment == "prod" ? "2Gi" : "512Mi"
            }
            limits = {
              cpu    = var.environment == "prod" ? "2000m" : "1000m"
              memory = var.environment == "prod" ? "4Gi" : "2Gi"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.environment == "prod" ? "50Gi" : "10Gi"
                  }
                }
              }
            }
          }
          # Service monitors for automatic target discovery
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
      
      # Grafana Configuration
      grafana = {
        enabled       = true
        adminPassword = "admin" # Fallback password - Azure AD is primary auth
        service = {
          type = var.environment == "prod" ? "ClusterIP" : "LoadBalancer"
        }
        persistence = {
          enabled = true
          size    = "5Gi"
        }
        # Azure AD / Microsoft Entra ID Authentication
        "grafana.ini" = {
          server = {
            root_url = "http://localhost:3000" # Update with your actual URL
          }
          "auth.azuread" = {
            name                = "Microsoft Entra ID"
            enabled             = true
            allow_sign_up       = true
            auto_login          = false
            client_id           = var.grafana_azure_ad_client_id
            client_secret       = var.grafana_azure_ad_client_secret
            scopes              = "openid email profile"
            auth_url            = "https://login.microsoftonline.com/${local.tenant_id}/oauth2/v2.0/authorize"
            token_url           = "https://login.microsoftonline.com/${local.tenant_id}/oauth2/v2.0/token"
            allowed_domains     = ""
            allowed_groups      = ""
            role_attribute_path = "contains(roles[*], 'Admin') && 'Admin' || contains(roles[*], 'Editor') && 'Editor' || 'Viewer'"
          }
        }
        # Pre-installed dashboards
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name            = "default"
                orgId           = 1
                folder          = ""
                type            = "file"
                disableDeletion = false
                editable        = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
        dashboards = {
          default = {
            "kubernetes-cluster" = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            "kubernetes-pods" = {
              gnetId     = 6417
              revision   = 1
              datasource = "Prometheus"
            }
            "nginx-ingress" = {
              gnetId     = 9614
              revision   = 1
              datasource = "Prometheus"
            }
          }
        }
      }
      
      # Alert Manager Configuration
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          replicas = var.environment == "prod" ? 2 : 1
        }
      }
      
      # Node Exporter
      nodeExporter = {
        enabled = true
      }
      
      # Kube State Metrics
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# -----------------------------------------------------------------------------
# Nginx Ingress Controller
# -----------------------------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.9.0"

  values = [
    yamlencode({
      controller = {
        replicaCount = var.environment == "prod" ? 3 : 1
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
          }
        }
        resources = {
          requests = {
            cpu    = var.environment == "prod" ? "200m" : "100m"
            memory = var.environment == "prod" ? "256Mi" : "128Mi"
          }
          limits = {
            cpu    = var.environment == "prod" ? "1000m" : "500m"
            memory = var.environment == "prod" ? "512Mi" : "256Mi"
          }
        }
        # Enable metrics for Prometheus
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
        # Enable admission webhooks
        admissionWebhooks = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# -----------------------------------------------------------------------------
# Azure KeyVault CSI Driver - Secrets Management
# -----------------------------------------------------------------------------
resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.0"

  values = [
    yamlencode({
      syncSecret = {
        enabled = true
      }
      enableSecretRotation = true
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "azure_kv_provider" {
  name       = "azure-kv-provider"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  namespace  = "kube-system"
  version    = "1.5.0"

  values = [
    yamlencode({
      # Enable metrics
      metrics = {
        enabled = true
      }
    })
  ]

  depends_on = [helm_release.csi_secrets_store]
}

# -----------------------------------------------------------------------------
# Outputs for accessing cluster tools
# -----------------------------------------------------------------------------
output "prometheus_namespace" {
  description = "Namespace where Prometheus stack is installed"
  value       = helm_release.prometheus.namespace
}

output "nginx_ingress_namespace" {
  description = "Namespace where Nginx Ingress is installed"
  value       = helm_release.nginx_ingress.namespace
}

