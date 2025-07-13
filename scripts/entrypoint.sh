#!/bin/bash
set -e

echo "Starting MinIO client container..."

# Default command
if [ $# -eq 0 ]; then
    exec /bin/bash
fi

# Execute the provided command
exec "$@"
