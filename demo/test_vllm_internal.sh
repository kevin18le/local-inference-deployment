#!/bin/bash
set -e

echo "=========================================="
echo "Testing vLLM Service from Inside Cluster"
echo "=========================================="
echo ""

# Check if we're in the right context
CONTEXT=$(kubectl config current-context)
if [[ ! "$CONTEXT" == *"local-inference"* ]]; then
    echo "Warning: Current context is '$CONTEXT'"
    echo "Expected context to contain 'local-inference'"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Checking vLLM Deployment status..."
echo ""

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=600s deployment/vllm-server -n inference || {
    echo "Error: vLLM deployment did not become available"
    echo ""
    echo "Checking pod status:"
    kubectl get pods -n inference
    echo ""
    echo "Checking pod logs:"
    kubectl logs -n inference -l app=vllm-server --tail=50
    exit 1
}

echo "✓ Deployment is available"
echo ""

echo "Step 2: Checking Service..."
SERVICE_IP=$(kubectl get svc vllm-server -n inference -o jsonpath='{.spec.clusterIP}')
echo "Service ClusterIP: $SERVICE_IP"
echo ""

echo "Step 3: Testing health endpoint from inside cluster..."
echo ""

# Create a test pod to hit the service from inside the cluster
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vllm-test-client
  namespace: inference
spec:
  restartPolicy: Never
  containers:
  - name: curl
    image: curlimages/curl:latest
    command: ['sh', '-c']
    args:
    - |
      echo "Testing vLLM health endpoint..."
      curl -f http://vllm-server.inference.svc.cluster.local:8000/health || exit 1
      echo ""
      echo "✓ Health check passed"
      echo ""
      echo "Testing chat completions endpoint..."
      curl -X POST http://vllm-server.inference.svc.cluster.local:8000/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{
          "model": "gpt2",
          "messages": [
            {"role": "user", "content": "Hello, how are you?"}
          ],
          "max_tokens": 50
        }' || exit 1
      echo ""
      echo "✓ Chat completions endpoint works!"
EOF

echo "Waiting for test pod to complete..."
kubectl wait --for=condition=Ready pod/vllm-test-client -n inference --timeout=60s || true

# Wait for pod to finish
echo "Waiting for test to complete..."
sleep 5

# Show logs
echo ""
echo "Test results:"
echo "=========================================="
kubectl logs vllm-test-client -n inference

# Check exit code
EXIT_CODE=$(kubectl get pod vllm-test-client -n inference -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}')
if [ "$EXIT_CODE" == "0" ]; then
    echo ""
    echo "=========================================="
    echo "✓ All tests passed!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "✗ Test failed with exit code: $EXIT_CODE"
    echo "=========================================="
fi

# Cleanup
echo ""
echo "Cleaning up test pod..."
kubectl delete pod vllm-test-client -n inference --ignore-not-found=true

echo ""
echo "Service details:"
kubectl get svc vllm-server -n inference
echo ""
echo "You can access vLLM from inside the cluster at:"
echo "  http://vllm-server.inference.svc.cluster.local:8000"
echo ""

