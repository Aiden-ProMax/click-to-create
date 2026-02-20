#!/bin/bash
# Deployment script for clickcreate with Google OAuth credentials and Gemini AI

set -e

echo "🚀 部署 clickcreate 到 Cloud Run（完整配置）..."

cd /Users/jiaoyan/AutoPlanner
source deploy_vars.env

# 创建临时的环境变量文件
ENV_FILE="/tmp/clickcreate_env.yaml"

cat > "$ENV_FILE" << ENVEOF
ENVIRONMENT: production
GOOGLE_GENERATIVE_AI_KEY: ${GEMINI_API_KEY}
GOOGLE_OAUTH_CLIENT_JSON: '{"web":{"client_id":"110580126301-numum3bhq595fc4pnse3a7lgj24ua00s.apps.googleusercontent.com","project_id":"click-to-create","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"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"}}'
GOOGLE_OAUTH_REDIRECT_URI: https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback
DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}
DJANGO_ALLOWED_HOSTS: ${DJANGO_ALLOWED_HOSTS}
OAUTHLIB_INSECURE_TRANSPORT: "false"
DB_NAME: ${DB_NAME}
DB_USER: ${DB_USER}
DB_PASSWORD: ${DB_PASSWORD}
CLOUD_SQL_CONNECTION_NAME: ${CLOUD_SQL_CONNECTION_NAME}
ENVEOF

# 部署到 Cloud Run
gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated \
  --env-vars-file "$ENV_FILE" \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10 \
  --quiet

# 清理临时文件
rm "$ENV_FILE"

echo "✅ 部署完成！"
echo "📍 应用 URL: https://clickcreate-110580126301.us-west1.run.app"
echo ""
echo "📋 已配置的关键环境变量："
echo "   ✅ GOOGLE_GENERATIVE_AI_KEY (Gemini API)"
echo "   ✅ GOOGLE_OAUTH_CLIENT_JSON (Google OAuth)"
echo "   ✅ GOOGLE_OAUTH_REDIRECT_URI"
echo "   ✅ DJANGO_SECRET_KEY"
echo "   ✅ Cloud SQL 连接"
echo ""
echo "⏳ 等待容器启动（1-2 分钟）..."
sleep 60
echo "🧪 测试应用..."
curl -s https://clickcreate-110580126301.us-west1.run.app/ | head -10 && echo -e "\n✅ 服务在线！"
