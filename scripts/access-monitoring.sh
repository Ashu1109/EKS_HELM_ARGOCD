#!/bin/bash

# Script to access monitoring services

echo "==================================="
echo "Chat App Monitoring Access"
echo "==================================="
echo ""

# Function to get Grafana password
get_grafana_password() {
    kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
    echo
}

# Menu
echo "Select an option:"
echo "1) Access Grafana Dashboard"
echo "2) Access Prometheus UI"
echo "3) Access AlertManager UI"
echo "4) Get Grafana Admin Password"
echo "5) Check Monitoring Pods Status"
echo "6) View Prometheus Targets"
echo ""

read -p "Enter option (1-6): " option

case $option in
    1)
        echo ""
        echo "Starting port-forward to Grafana..."
        echo "Grafana will be available at: http://localhost:3000"
        echo "Username: admin"
        echo -n "Password: "
        get_grafana_password
        echo ""
        echo "Press Ctrl+C to stop port-forwarding"
        kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
        ;;
    2)
        echo ""
        echo "Starting port-forward to Prometheus..."
        echo "Prometheus will be available at: http://localhost:9090"
        echo ""
        echo "Press Ctrl+C to stop port-forwarding"
        kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
        ;;
    3)
        echo ""
        echo "Starting port-forward to AlertManager..."
        echo "AlertManager will be available at: http://localhost:9093"
        echo ""
        echo "Press Ctrl+C to stop port-forwarding"
        kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
        ;;
    4)
        echo ""
        echo "Grafana Admin Credentials:"
        echo "Username: admin"
        echo -n "Password: "
        get_grafana_password
        ;;
    5)
        echo ""
        echo "Monitoring Pods Status:"
        kubectl get pods -n monitoring
        ;;
    6)
        echo ""
        echo "Opening Prometheus Targets page..."
        echo "Port-forwarding Prometheus to localhost:9090"
        echo "Visit http://localhost:9090/targets in your browser"
        echo ""
        echo "Press Ctrl+C to stop port-forwarding"
        kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

