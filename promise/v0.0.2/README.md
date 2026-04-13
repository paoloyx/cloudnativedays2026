# Promise v2.0 - Database with High Availability

This is the second version of the Database Promise, adding High Availability support.

## Features
- PostgreSQL cluster provisioning with optional HA
- Support for dev and prod environments
- Configurable replicas (1 or 3) via `ha` property
- High Availability enabled by default
- Simple parameter configuration

## Usage

Create a database resource with HA enabled (default):

```yaml
apiVersion: demo.cloudnativedaysitaly.org/v1alpha1
kind: Database
metadata:
  name: my-database-ha
spec:
  size: small
  environment_type: dev
  postgresql_version: 17
  ha: true
```

Create a database without HA:

```yaml
apiVersion: demo.cloudnativedaysitaly.org/v1alpha1
kind: Database
metadata:
  name: my-database-single
spec:
  size: small
  environment_type: dev
  postgresql_version: 17
  ha: false
```

## API Spec

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| size | string | Yes | - | Cluster size (small, large) |
| environment_type | string | Yes | - | Environment (dev, prod) |
| postgresql_version | integer | No | 17 | PostgreSQL version (15, 16, 17) |
| ha | boolean | No | true | Enable High Availability (3 replicas) |

## Replica Configuration

- **ha: true** → **3 replicas** (High Availability enabled)
- **ha: false** → **1 replica** (Single instance, no HA)

## Demo Scenario

This version demonstrates:
1. Starting simple (v1 - single replica, no options)
2. Adding capability incrementally (v2 - optional HA feature)
3. Progressive disclosure of complexity
