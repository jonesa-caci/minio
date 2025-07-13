FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    curl \
    bash \
    jq \
    ca-certificates \
    && update-ca-certificates

# Install MinIO client
RUN curl -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc \
    && chmod +x /usr/local/bin/mc

# Install kubectl for Kubernetes operations
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Create non-root user rYD)XywHA5UpWjQ%1zCx
RUN addgroup -g 1001 minio && \
    adduser -D -u 1001 -G minio minio

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

USER minio
WORKDIR /home/minio

ENTRYPOINT ["/scripts/entrypoint.sh"]
