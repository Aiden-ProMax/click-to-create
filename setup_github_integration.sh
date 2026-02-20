#!/bin/bash
# Setup GitHub integration for Cloud Build
# This script completes the GitHub authorization and creates a build trigger

set -e

cd /Users/jiaoyan/AutoPlanner
source deploy_vars.env

echo "=========================================="
echo "GitHub Cloud Build Integration Setup"
echo "=========================================="
echo ""
echo "IMPORTANT: You need to manually authorize Cloud Build first!"
echo ""
echo "Step 1: Visit this URL in your browser:"
echo "https://console.cloud.google.com/cloud-build/repositories?project=$PROJECT_ID"
echo ""
echo "Step 2: Click on 'Connect repository'"
echo "Step 3: Select 'GitHub' and authorize your account"
echo "Step 4: Select your repository: 'jiaoyan/click-to-create'"
echo ""
echo "After completing the authorization, run:"
echo "gcloud builds repositories create click-to-create --connection=github-conn --remote-uri=https://github.com/jiaoyan/click-to-create --region=us-central1 --project=$PROJECT_ID"
echo ""
echo "Then create the build trigger:"
echo "gcloud builds triggers create github --name=autoplanner-deploy --repo-owner=jiaoyan --repo-name=click-to-create --branch-pattern='^main$' --build-config=cloudbuild.yaml --region=us-central1 --project=$PROJECT_ID"
