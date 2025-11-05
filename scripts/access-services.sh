#!/bin/bash
################################################################################
# Access Cluster Services
#
# This script helps you access Grafana and Prometheus UIs
# through port-forwarding.
#
# Usage:
#   ./access-services.sh [service]
#
# Services:
#   grafana     - Grafana dashboards
#   prometheus  - Prometheus metrics
#   all         - Open all services (in background)
################################################################################

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE=${1:-all}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

access_grafana() {
    print_header "    Grafana Dashboards"
    echo ""
    echo -e "${GREEN}Starting port-forward to Grafana...${NC}"
    echo "URL: http://localhost:3000"
    echo ""
    echo "Authentication:"
    echo "  Default:           admin / admin"
    echo "  Microsoft Entra:   Click 'Sign in with Microsoft Entra ID'"
    echo ""
    kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
}

access_prometheus() {
    print_header "    Prometheus Metrics"
    echo ""
    echo -e "${GREEN}Starting port-forward to Prometheus...${NC}"
    echo "URL: http://localhost:9090"
    echo ""
    kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
}

access_all() {
    print_header "    Starting All Services"
    echo ""
    
    echo -e "${GREEN}Starting Grafana on port 3000...${NC}"
    kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 > /dev/null 2>&1 &
    GRAFANA_PID=$!
    
    echo -e "${GREEN}Starting Prometheus on port 9090...${NC}"
    kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 > /dev/null 2>&1 &
    PROMETHEUS_PID=$!
    
    echo ""
    echo -e "${GREEN}✓ All services started!${NC}"
    echo ""
    echo "Access URLs:"
    echo "  Grafana:    http://localhost:3000"
    echo "              Login: admin/admin OR Microsoft Entra ID"
    echo "  Prometheus: http://localhost:9090"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
    echo ""
    
    # Wait for Ctrl+C
    trap "kill $GRAFANA_PID $PROMETHEUS_PID 2>/dev/null; echo ''; echo 'Services stopped'; exit" INT
    wait
}

# Main
case "$SERVICE" in
    grafana)
        access_grafana
        ;;
    prometheus)
        access_prometheus
        ;;
    all)
        access_all
        ;;
    *)
        echo -e "${RED}Unknown service: $SERVICE${NC}"
        echo ""
        echo "Usage: $0 [service]"
        echo ""
        echo "Services:"
        echo "  grafana     - Grafana dashboards"
        echo "  prometheus  - Prometheus metrics"
        echo "  all         - All services (default)"
        exit 1
        ;;
esac

