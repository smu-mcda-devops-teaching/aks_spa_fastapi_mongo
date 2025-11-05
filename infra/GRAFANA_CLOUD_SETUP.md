# Grafana Cloud Setup Guide

This guide helps you set up Grafana Cloud monitoring for your AKS cluster.

## 🎯 What is Grafana Cloud?

Grafana Cloud is a managed observability platform that provides:
- **Prometheus** - Metrics storage and querying
- **Loki** - Log aggregation
- **Tempo** - Distributed tracing (OTLP)
- **Grafana** - Visualization dashboards
- **Alloy** - Data collection agent (deployed in your cluster)

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│ Your AKS Cluster                                 │
│                                                  │
│  ┌────────────────────────────────────────┐    │
│  │ Grafana Alloy Agents                   │    │
│  │ (grafana-k8s-monitoring chart)         │    │
│  │                                         │    │
│  │  • Collects metrics from pods          │    │
│  │  • Scrapes Prometheus endpoints        │    │
│  │  • Gathers logs from containers        │    │
│  │  • Receives traces (OTLP)              │    │
│  └────────────────────────────────────────┘    │
│              │                                   │
│              │ Sends data to...                 │
└──────────────┼───────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────┐
│ Grafana Cloud (Managed by Grafana)              │
│                                                  │
│  • Prometheus - Stores metrics                  │
│  • Loki - Stores logs                           │
│  • Tempo - Stores traces                        │
│  • Grafana - Dashboards & visualization         │
└─────────────────────────────────────────────────┘
```

## 🚀 Setup Steps

### Step 1: Create Grafana Cloud Account

1. Go to [grafana.com/products/cloud](https://grafana.com/products/cloud)
2. Click **"Start for free"**
3. Sign up (email, GitHub, or Google)
4. Create your organization name

**Free Tier Includes:**
- 10K metrics series
- 50GB logs
- 50GB traces
- 14-day retention
- Perfect for learning and small projects!

### Step 2: Create a Stack

1. After signing up, click **"Create a stack"**
2. Choose a region close to your AKS cluster:
   - `prod-ca-east-0` for Canada East
   - `prod-us-east-0` for US East
   - etc.
3. Name your stack (e.g., `mcda-dev-monitoring`)
4. Click **"Create stack"**

### Step 3: Get Your Credentials

#### **For Prometheus (Metrics)**

1. In your Grafana Cloud portal, go to **"Connections"** → **"Add new connection"**
2. Search for **"Kubernetes Monitoring"**
3. Click **"Install integration"**
4. Copy the following values:

   - **Prometheus URL**: `https://prometheus-prod-XX-prod-REGION.grafana.net/api/prom/push`
   - **Instance ID/Username**: `XXXXXX` (numeric)
   - **Password/Token**: `glc_XXXXXXXXXXXXXXXXX`

#### **For Loki (Logs)**

1. In your Grafana Cloud portal, go to **"Connections"** → **"Loki"**
2. Click **"Details"** or **"Send logs"**
3. Copy:

   - **Loki URL**: `https://logs-prod-XXX.grafana.net/loki/api/v1/push`
   - **User ID**: `XXXXXX`
   - **API Key**: Same as Prometheus or generate new

#### **For Tempo (Traces)**

1. Go to **"Connections"** → **"Tempo"**
2. Copy:

   - **OTLP URL**: `https://otlp-gateway-prod-REGION.grafana.net/otlp`
   - **Instance ID**: `XXXXXX`
   - **API Key**: Same as above

### Step 4: Create Secrets File

Create a file `infra/dev/grafana-cloud-secrets.tfvars`:

```hcl
# Grafana Cloud Credentials
# DO NOT COMMIT THIS FILE!

# Prometheus (Metrics)
destinations_prometheus_url      = "https://prometheus-prod-32-prod-ca-east-0.grafana.net/api/prom/push"
destinations_prometheus_username = "YOUR_PROMETHEUS_INSTANCE_ID"
destinations_prometheus_password = "YOUR_GRAFANA_CLOUD_API_KEY"

# Loki (Logs)
destinations_loki_url      = "https://logs-prod-018.grafana.net/loki/api/v1/push"
destinations_loki_username = "YOUR_LOKI_USER_ID"
destinations_loki_password = "YOUR_GRAFANA_CLOUD_API_KEY"

# Tempo/OTLP (Traces)
destinations_otlp_url      = "https://otlp-gateway-prod-ca-east-0.grafana.net/otlp"
destinations_otlp_username = "YOUR_OTLP_INSTANCE_ID"
destinations_otlp_password = "YOUR_GRAFANA_CLOUD_API_KEY"

# Fleet Management
fleetmanagement_url      = "https://fleet-management-prod-012.grafana.net"
fleetmanagement_username = "YOUR_FLEET_INSTANCE_ID"
fleetmanagement_password = "YOUR_GRAFANA_CLOUD_API_KEY"
```

**Note:** Often the same API key works for all services!

### Step 5: Secure the Secrets File

```bash
# Add to .gitignore
echo "**/grafana-cloud-secrets.tfvars" >> .gitignore

# Verify it won't be committed
git status
```

