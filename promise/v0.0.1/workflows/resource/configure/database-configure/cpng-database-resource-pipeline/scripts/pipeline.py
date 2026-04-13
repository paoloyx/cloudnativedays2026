import kratix_sdk as ks
import yaml

DEV_INSTANCES = 1
PROD_INSTANCES = 1
DEV_STORAGE = "10Gi"
PROD_STORAGE = "10Gi"


def build_backup_spec(namespace: str, name: str) -> dict:
    return {
        "barmanObjectStore": {
            "destinationPath": f"s3://cnpg-backups/{namespace}/{name}",
            "s3Credentials": {
                "accessKeyId": {"name": "backup-s3-creds", "key": "ACCESS_KEY_ID"},
                "secretAccessKey": {"name": "backup-s3-creds", "key": "ACCESS_SECRET_KEY"},
            },
            "wal": {"compression": "gzip"},
            "data": {"compression": "gzip"},
        },
        "retentionPolicy": "7d",
    }


def build_dev_cluster(name: str, namespace: str, size: str, pg_version: int, backup_enabled: bool) -> dict:
    spec = {
        "imageName": f"ghcr.io/cloudnative-pg/postgresql:{pg_version}",
        "instances": DEV_INSTANCES,
        "storage": {
            "size": DEV_STORAGE,
        },
        "postgresql": {
            "parameters": {
                "max_connections": "50",
                "shared_buffers": "64MB",
            },
        },
    }
    if backup_enabled:
        spec["backup"] = build_backup_spec(namespace, name)

    return {
        "apiVersion": "postgresql.cnpg.io/v1",
        "kind": "Cluster",
        "metadata": {
            "name": name,
            "namespace": namespace,
            "labels": {
                "environment": "dev",
            },
        },
        "spec": spec,
    }


def build_prod_cluster(name: str, namespace: str, size: str, pg_version: int) -> dict:
    return {
        "apiVersion": "postgresql.cnpg.io/v1",
        "kind": "Cluster",
        "metadata": {
            "name": name,
            "namespace": namespace,
            "labels": {
                "environment": "prod",
            },
        },
        "spec": {
            "imageName": f"ghcr.io/cloudnative-pg/postgresql:{pg_version}",
            "instances": PROD_INSTANCES,
            "storage": {
                "size": PROD_STORAGE,
            },
            "backup": build_backup_spec(namespace, name),
            "postgresql": {
                "parameters": {
                    "max_connections": "200",
                    "shared_buffers": "256MB",
                },
            },
        },
    }


def main():
    sdk = ks.KratixSDK()
    resource = sdk.read_resource_input()

    name = resource.get_name()
    namespace = resource.get_namespace()
    size = resource.get_value("spec.size", default="small")
    env_type = resource.get_value("spec.environment_type", default="dev")
    pg_version = int(resource.get_value("spec.postgresql_version", default=17))
    backup_enabled = resource.get_value("spec.backup_enabled", default="false") == "true"

    if env_type == "prod":
        cluster = build_prod_cluster(name, namespace, size, pg_version)
    else:
        cluster = build_dev_cluster(name, namespace, size, pg_version, backup_enabled)

    data = yaml.safe_dump(cluster).encode("utf-8")
    sdk.write_output("database.yaml", data)

    # Dynamic routing: schedule to the cluster matching environment_type
    selectors = [ks.DestinationSelector(match_labels={"environment": env_type})]
    sdk.write_destination_selectors(selectors)

    status = ks.Status()
    status.set("environment_type", env_type)
    status.set("postgresql_version", str(pg_version))
    status.set("backup_enabled", "true" if (env_type == "prod" or backup_enabled) else "false")
    sdk.write_status(status)

    print(f"""\n=== DATABASE CLUSTER PROVISIONED ===
Name: {name}
Environment: {env_type.upper()}
PostgreSQL: {pg_version}
Instances: 1 (fixed, no HA)
Storage: {DEV_STORAGE if env_type == 'dev' else PROD_STORAGE}
Backup: {'enabled' if (env_type == 'prod' or backup_enabled) else 'disabled'}
====================================\n""")


if __name__ == '__main__':
    main()
