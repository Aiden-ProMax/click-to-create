#!/bin/bash

# 远程测试 AI 解析功能并诊断模型问题

API_URL="https://clickcreate-110580126301.us-west1.run.app"
TEST_TEXT="明天下午3点开会"

echo "🧪 远程测试 AI 解析功能"
echo "================================"
echo ""
echo "📍 API 地址: $API_URL"
echo "📍 测试文本: $TEST_TEXT"
echo ""

# 获取 CSRF token（如果需要）
echo "1️⃣ 获取页面..."
curl -s -c /tmp/cookies.txt "$API_URL/dashboard.html" > /dev/null

# 测试 AI 解析 API
echo "2️⃣ 调用 AI 解析 API..."
echo ""

RESPONSE=$(curl -s -X POST \
  "$API_URL/api/ai/parse/" \
  -H "Content-Type: application/json" \
  -b /tmp/cookies.txt \
  -d "{\"text\": \"$TEST_TEXT\"}" \
  -w "\n%{http_code}")

# 分离响应体和状态码
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP 状态码: $HTTP_CODE"
echo ""
echo "📋 响应内容:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

# 诊断
if [[ $HTTP_CODE == "200" ]]; then
    echo "✅ API 调用成功！AI 解析已修复"
elif [[ "$BODY" == *"gemini-1.5-flash"* ]]; then
    echo "❌ 错误：容器中仍在使用 gemini-1.5-flash"
    echo "   原因：旧镜像仍在运行"
    echo "   解决：需要强制删除镜像并重新部署"
elif [[ "$BODY" == *"gemini-1.0-pro"* ]]; then
    echo "⚠️  API 返回 gemini-1.0-pro 相关错误"
    echo "   可能是模型配置问题"
    echo "   信息: $BODY"
elif [[ "$BODY" == *"404"* ]]; then
    echo "❌ 404 错误"
    echo "   问题: $BODY"
elif [[ $HTTP_CODE == "401" ]] || [[ $HTTP_CODE == "403" ]]; then
    echo "⚠️  认证错误 (HTTP $HTTP_CODE)"
    echo "   需要先登录或增加认证"
else
    echo "❌ 未知错误"
    echo "   HTTP 状态码: $HTTP_CODE"
    echo "   响应: $BODY"
fi

echo ""
echo "🔍 诊断总结:"
echo "================================"

# 进一步检查日志
echo ""
echo "3️⃣ 检查云日志..."
source deploy_vars.env 2>/dev/null || echo "⚠️  未找到 deploy_vars.env"

if command -v gcloud &> /dev/null; then
    echo ""
    echo "🔎 最近的错误日志:"
    ERRORS=$(gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=clickcreate AND severity=ERROR" \
      --limit=5 --format=json --project=$PROJECT_ID 2>/dev/null | python3 -c "
import sys, json
try:
    logs = json.load(sys.stdin)
    for log in logs:
        if 'textPayload' in log:
            payload = log['textPayload']
            if 'gemini' in payload.lower():
                print(payload[:200])
except:
    pass
" || echo "⚠️  无法读取日志")
    
    if [ -z "$ERRORS" ]; then
        echo "✅ 没有 Gemini 相关错误"
    else
        echo "$ERRORS"
    fi
fi

echo ""
echo "================================"
echo "🔧 如果仍为 gemini-1.5-flash 错误，运行:"
echo "   ./fix_ai_model.sh"
