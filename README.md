# local-inference-deployment
A refresher on Kubernetes and vLLM

## Prerequisites

Before setting up the local Kubernetes cluster, ensure you have the following tools installed:

- **kind**: Kubernetes in Docker - for creating local clusters
- **kubectl**: Kubernetes command-line tool
- **helm**: Kubernetes package manager

### Installation (macOS)

```bash
brew install kind kubectl helm
```

For other platforms, visit:
- [kind installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl installation](https://kubernetes.io/docs/tasks/tools/)
- [helm installation](https://helm.sh/docs/intro/install/)

## Quick Start

Run the main setup script to create the cluster, install ingress-nginx, and create namespaces:

```bash
./setup.sh
```

This script will:
1. Check for required prerequisites (kind, kubectl, helm)
2. Create a local Kubernetes cluster using kind
3. Create namespaces: `inference`, `observability`, `storage`
4. Install ingress-nginx via Helm

## Manual Setup

If you prefer to run steps individually:

### 1. Create Cluster

```bash
./setup-cluster.sh
```

### 2. Create Namespaces

```bash
kubectl apply -f infra/namespaces/
```

### 3. Install Ingress Controller

```bash
./infra/ingress/install-ingress-nginx.sh
```

## Cluster Details

- **Cluster Name**: `local-inference`
- **Context**: `kind-local-inference`
- **Ingress Ports**:
  - HTTP: `30080`
  - HTTPS: `30443`

## Namespaces

The following namespaces are created:

- **inference**: For inference workloads (vLLM, etc.)
- **observability**: For monitoring and logging tools
- **storage**: For storage services (MinIO, etc.)

## Useful Commands

```bash
# Check cluster status
kubectl cluster-info --context kind-local-inference

# List all namespaces
kubectl get namespaces

# Check ingress-nginx status
kubectl get pods -n ingress-nginx

# Delete the cluster
kind delete cluster --name local-inference
```

## Project Structure

```
.
├── infra/
│   ├── gateway/          # API Gateway configuration
│   ├── hpa/              # Horizontal Pod Autoscaler
│   ├── ingress/          # Ingress controller setup
│   ├── minio/            # MinIO storage configuration
│   ├── namespaces/       # Namespace definitions
│   ├── observability/    # Monitoring and logging
│   └── vllm/            # vLLM deployment
├── setup.sh              # Main setup script
└── setup-cluster.sh      # Cluster creation script
```
