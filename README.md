# MinIO and Longhorn GitLab CI/CD Pipeline

This repository contains a comprehensive GitLab CI/CD pipeline for deploying and managing MinIO object storage with Longhorn persistent storage in Kubernetes environments.

## Features

- **Multi-environment deployments** (staging, production)
- **Security-first approach** with vulnerability scanning
- **Automated testing** and integration validation
- **Helm chart management** for MinIO and Longhorn
- **Monitoring and alerting** integration
- **Backup and disaster recovery** procedures
- **Infrastructure as Code** with Kubernetes manifests

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitLab CI/CD  │───▶│   Kubernetes    │───▶│   Longhorn      │
│                 │    │                 │    │   Storage       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     MinIO       │
                       │  Object Storage │
                       └─────────────────┘
```

## Prerequisites

- Kubernetes cluster (1.25+)
- GitLab Runner with Kubernetes executor
- Helm 3.13+
- Longhorn storage system installed
- NGINX Ingress Controller
- cert-manager for TLS certificates

### Required GitLab CI/CD Variables

Set these variables in your GitLab project settings:

```bash
# Container Registry
CI_REGISTRY_USER          # GitLab registry username
CI_REGISTRY_PASSWORD      # GitLab registry password

# MinIO Configuration
MINIO_ROOT_USER           # MinIO admin username
MINIO_ROOT_PASSWORD       # MinIO admin password
MINIO_ENDPOINT            # MinIO server endpoint

# Kubernetes Contexts
KUBE_CONTEXT_STAGING      # Kubernetes context for staging
KUBE_CONTEXT_PRODUCTION   # Kubernetes context for production

# Backup Configuration (optional)
BACKUP_ACCESS_KEY         # S3 backup access key
BACKUP_SECRET_KEY         # S3 backup secret key
BACKUP_ENDPOINT           # S3 backup endpoint

# Notifications (optional)
SLACK_WEBHOOK_URL         # Slack webhook for notifications
```

## Pipeline Stages

### 1. Validate
- YAML syntax validation
- Kubernetes manifest validation
- Helm chart linting and templating

### 2. Build
- Docker image building for MinIO client tools
- Image pushing to registry
- Multi-arch support

### 3. Security Scan
- Container vulnerability scanning with Trivy
- SAST (Static Application Security Testing)
- Dependency scanning
- Critical vulnerability blocking

### 4. Test
- MinIO connectivity tests
- Longhorn storage validation
- Integration testing

### 5. Deploy Staging
- Automated deployment to staging environment
- Health checks and validation
- Smoke tests

### 6. Integration Test
- End-to-end testing in staging
- Performance validation
- Data persistence tests

### 7. Deploy Production
- Manual approval required
- Zero-downtime deployment
- Production health validation
- Automatic rollback on failure

### 8. Cleanup
- Old image cleanup
- Resource optimization
- Log archival

## Directory Structure

```
.
├── .gitlab-ci.yml              # Main pipeline configuration
├── README.md                   # This file
├── docker/
│   └── minio-client/
│       └── Dockerfile          # MinIO client container
├── helm/
│   └── minio/
│       ├── Chart.yaml          # Helm chart metadata
│       ├── values.yaml         # Default values
│       ├── values-staging.yaml # Staging environment values
│       ├── values-production.yaml # Production environment values
│       └── templates/          # Helm templates
├── k8s/
│   ├── minio-deployment.yaml   # Kubernetes manifests
│   └── longhorn-config.yaml    # Longhorn configuration
├── scripts/
│   ├── entrypoint.sh          # Container entrypoint
│   └── integration-tests.sh    # Integration test script
└── tests/
    └── longhorn-test-pvc.yaml  # Longhorn test resources
```

## Usage

### Local Development

1. **Install dependencies:**
   ```bash
   # Install Helm
   curl https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz | tar xz
   sudo mv linux-amd64/helm /usr/local/bin/

   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

