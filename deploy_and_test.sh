#!/bin/bash
set -e

cd /Users/jiaoyan/AutoPlanner
source deploy_vars.env

echo "🔧 强制清除并重新部署（不使用缓存）..."
echo ""

gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,GOOGLE_GENERATIVE_AI_KEY=$GEMINI_API_KEY,GOOGLE_GENERATIVE_AI_MODEL=gemini-1.0-pro,DJANGO_SECRET_KEY=autoplanner-django-secret-key-prod-2026,DB_NAME=autoplanner,DB_USER=autoplanner_user,DB_PASSWORD=VUKk2Dr44GI3VDaMyseKPh3a1Mel486rnwEeUPAiVfU,CLOUD_SQL_CONNECTION_NAME=click-to-create:us-west1:autoplanner-db-prod-uswest,GOOGLE_OAUTH_REDIRECT_URI=https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback,OAUTHLIB_INSECURE_TRANSPORT=false" \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10 \
  --quiet

echo ""
echo "✅ 部署完成，等待 30 秒启动..."
sleep 30

echo ""
echo "📋 再次运行测试..."
bash test_ai_remote.sh
