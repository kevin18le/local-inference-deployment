#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="local-inference"

echo "=========================================="
echo "Local Kubernetes Cluster Setup"
echo "=========================================="
echo ""

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."
echo ""

MISSING_TOOLS=()

if ! command -v kind &> /dev/null; then
    MISSING_TOOLS+=("kind")
fi

if ! command -v kubectl &> /dev/null; then
    MISSING_TOOLS+=("kubectl")
fi

if ! command -v helm &> /dev/null; then
    MISSING_TOOLS+=("helm")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "Missing required tools: ${MISSING_TOOLS[*]}"
    echo ""
    echo "Installation instructions:"
    echo ""
    for tool in "${MISSING_TOOLS[@]}"; do
        case $tool in
            kind)
                echo "  kind:"
                echo "    brew install kind"
                echo "    Or visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
                ;;
            kubectl)
                echo "  kubectl:"
                echo "    brew install kubectl"
                echo "    Or visit: https://kubernetes.io/docs/tasks/tools/"
                ;;
            helm)
                echo "  helm:"
                echo "    brew install helm"
                echo "    Or visit: https://helm.sh/docs/intro/install/"
                ;;
        esac
        echo ""
    done
    exit 1
fi

echo "✓ All prerequisites are installed"
echo ""

# Step 2: Create cluster
echo "Step 2: Creating Kubernetes cluster..."
echo ""

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '${CLUSTER_NAME}' already exists."
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo "Using existing cluster."
    fi
fi

if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    # Create kind cluster configuration
    cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
EOF

    kind create cluster --config /tmp/kind-config.yaml --name "${CLUSTER_NAME}"
    rm /tmp/kind-config.yaml

    # Wait for cluster to be ready
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
fi

echo "✓ Cluster created"
echo ""

# Step 3: Create namespaces
echo "Step 3: Creating namespaces..."
echo ""

kubectl apply -f "${SCRIPT_DIR}/infra/namespaces/inference.yaml"
kubectl apply -f "${SCRIPT_DIR}/infra/namespaces/observability.yaml"
kubectl apply -f "${SCRIPT_DIR}/infra/namespaces/storage.yaml"

echo "✓ Namespaces created:"
kubectl get namespaces inference observability storage
echo ""

# Step 4: Install ingress-nginx
echo "Step 4: Installing ingress-nginx via Helm..."
echo ""

# Add ingress-nginx Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update

# Check if ingress-nginx is already installed
if helm list -n ingress-nginx | grep -q ingress-nginx; then
    echo "ingress-nginx is already installed. Skipping..."
else
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=30080 \
        --set controller.service.nodePorts.https=30443 \
        --wait \
        --timeout 5m

    echo "Waiting for ingress-nginx to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
fi

echo "✓ ingress-nginx installed"
echo ""

# Summary
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Cluster: ${CLUSTER_NAME}"
echo "Context: kind-${CLUSTER_NAME}"
echo ""
echo "Namespaces created:"
echo "  - inference"
echo "  - observability"
echo "  - storage"
echo ""
echo "Ingress Controller:"
echo "  HTTP: http://localhost:30080"
echo "  HTTPS: https://localhost:30443"
echo ""
echo "Useful commands:"
echo "  kubectl cluster-info --context kind-${CLUSTER_NAME}"
echo "  kubectl get namespaces"
echo "  kubectl get pods -n ingress-nginx"
echo "  kind delete cluster --name ${CLUSTER_NAME}"
echo ""