### Step 6: Deploy with Grafana Cloud Monitoring

```bash
cd infra

# Deploy infrastructure with Grafana Cloud credentials
terraform apply \
  -var-file="dev/dev.tfvars" \
  -var-file="dev/grafana-cloud-secrets.tfvars"
```

**What gets deployed:**
- All your normal infrastructure (AKS, ACR, KeyVault, etc.)
- Prometheus + Grafana in the cluster (local monitoring)
- **Grafana Alloy agents** (send data to Grafana Cloud)

### Step 7: Verify Data is Flowing

1. Go to your Grafana Cloud portal: `https://YOUR-STACK.grafana.net`
2. Click **"Explore"**
3. Select **"Prometheus"** as data source
4. Try a query: `up{cluster="mcda-dev-aks"}`
5. You should see metrics from your cluster!

**For Logs:**
1. In Explore, select **"Loki"**
2. Try: `{namespace="monitoring"}`

## 🔍 What You Can Monitor

Once set up, you'll see:

### **Metrics** (Prometheus)
- Node CPU, memory, disk usage
- Pod resource usage
- Container metrics
- Kubernetes API server metrics
- Custom application metrics

### **Logs** (Loki)
- Container logs from all pods
- Kubernetes events
- Application logs
- Queryable and filterable

### **Traces** (Tempo)
- Distributed traces from your applications
- Request flows across services
- Performance bottlenecks

### **Dashboards**
- Pre-built Kubernetes dashboards
- Node and pod monitoring
- Resource utilization
- Custom dashboards

## 🎓 Benefits for Teaching

**With Grafana Cloud, students learn:**
- ✅ Cloud-native observability
- ✅ Metrics, logs, and traces (the "three pillars")
- ✅ Data collection with agents (Alloy)
- ✅ Remote vs. local monitoring
- ✅ SaaS vs. self-hosted trade-offs

**Comparison:**

| Feature | Local Prometheus/Grafana | Grafana Cloud |
|---------|--------------------------|---------------|
| Setup | Complex | Simple (managed) |
| Storage | In-cluster (expensive) | Cloud (elastic) |
| Retention | Limited by disk | Longer (14-30 days) |
| Maintenance | You manage | Grafana manages |
| Cost | Cluster resources | Free tier available |
| Access | Port-forward or ingress | Direct URL |

## 🔧 Troubleshooting

### Issue: No data appearing in Grafana Cloud

**Check Alloy pods:**
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=alloy
kubectl logs -n monitoring <alloy-pod-name>
```

**Look for:**
- Connection errors
- Authentication failures
- Data being sent successfully

### Issue: Authentication errors

**Verify credentials:**
```bash
# Test Prometheus endpoint
curl -u "USERNAME:API_KEY" \
  "https://prometheus-prod-XX.grafana.net/api/prom/api/v1/query?query=up"
```

Should return JSON response, not 401 Unauthorized.

### Issue: Partial data (metrics but no logs)

**Check individual destinations:**
- Each destination (Prometheus, Loki, OTLP) needs correct credentials
- Verify URL formats (no typos, correct region)
- Check that all API keys are valid

## 🔐 Security Best Practices

1. ✅ **Never commit API keys** to Git
2. ✅ **Rotate API keys** regularly (every 90 days)
3. ✅ **Use separate keys** per environment if possible
4. ✅ **Limit key permissions** to minimum required
5. ✅ **Monitor key usage** in Grafana Cloud settings
6. ✅ **Revoke keys** immediately if compromised

## 💰 Cost Management

**Free Tier Limits:**
- 10,000 series (metrics)
- 50 GB logs per month
- 50 GB traces per month

**If you exceed:**
- Data is sampled/dropped
- Or upgrade to paid tier

**Tips to stay in free tier:**
- Use metric relabeling to drop unnecessary metrics
- Filter logs (don't send debug logs)
- Sample traces (not every request)
- Monitor your usage in Grafana Cloud portal

## 🎯 Alternative: Local Only

If you prefer to use only local Prometheus/Grafana (no cloud):

```bash
# Simply don't provide the grafana-cloud-secrets.tfvars file
terraform apply -var-file="dev/dev.tfvars"

# This skips Grafana Cloud integration
# You'll still have Prometheus + Grafana in your cluster
```

Access via port-forward:
```bash
./scripts/access-services.sh grafana
```

## 📚 Additional Resources

- [Grafana Cloud Documentation](https://grafana.com/docs/grafana-cloud/)
- [Kubernetes Monitoring Guide](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/)
- [Alloy Documentation](https://grafana.com/docs/alloy/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/)

---

## ✅ Summary

**To enable Grafana Cloud:**

1. Sign up at grafana.com
2. Create a stack
3. Get your API credentials
4. Create `grafana-cloud-secrets.tfvars`
5. Run `terraform apply` with the secrets file
6. View your data in Grafana Cloud!

**To skip Grafana Cloud:**

1. Just run `terraform apply -var-file="dev/dev.tfvars"`
2. Use local Prometheus/Grafana via port-forward

Both options give you full monitoring - choose based on your needs!

