# Project: “Mini Inference Platform”
**Goal**: A local Kubernetes cluster that serves an OpenAI-compatible /v1/chat/completions endpoint backed by vLLM, plus:
- S3-compatible artifact storage (MinIO locally, mirrors S3 concepts)
- Ingress + auth (basic API key)
- Metrics + dashboards (Prometheus + Grafana)
- Autoscaling (HPA off CPU or request metrics)

## What you’ll deploy (architecture)
- Kubernetes (kind or minikube)
- vLLM server in a Deployment (CPU mode)
- Model cache + artifacts stored in MinIO (S3-compatible API)
- Ingress controller (nginx) routing traffic to vLLM
### Observability
- Prometheus scraping metrics
- Grafana dashboard (latency, throughput, errors)
### HPA
- scale vLLM replicas based on CPU (simple) and optionally requests (advanced)
### Load test client
- small script that sends concurrent requests and logs p50/p95 latency

## Output:
A repo you can show: README + infra/ manifests + demo/ scripts
A working endpoint you can curl like OpenAI