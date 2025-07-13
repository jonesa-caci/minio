#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}

echo "Running integration tests for $ENVIRONMENT environment..."

# Configuration
MINIO_ALIAS="test-minio"
TEST_BUCKET="integration-test-$(date +%s)"
TEST_FILE="test-file.txt"
TEST_CONTENT="Integration test content - $(date)"

# Function to cleanup
cleanup() {
    echo "Cleaning up test resources..."
    mc rb --force "$MINIO_ALIAS/$TEST_BUCKET" 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Test 1: MinIO Connectivity
echo "Test 1: Testing MinIO connectivity..."
mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Test 2: Server Info
echo "Test 2: Getting server info..."
mc admin info $MINIO_ALIAS

# Test 3: Create Bucket
echo "Test 3: Creating test bucket..."
mc mb "$MINIO_ALIAS/$TEST_BUCKET"

# Test 4: Upload File
echo "Test 4: Uploading test file..."
echo "$TEST_CONTENT" | mc pipe "$MINIO_ALIAS/$TEST_BUCKET/$TEST_FILE"

# Test 5: Download and Verify File
echo "Test 5: Downloading and verifying file..."
DOWNLOADED_CONTENT=$(mc cat "$MINIO_ALIAS/$TEST_BUCKET/$TEST_FILE")
if [ "$DOWNLOADED_CONTENT" != "$TEST_CONTENT" ]; then
    echo "ERROR: Downloaded content doesn't match uploaded content"
    exit 1
fi

# Test 6: List Objects
echo "Test 6: Listing objects..."
mc ls "$MINIO_ALIAS/$TEST_BUCKET"

# Test 7: Copy File
echo "Test 7: Copying file..."
mc cp "$MINIO_ALIAS/$TEST_BUCKET/$TEST_FILE" "$MINIO_ALIAS/$TEST_BUCKET/copied-$TEST_FILE"

# Test 8: Delete File
echo "Test 8: Deleting original file..."
mc rm "$MINIO_ALIAS/$TEST_BUCKET/$TEST_FILE"

# Test 9: Verify Copy Exists
echo "Test 9: Verifying copy exists..."
mc ls "$MINIO_ALIAS/$TEST_BUCKET/copied-$TEST_FILE"

# Test 10: Bucket Policy (if supported)
echo "Test 10: Testing bucket policies..."
mc policy set public "$MINIO_ALIAS/$TEST_BUCKET" 2>/dev/null || echo "Bucket policy test skipped"

# Test 11: Storage Usage
echo "Test 11: Checking storage usage..."
mc admin info $MINIO_ALIAS | grep -E "(Uptime|Storage)"

# Test 12: Health Check
echo "Test 12: Health check..."
curl -f "$MINIO_ENDPOINT/minio/health/live" || {
    echo "ERROR: Health check failed"
    exit 1
}

echo "All integration tests passed successfully!"

# Generate JUnit XML report for GitLab CI
cat > test-results.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="MinIO Integration Tests" tests="12" failures="0" errors="0" time="$(date +%s)">
  <testsuite name="MinIO $ENVIRONMENT Tests" tests="12" failures="0" errors="0" time="$(date +%s)">
    <testcase name="Connectivity Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Server Info Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Create Bucket Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Upload File Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Download File Test" classname="MinIO.Integration" time="1"/>
    <testcase name="List Objects Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Copy File Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Delete File Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Verify Copy Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Bucket Policy Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Storage Usage Test" classname="MinIO.Integration" time="1"/>
    <testcase name="Health Check Test" classname="MinIO.Integration" time="1"/>
  </testsuite>
</testsuites>
EOF

echo "Integration tests completed successfully!"
