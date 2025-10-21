#!/bin/bash

echo "======================================"
echo "Monitoring LoadBalancer URLs"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Getting LoadBalancer external URLs..."
echo ""

# Get Grafana URL
GRAFANA_URL=$(kubectl get svc grafana-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
GRAFANA_PORT=$(kubectl get svc grafana-loadbalancer -n monitoring -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

if [ ! -z "$GRAFANA_URL" ]; then
    echo -e "${GREEN}📊 Grafana Dashboard:${NC}"
    echo -e "${BLUE}   http://${GRAFANA_URL}${NC}"
    echo -e "${YELLOW}   Username: admin${NC}"
    echo -e "${YELLOW}   Password: prom-operator${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠ Grafana LoadBalancer is still pending...${NC}"
    echo ""
fi

# Get Prometheus URL
PROMETHEUS_URL=$(kubectl get svc prometheus-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
PROMETHEUS_PORT=$(kubectl get svc prometheus-loadbalancer -n monitoring -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

if [ ! -z "$PROMETHEUS_URL" ]; then
    echo -e "${GREEN}🔍 Prometheus UI:${NC}"
    echo -e "${BLUE}   http://${PROMETHEUS_URL}${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠ Prometheus LoadBalancer is still pending...${NC}"
    echo ""
fi

# Get AlertManager URL
ALERTMANAGER_URL=$(kubectl get svc alertmanager-loadbalancer -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
ALERTMANAGER_PORT=$(kubectl get svc alertmanager-loadbalancer -n monitoring -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)

if [ ! -z "$ALERTMANAGER_URL" ]; then
    echo -e "${GREEN}🚨 AlertManager UI:${NC}"
    echo -e "${BLUE}   http://${ALERTMANAGER_URL}${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠ AlertManager LoadBalancer is still pending...${NC}"
    echo ""
fi

echo "======================================"
echo "LoadBalancer Status:"
echo "======================================"
kubectl get svc -n monitoring | grep loadbalancer

echo ""
echo "Note: It may take a few minutes for LoadBalancers to get external IPs"
echo "Run this script again if any URLs show as pending"
