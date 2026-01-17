#!/bin/bash

# Script to update image tags in Kubernetes manifests
# Usage: ./update-image-tag.sh <image-tag> [docker-username]

set -e

IMAGE_TAG=${1:-latest}
DOCKER_USERNAME=${2:-devanshpandey21}
DEPLOYMENT_FILE="kubernetes/08-easyshop-deployment.yaml"
MIGRATION_FILE="kubernetes/12-migration-job.yaml"

DOCKER_IMAGE_NAME="${DOCKER_USERNAME}/easyshop-app"
DOCKER_MIGRATION_IMAGE_NAME="${DOCKER_USERNAME}/easyshop-migration"

echo "=========================================="
echo "Updating Kubernetes Image Tags"
echo "=========================================="
echo "Image Tag: $IMAGE_TAG"
echo "Docker Username: $DOCKER_USERNAME"
echo "Main App Image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
echo "Migration Image: ${DOCKER_MIGRATION_IMAGE_NAME}:${IMAGE_TAG}"
echo "=========================================="

# Check if files exist
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ Error: $DEPLOYMENT_FILE not found!"
    exit 1
fi

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Error: $MIGRATION_FILE not found!"
    exit 1
fi

# Update main application deployment
echo "Updating $DEPLOYMENT_FILE..."
sed -i.bak "s|image: .*/easyshop-app.*|image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}|g" "$DEPLOYMENT_FILE"

# Update migration job
echo "Updating $MIGRATION_FILE..."
sed -i.bak "s|image: .*/easyshop-migration.*|image: ${DOCKER_MIGRATION_IMAGE_NAME}:${IMAGE_TAG}|g" "$MIGRATION_FILE"

# Remove backup files
rm -f "${DEPLOYMENT_FILE}.bak" "${MIGRATION_FILE}.bak"

echo ""
echo "✅ Image tags updated successfully!"
echo ""
echo "Modified files:"
echo "  ✓ $DEPLOYMENT_FILE"
echo "  ✓ $MIGRATION_FILE"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff kubernetes/"
echo "  2. Commit changes: git add kubernetes/ && git commit -m 'Update image tags to ${IMAGE_TAG}'"
echo "  3. Push changes: git push origin master"
echo "  4. ArgoCD will auto-sync the changes"
echo "=========================================="
