# Demo Flows Runbook

This runbook prepares and validates two demo flows:

1. User flow with Promise v0.0.1 (DEV + PROD databases)
2. Operator flow upgrading Promise to v0.0.2 (HA mode)

## Prerequisites

- Bootstrap completed successfully:

```bash
make bootstrap HOST_CA_CERT_PATH=/path/to/ca.crt
```

- Contexts available:
  - `k3d-cloudnativedays2026-ctrl-plane`
  - `k3d-cloudnativedays2026-worker-dev`
  - `k3d-cloudnativedays2026-worker-prod`

## 1) User Flow: Create DEV and PROD databases (Promise v0.0.1)

### Step 1. Apply Database resources on control plane

```bash
kubectl --context k3d-cloudnativedays2026-ctrl-plane apply -f databases/dev-database.yaml
kubectl --context k3d-cloudnativedays2026-ctrl-plane apply -f databases/prod-database.yaml
```

Optional negative test:

```bash
kubectl --context k3d-cloudnativedays2026-ctrl-plane apply -f databases/wrong-database.yaml
```

Expected result: validation error due to invalid `spec.size`.

### Step 2. Verify cross-cluster placement

```bash
kubectl --context k3d-cloudnativedays2026-worker-dev get clusters.postgresql.cnpg.io -A
kubectl --context k3d-cloudnativedays2026-worker-prod get clusters.postgresql.cnpg.io -A
```

Expected:

- `dev-database` appears in worker-dev only
- `prod-database` appears in worker-prod only

### Step 3. Verify config differences (v0.0.1)

DEV checks:

```bash
kubectl --context k3d-cloudnativedays2026-worker-dev -n default get cluster dev-database -o jsonpath='{.spec.instances}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-dev -n default get cluster dev-database -o jsonpath='{.spec.postgresql.parameters.max_connections}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-dev -n default get cluster dev-database -o jsonpath='{.spec.postgresql.parameters.shared_buffers}{"\n"}'
```

Expected:

- instances: `1`
- max_connections: `50`
- shared_buffers: `64MB`

PROD checks:

```bash
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.spec.instances}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.spec.postgresql.parameters.max_connections}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.spec.postgresql.parameters.shared_buffers}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.spec.backup.retentionPolicy}{"\n"}'
```

Expected:

- instances: `1`
- max_connections: `200`
- shared_buffers: `256MB`
- backup.retentionPolicy: `7d`

## 2) Operator Flow: Upgrade Promise to v0.0.2 and enforce HA

### Step 1. Upgrade Promise definition on control plane

```bash
kubectl --context k3d-cloudnativedays2026-ctrl-plane apply -f promise/v0.0.2/promise.yaml
```

### Step 2. Trigger reconciliation for existing resources

If your environment does not auto-reconcile existing resources immediately after Promise update, force a no-op spec patch on both Database resources:

```bash
kubectl --context k3d-cloudnativedays2026-ctrl-plane -n default patch database dev-database --type merge -p '{"spec":{"postgresql_version":15}}'
kubectl --context k3d-cloudnativedays2026-ctrl-plane -n default patch database prod-database --type merge -p '{"spec":{"postgresql_version":17}}'
```

### Step 3. Verify HA mode (3 replicas)

```bash
kubectl --context k3d-cloudnativedays2026-worker-dev -n default get cluster dev-database -o jsonpath='{.spec.instances}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.spec.instances}{"\n"}'
```

Expected:

- both outputs are `3`

Optional label checks:

```bash
kubectl --context k3d-cloudnativedays2026-worker-dev -n default get cluster dev-database -o jsonpath='{.metadata.labels.ha}{"\n"}'
kubectl --context k3d-cloudnativedays2026-worker-prod -n default get cluster prod-database -o jsonpath='{.metadata.labels.ha}{"\n"}'
```

Expected:

- both outputs are `true`

## Cleanup (optional)

```bash
kubectl --context k3d-cloudnativedays2026-ctrl-plane -n default delete database dev-database prod-database --ignore-not-found
```
