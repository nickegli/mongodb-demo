# MongoDB Demo for MAD
This repository holds all components required for the MongoDB demo as part of the hiring process for MAD team as Cloud DevOps Engineer.

Following components are part of this repository: <br>
* bitnami/mongodb configuration
* backup script and CronJob
* sample application for testing


<br>

## Installation
This section holds all information on installation of the chart, BackupJob and sample application

### Installation of Helmchart
create a local template 
```shell
helm template bitnami/mongodb --output-dir ./ --values deploy/values.yaml
```
install chart on cluster (ensure that mongodb namespace exists)
```shell
helm install mongodb-demo bitnami/mongodb --values deploy/values.yaml
```
install a specific version of the chart - get available versions run ```helm search repo bitnami/mongodb --versions```
```shell
helm upgrade --install mongodb-demo bitnami/mongodb --version 13.12.1 -f deploy/values-13.12.1.yaml --set auth.replicaSetKey=bXGDODFcwY
helm upgrade --install mongodb-demo bitnami/mongodb --version 13.15.1 -f deploy/values.yaml --set auth.replicaSetKey=bXGDODFcwY
```
### Installation of further components
Install DemoApp from image mongodb-demo-app:1.0.3
```shell
kubectl apply -f deploy/DemoApp/ 
```
Install BackupJob from image mongodb-backup:1.0.2
```shell
kubectl apply -f deploy/BackupJob/
```


## Testing
```shell
docker build --tag mongodb-demo-app:1.0.2 -f build/DemoApp/Dockerfile .
```
| Name | Required | Default value | Description |
|:-------|:---------|:---------|:---------|
| DB_USER  | true | | DB username required to run backup.
| DB_PASSWORD  | true |  | DB password required to run backup.
| DB_AUTHENTICATION_DB | false | admin | Authentication Database required for login.
| DB_CONNECTIONSTRING | true | | Connectionstring used for pod selection.
| DB_NAME | false | "" | Name of specific DB to Backup 

To test if the ReplicaSet is running successfully run the following demo pod.
```shell
kubectl run --namespace mongodb mongodb-demo-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:6.0.6-debian-11-r3 --command -- bash
```

Run the following command to connect to the ReplicaSet from inside the cluster (FullName allows to connect from any namespace)

```shell
mongosh admin --host "rs0/mongodb-demo-0.mongodb-demo-headless.mongodb.svc.cluster.local:27017,mongodb-demo-1.mongodb-demo-headless.mongodb.svc.cluster.local:27017,mongodb-demo-2.mongodb-demo-headless.mongodb.svc.cluster.local:27017" --authenticationDatabase admin -u root -p "12345678"
```

## Security
Security can be implemented on different levels. For instance here are a few aspects to consider on k8s and mongodb level.

### Kubernetes security
1. RBAC: Limit users that can access ressources
2. Network Policies: control traffic between pods
3. Secrets: Use external secret store to store sensitive data - Vault
4. Security Context: enforce bitnami standard User 1001 and ensure runAsNonRoot is set to true.

Keep up with regular security patches and bug fixes. Ensure regular pentesting and vulnerability assessment to keep an overview of risks.


