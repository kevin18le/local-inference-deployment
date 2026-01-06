# vLLM Deployment

This directory contains Kubernetes manifests for deploying vLLM in CPU mode.

## Overview

- **Deployment**: vLLM server running GPT-2 model in CPU mode
- **Service**: ClusterIP service exposing vLLM on port 8000 (internal cluster access only)
- **Namespace**: `inference`

## Deployment

### Using kubectl

```bash
# Deploy vLLM
kubectl apply -k infra/vllm/

# Or deploy individual resources
kubectl apply -f infra/vllm/deployment.yaml
kubectl apply -f infra/vllm/service.yaml
```

### Verify Deployment

```bash
# Check deployment status
kubectl get deployment vllm-server -n inference

# Check pods
kubectl get pods -n inference -l app=vllm-server

# Check service
kubectl get svc vllm-server -n inference

# View logs
kubectl logs -n inference -l app=vllm-server --follow
```

## Testing from Inside Cluster

Run the automated test script:

```bash
./demo/test_vllm_internal.sh
```

Or manually test using a pod:

```bash
# Create a test pod
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -n inference -- sh

# Inside the pod, test the service
curl http://vllm-server.inference.svc.cluster.local:8000/health

# Test chat completions
curl -X POST http://vllm-server.inference.svc.cluster.local:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt2",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "max_tokens": 50
  }'
```

## Service Details

- **Service Name**: `vllm-server`
- **Namespace**: `inference`
- **Type**: `ClusterIP` (internal access only)
- **Port**: `8000`
- **DNS**: `vllm-server.inference.svc.cluster.local`

## Configuration

The deployment uses:
- **Model**: `gpt2` (small model suitable for CPU)
- **Device**: CPU mode
- **Resources**: 
  - CPU: 2-4 cores
  - Memory: 4-8 Gi

## Notes

- vLLM CPU mode support may be experimental
- Model loading can take 1-2 minutes on first startup
- The health endpoint may take 60+ seconds to become ready

