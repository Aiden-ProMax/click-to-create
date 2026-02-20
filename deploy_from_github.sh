#!/bin/bash
# Deploy from GitHub using Cloud Build
# This can trigger builds from local repo or GitHub repository

set -e

cd /Users/jiaoyan/AutoPlanner
source deploy_vars.env

BRANCH="${1:-main}"

echo "=========================================="
echo "Deploying from Local Repository"
echo "=========================================="
echo "Branch: $BRANCH"
echo "Project: $PROJECT_ID"
echo ""

# Method 1: Build from local directory (recommended for immediate testing)
if [ "$2" = "--local" ]; then
    echo "Building from local source..."
    gcloud builds submit . \
      --region=us-central1 \
      --project=$PROJECT_ID \
      --config=cloudbuild.yaml \
      --timeout=3600
fi

# Method 2: Build from GitHub (requires full setup)
if [ "$2" = "--github" ]; then
    echo "Building from GitHub repository..."
    git checkout $BRANCH
    COMMIT_SHA=$(git rev-parse HEAD)
    echo "Building commitm $COMMIT_SHA"
    
    gcloud builds submit . \
      --region=us-central1 \
      --project=$PROJECT_ID \
      --config=cloudbuild.yaml \
      --timeout=3600
fi

# Default: build from local  
if [ -z "$2" ]; then
    echo "Building from local source..."
    gcloud builds submit . \
      --region=us-central1 \
      --project=$PROJECT_ID \
      --config=cloudbuild.yaml \
      --timeout=3600
fi

