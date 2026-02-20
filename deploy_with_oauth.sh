#!/bin/bash
# Deployment script for clickcreate with Google OAuth credentials

set -e

echo "🚀 部署 clickcreate 到 Cloud Run（包含 Google OAuth）..."

cd /Users/jiaoyan/AutoPlanner

# 创建临时的环境变量文件
ENV_FILE="/tmp/clickcreate_env.yaml"

cat > "$ENV_FILE" << 'ENVEOF'
ENVIRONMENT: production
DJANGO_SECRET_KEY: autoplanner-django-secret-key-prod-2026
DB_NAME: autoplanner
DB_USER: autoplanner_user
DB_PASSWORD: VUKk2Dr44GI3VDaMyseKPh3a1Mel486rnwEeUPAiVfU
CLOUD_SQL_CONNECTION_NAME: click-to-create:us-west1:autoplanner-db-prod-uswest
GOOGLE_OAUTH_CLIENT_JSON: '{"web":{"client_id":"110580126301-numum3bhq595fc4pnse3a7lgj24ua00s.apps.googleusercontent.com","project_id":"click-to-create","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"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"}}'
OAUTHLIB_INSECURE_TRANSPORT: "false"
ENVEOF

# 部署到 Cloud Run
gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated \
  --env-vars-file "$ENV_FILE" \
  --add-cloudsql-instances=click-to-create:us-west1:autoplanner-db-prod-uswest \
  --memory=512Mi \
  --timeout=3600 \
  --max-instances=10 \
  --quiet

# 清理临时文件
rm "$ENV_FILE"

echo "✅ 部署完成！"
echo "📍 应用 URL: https://clickcreate-110580126301.us-west1.run.app"
echo "⏳ 等待容器启动（1-2 分钟）..."
sleep 60
echo "🧪 测试 Google OAuth 功能..."
curl -s https://clickcreate-110580126301.us-west1.run.app/api/google/status/ || echo "服务还在启动中，请稍后再试"
