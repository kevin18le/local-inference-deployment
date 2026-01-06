#!/bin/bash
set -e

echo "Installing ingress-nginx via Helm..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed. Please install helm first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Kubernetes cluster is not accessible. Please ensure your cluster is running."
    exit 1
fi

# Add ingress-nginx Helm repository
echo "Adding ingress-nginx Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress-nginx
echo "Installing ingress-nginx..."
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=30080 \
    --set controller.service.nodePorts.https=30443

echo "Waiting for ingress-nginx to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

echo "ingress-nginx installed successfully!"
echo ""
echo "To access ingress, use:"
echo "  HTTP: http://localhost:30080"
echo "  HTTPS: https://localhost:30443"
echo ""
echo "To get the ingress controller service details:"
echo "  kubectl get svc -n ingress-nginx"

