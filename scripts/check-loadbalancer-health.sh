#!/bin/bash

echo "======================================"
echo "LoadBalancer Health Check"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to test URL
test_url() {
    local url=$1
    local name=$2
    
    echo -n "Testing $name... "
    
    # Use curl with timeout
    if curl -s --connect-timeout 10 --max-time 15 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Accessible${NC}"
        echo -e "${BLUE}   URL: $url${NC}"
        return 0
    else
        echo -e "${RED}✗ Not accessible${NC}"
        return 1
    fi
}

echo "Checking LoadBalancer URLs..."
echo ""

# Get URLs
GRAFANA_URL=$(kubectl get svc grafana-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
PROMETHEUS_URL=$(kubectl get svc prometheus-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
ALERTMANAGER_URL=$(kubectl get svc alertmanager-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

# Test each service
if [ ! -z "$GRAFANA_URL" ]; then
    test_url "http://$GRAFANA_URL" "Grafana"
    echo ""
fi

if [ ! -z "$PROMETHEUS_URL" ]; then
    test_url "http://$PROMETHEUS_URL" "Prometheus"
    echo ""
fi

if [ ! -z "$ALERTMANAGER_URL" ]; then
    test_url "http://$ALERTMANAGER_URL" "AlertManager"
    echo ""
fi

echo "======================================"
echo "Alternative Access Methods:"
echo "======================================"
echo ""
echo -e "${YELLOW}If LoadBalancers are not accessible, use port-forwarding:${NC}"
echo ""
echo "1. Grafana:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   Then visit: http://localhost:3000"
echo ""
echo "2. Prometheus:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   Then visit: http://localhost:9090"
echo ""
echo "3. AlertManager:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
echo "   Then visit: http://localhost:9093"
echo ""
echo "Or use the quick access script:"
echo "   ./scripts/access-monitoring.sh"
echo ""

echo "======================================"
echo "LoadBalancer Status:"
echo "======================================"
kubectl get svc -n monitoring | grep loadbalancer
