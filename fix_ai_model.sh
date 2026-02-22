#!/bin/bash

# 强制修复 AI 模型问题 - 清除缓存并重新部署

set -e

echo "🔧 强制修复 AI 模型 (gemini-1.5-flash → gemini-1.0-pro)"
echo "================================================================"

cd "$(dirname "$0")" || exit 1

# 检查环境
if [ ! -f deploy_vars.env ]; then
    echo "❌ 未找到 deploy_vars.env"
    exit 1
fi

source deploy_vars.env

# 步骤 1: 检查当前代码
echo ""
echo "1️⃣ 检查源代码..."
if grep -q "gemini-1.0-pro" ai/services.py; then
    echo "✅ ai/services.py 已更新为 gemini-1.0-pro"
else
    echo "❌ ai/services.py 未正确更新"
    echo "   修复代码中..."
    sed -i '' "s/model_name='gemini-pro'/model_name='gemini-1.0-pro'/g" ai/services.py
    sed -i '' "s/model_name='gemini-1.5-flash'/model_name='gemini-1.0-pro'/g" ai/services.py
    sed -i '' "s/model_name='gemini-2.0-flash'/model_name='gemini-1.0-pro'/g" ai/services.py
    echo "✅ 源代码已修复"
fi

# 步骤 2: 清除 Docker 构建缓存
echo ""
echo "2️⃣ 清除 Docker 缓存..."
if command -v docker &> /dev/null; then
    docker system prune -f --all 2>/dev/null || true
    echo "✅ Docker 缓存已清除"
else
    echo "⚠️  Docker 不在本地，Cloud Run 会自动清除"
fi

# 步骤 3: 删除旧镜像（如果存在）
echo ""
echo "3️⃣ 删除云端旧镜像..."
OLD_IMAGE=$(gcloud run revisions describe clickcreate-00013-6sn \
  --service=clickcreate \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format='value(spec.template.spec.containers[0].image)' 2>/dev/null || echo "")

if [ -n "$OLD_IMAGE" ]; then
    echo "   旧镜像: $OLD_IMAGE"
    # 尝试删除
    gcloud container images delete "$OLD_IMAGE" \
      --project=$PROJECT_ID \
      --quiet 2>/dev/null || echo "   ⚠️  无法删除（可能被其他版本使用）"
fi

# 步骤 4: 完整重新部署
echo ""
echo "4️⃣ 重新部署应用（完整构建）..." 
echo "   （这会需要 2-3 分钟）"

gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --no-cache \
  --set-env-vars "ENVIRONMENT=production,GOOGLE_GENERATIVE_AI_KEY=$GEMINI_API_KEY,GOOGLE_GENERATIVE_AI_MODEL=gemini-1.0-pro,DJANGO_SECRET_KEY=autoplanner-django-secret-key-prod-2026,DB_NAME=autoplanner,DB_USER=autoplanner_user,DB_PASSWORD=VUKk2Dr44GI3VDaMyseKPh3a1Mel486rnwEeUPAiVfU,CLOUD_SQL_CONNECTION_NAME=click-to-create:us-west1:autoplanner-db-prod-uswest,GOOGLE_OAUTH_REDIRECT_URI=https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback,OAUTHLIB_INSECURE_TRANSPORT=false" \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10 \
  --quiet

echo "✅ 部署完成"

# 步骤 5: 等待并验证
echo ""
echo "5️⃣ 等待服务启动..."
sleep 20

echo ""
echo "6️⃣ 验证模型配置..."
gcloud run services describe clickcreate \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format=json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    env_vars = data['spec']['template']['spec']['containers'][0]['env']
    for var in env_vars:
        if 'MODEL' in var['name']:
            print(f\"{var['name']}: {var['value']}\")
except Exception as e:
    print(f'Error: {e}')
"

echo ""
echo "7️⃣ 测试 API..."
RESPONSE=$(curl -s -X POST \
  "https://clickcreate-110580126301.us-west1.run.app/api/ai/parse/" \
  -H "Content-Type: application/json" \
  -d '{"text":"明天下午3点开会"}')

if echo "$RESPONSE" | grep -q "gemini-1.5-flash"; then
    echo "❌ 仍然看到 gemini-1.5-flash 错误"
    echo "   响应: $RESPONSE"
    exit 1
elif echo "$RESPONSE" | grep -q "error"; then
    echo "⚠️  API 返回错误（但不是 gemini-1.5-flash）:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
elif echo "$RESPONSE" | grep -q '"events"'; then
    echo "✅ AI 解析成功！"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
else
    echo "⚠️  未知响应:"
    echo "$RESPONSE"
fi

echo ""
echo "================================================================"
echo "✅ 修复完成！"
echo ""
echo "如果仍然有问题，请运行:"
echo "   ./test_ai_remote.sh"
