#!/bin/bash
set -e

cd /Users/jiaoyan/AutoPlanner

echo "部署应用到 Cloud Run (修复 OAuth)..."

echo "使用 gcloud run deploy..."
gcloud run deploy clickcreate \
  --source . \
  --region us-west2 \
  --set-cloudsql-instances click-to-create:us-west1:autoplanner-db-prod-uswest \
  --env-vars-file env-vars.yaml \
  --timeout=3600 \
  --memory=1Gi \
  --allow-unauthenticated \
  --quiet

echo "✅ 部署完成"
sleep 5
gcloud run services describe clickcreate --region=us-west2 2>&1 | grep -E "Service|URL" | head -3