### MongoDB security
1.  Dedicated Accounts: Accounts for different opperations following the principle of least privileges. eg dedicated user for DemoApp/BackupJob.
2. Transport Encryption: Use TLS/SSL to secure data in transmission between client and server.
3. Audit/Logging: Log collection to monitor and analyze security incidents.
4. Security Checklist: Follow the [Checklist](https://www.mongodb.com/docs/manual/administration/security-checklist/) provided by MongoDB


## Monitoring & Alerting
1. Setup Grafana & Prometheus.
2. Grfana dashboards for visualisation.
3. Setup Alertmanager to define notification channels.
4. Setup alerts in Grafana.

Further steps could include **Istio** as ServiceMesh in combbination with **Jaeger** to run traces and monitor real time traffic.

## Backup & Restore - BackupJob

### Build from Dockerfile
```shell
docker build --tag mongodb-backup:1.0.2 -f build/BackupJob/Dockerfile .
```

**Configuration (environment variables)**

| Name | Required | Default value | Description |
|:-------|:---------|:---------|:---------|
| DB_USER  | true | | DB username required to run backup.
| DB_PASSWORD  | true |  | DB password required to run backup.
| DB_AUTHENTICATION_DB | false | admin | Authentication Database required for login.
| DB_CONNECTIONSTRING | true | | Connectionstring used for pod selection.
| DB_NAME | false | "" | Name of specific DB to Backup 
| OUTPUT_BASE_PATH| true | | Output path required for backup storing.
|RETENTION_SPAN| true | | Amount of SPAN for which backups will be stored.
|EXCLUDE_COLLECTIONS_WITH_PREFIX | false | "" | Allows the exclusion of specified collections if not required


Install the BackupJob and all dependencies by running:
```shell
kubectl apply -n mongodb -f .\deploy\BackupJob\
```
> ImagePullPolicy is set to Never to pull local images this can be changed in further releases to incorporate support for Images from DockerHub or internal Registry.

> Should CronJob fail switch CRLF to LF and save the file to fix problems with line endings. 

### Restore
To restore a backup run the following commands:

## Scalability
This setup can be scaled in multiple ways.
* Adding further pods to an existing release
* Running multiple releases for different projects

Therefor technically scalability to +1000 replicas is possible as long as the underlying hardware supports it.


### Way to influence ReplicaSet
Either of two options work to influence the ReplicaSet behaviour. CatchUp Abort prevents new primary from loosing too much time. TimeoutMillis can be reduced to reduce DownTime.

```shell
helm template mongodb-demo --set 'mongodb.extraFlags[0]="electionTimeoutMillis=5000"' --set 'mongodb.extraFlags[1]="replSetAbortPrimaryCatchUp=true"' bitnami/mongodb --output-dir ./ --values deploy/values.yaml
```

```shell
mongodb:
  extraFlags:
    - "--setParameter"
    - "electionTimeoutMillis=5000"
    - "--setParameter"
    - "replSetAbortPrimaryCatchUp=true"
```

### Sequence of events during rolling upgrade
Here's a general sequence of events during a rolling upgrade:

1. The replica set consists of one primary and two secondary nodes.
2. The rolling upgrade process starts by updating one secondary node at a time.
3. As each secondary node is updated, it may briefly go into a "RECOVERING" state, during which it catches up with the changes made by the primary.
4. Once the secondary node is fully caught up, it rejoins the replica set as a secondary member.
5. This process continues until all secondary nodes are updated.
6. Finally, the primary node is updated. As soon as it goes offline, the remaining secondary nodes initiate an election to select a new primary.
7. The election process completes, and a new primary is established.
8. The updated primary rejoins the replica set, this time as a secondary node.
9. The rolling upgrade is now complete, and the replica set is fully updated.

### SpeedUp failover process / reduce the time for elections in MongoDB:

1. `electionTimeoutMillis`: Determines the time interval in milliseconds for a replica set election to complete. Helps speed up the election process. For example: `--setParameter electionTimeoutMillis=2000`.

2. `heartbeatIntervalMillis`: Time interval in milliseconds between heartbeats. Helps detect failures and trigger elections more quickly. For example: `--setParameter heartbeatIntervalMillis=500`.

3. `heartbeatTimeoutSecs`: Sets the maximum time in seconds for a replica set member to respond to a heartbeat request. Helps detect unresponsive members faster, leading to quicker failover. For example: `--setParameter heartbeatTimeoutSecs=2`.

4. `electionHandoffTimeoutMillis`: Defines the maximum time in milliseconds for a primary to hand off its role during an election. Speeds up the failover process. For example: `--setParameter electionHandoffTimeoutMillis=10000`.

Adjusting these parameters can influence stability and reliability


use ${DB_NAME} \
db.test.find() \
db.test.find({ _id: ObjectId("64874f0027ddc85a763ef1d1") })