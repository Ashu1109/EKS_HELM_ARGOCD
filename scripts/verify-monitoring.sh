#!/bin/bash

echo "======================================"
echo "Monitoring Stack Verification"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

echo "1. Checking monitoring namespace..."
kubectl get namespace monitoring &>/dev/null
check_status "Monitoring namespace exists"
echo ""

echo "2. Checking Prometheus pods..."
PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
if [ "$PROM_PODS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Prometheus pods running: $PROM_PODS"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
else
    echo -e "${RED}✗${NC} No Prometheus pods found"
fi
echo ""

echo "3. Checking Grafana pod..."
GRAFANA_STATUS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | awk '{print $3}')
if [ "$GRAFANA_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓${NC} Grafana is running"
else
    echo -e "${YELLOW}⚠${NC} Grafana status: $GRAFANA_STATUS"
fi
echo ""

echo "4. Checking AlertManager..."
ALERT_STATUS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers 2>/dev/null | awk '{print $3}')
if [ "$ALERT_STATUS" == "Running" ]; then
    echo -e "${GREEN}✓${NC} AlertManager is running"
else
    echo -e "${YELLOW}⚠${NC} AlertManager status: $ALERT_STATUS"
fi
echo ""

echo "5. Checking ServiceMonitors..."
SM_COUNT=$(kubectl get servicemonitor -n monitoring 2>/dev/null | grep -c "chat-app")
if [ "$SM_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} ServiceMonitors for chat app: $SM_COUNT"
    kubectl get servicemonitor -n monitoring | grep chat-app
else
    echo -e "${RED}✗${NC} No chat app ServiceMonitors found"
fi
echo ""

echo "6. Checking Services..."
kubectl get svc -n monitoring | grep -E "NAME|prometheus-grafana|prometheus-kube-prometheus-prometheus|alertmanager"
echo ""

echo "7. Getting Grafana credentials..."
echo -e "${YELLOW}Username:${NC} admin"
GRAFANA_PASS=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode)
if [ ! -z "$GRAFANA_PASS" ]; then
    echo -e "${YELLOW}Password:${NC} $GRAFANA_PASS"
else
    echo -e "${RED}✗${NC} Could not retrieve Grafana password"
fi
echo ""

echo "======================================"
echo "Access Instructions:"
echo "======================================"
echo ""
echo "To access Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Then visit: http://localhost:3000"
echo ""
echo "To access Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo "To access AlertManager:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
echo "  Then visit: http://localhost:9093"
echo ""
echo "Or use the quick access script:"
echo "  ./scripts/access-monitoring.sh"
echo ""

