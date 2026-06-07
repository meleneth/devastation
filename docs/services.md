# SNS, SQS, And S3

`devastation` includes local AWS-shaped services for queues, topics, and object storage.

## SNS And SQS

Eventline GoAWS runs at:

```bash
http://eventline.deva.station:4100
```

Use it as the endpoint URL for SNS and SQS clients.

Example with AWS CLI:

```bash
aws --endpoint-url http://eventline.deva.station:4100 sqs list-queues
aws --endpoint-url http://eventline.deva.station:4100 sns list-topics
```

For SDKs, set:

- endpoint: `http://eventline.deva.station:4100`
- region: any local value, such as `us-east-1`
- access key: any non-empty local value
- secret key: any non-empty local value

The persistent service data lives under:

```bash
/srv/devastation/eventline
```

## S3

MinIO runs the S3-compatible API at:

```bash
http://storage.deva.station:9000
```

The browser console is:

```bash
http://storage.deva.station:9001
```

Default credentials:

```text
username: devastation
password: devastation
```

Example with AWS CLI:

```bash
AWS_ACCESS_KEY_ID=devastation \
AWS_SECRET_ACCESS_KEY=devastation \
aws --endpoint-url http://storage.deva.station:9000 s3 mb s3://example
```

Persistent object data lives under:

```bash
/srv/devastation/storage/data
```

## Databases

Postgres services are available at:

- `test-db.deva.station:5432`
- `development-db.deva.station:5432`
- `production-db.deva.station:5432`
- `otel-db.deva.station:5432`

The username and password are both `devastation` by default.

Host ports are also exposed:

- test: `5433`
- development: `5434`
- production: `5435`
- otel: `5436`