2. **Validate configurations:**
   ```bash
   # Validate YAML files
   yamllint .gitlab-ci.yml
   yamllint k8s/
   yamllint helm/

   # Validate Kubernetes manifests
   kubectl --dry-run=client apply -f k8s/

   # Validate Helm charts
   helm lint helm/minio/
   helm template minio helm/minio/ --debug
   ```

3. **Test locally:**
   ```bash
   # Build Docker image
   docker build -t minio-client:local -f docker/minio-client/Dockerfile .

   # Run integration tests
   docker run --rm -e MINIO_ENDPOINT=http://localhost:9000 \
     -e MINIO_ROOT_USER=minio \
     -e MINIO_ROOT_PASSWORD=minio123 \
     minio-client:local ./scripts/integration-tests.sh
   ```

### Deployment

#### Staging Deployment
```bash
helm upgrade --install minio-staging helm/minio/ \
  --namespace minio-staging \
  --create-namespace \
  --values helm/minio/values-staging.yaml
```

#### Production Deployment
```bash
helm upgrade --install minio-prod helm/minio/ \
  --namespace minio-production \
  --create-namespace \
  --values helm/minio/values-production.yaml
```

## Security Best Practices

### Container Security
- Non-root user execution
- Read-only root filesystem where possible
- Minimal base images (Alpine Linux)
- Regular vulnerability scanning
- Security context constraints

### Network Security
- Network policies for traffic isolation
- TLS encryption in transit
- Ingress controller with SSL termination
- Service mesh integration ready

### Storage Security
- Encrypted persistent volumes
- Backup encryption
- Access control policies
- Audit logging

### Access Control
- RBAC (Role-Based Access Control)
- Service accounts with minimal permissions
- Secrets management with external secret stores
- Multi-factor authentication support

## Monitoring and Observability

### Metrics
- Prometheus metrics collection
- Grafana dashboards
- AlertManager integration
- Custom SLIs/SLOs

### Logging
- Structured logging
- Centralized log aggregation
- Log retention policies
- Security event monitoring

### Tracing
- Distributed tracing support
- Performance monitoring
- Request flow visualization
- Error tracking

## Backup and Disaster Recovery

### Backup Strategy
- Automated daily backups
- Cross-region replication
- Point-in-time recovery
- Backup validation

### Disaster Recovery
- RTO: 15 minutes
- RPO: 1 hour
- Automated failover
- Regular DR testing

## Troubleshooting

### Common Issues

1. **Pipeline fails at validation stage:**
   - Check YAML syntax with `yamllint`
   - Validate Kubernetes manifests
   - Ensure Helm chart templates are correct

2. **Security scan failures:**
   - Update base images to latest versions
   - Review and fix critical vulnerabilities
   - Update dependency versions

3. **Deployment failures:**
   - Check resource quotas and limits
   - Verify persistent volume availability
   - Review network policies
   - Check ingress controller configuration

4. **Integration test failures:**
   - Verify MinIO credentials and endpoint
   - Check network connectivity
   - Review service mesh policies
   - Validate DNS resolution

### Debug Commands

```bash
# Check pod status
kubectl get pods -n minio-production

# View pod logs
kubectl logs -n minio-production deployment/minio-prod

# Check persistent volumes
kubectl get pv,pvc -n minio-production

# Test MinIO connectivity
kubectl run -it --rm debug --image=minio/mc --restart=Never -- \
  mc alias set test http://minio-service:9000 admin password

# Check Longhorn status
kubectl get volumes,engines,replicas -n longhorn-system
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Standards
- Use consistent YAML formatting
- Add comments for complex configurations
- Follow Kubernetes best practices
- Include security considerations
- Update documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the CoreNet team
- Check the troubleshooting section
- Review GitLab CI/CD logs

## Changelog

### v0.1.0 (2024-01-16)
- Initial release
- Basic MinIO and Longhorn integration
- Multi-environment support
- Security scanning integration
- Automated testing framework
