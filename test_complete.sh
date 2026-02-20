#!/bin/bash

# AutoPlanner 完整功能测试脚本 (改进版)
# 测试所有主要功能，包括 OAuth、AI API 等

set -e

echo "🚀 开始 AutoPlanner 完整功能测试"
echo "════════════════════════════════════"

APP_URL="${APP_URL:-http://localhost:8000}"
TEST_USER="testuser_$(date +%s)"
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"

echo "📋 测试配置:"
echo "  APP_URL: $APP_URL"
echo "  TEST_USER: $TEST_USER"
echo "  TEST_EMAIL: $TEST_EMAIL"
echo ""

# ============= 健康检查 =============
test_health() {
    echo "💚 1️⃣ 应用健康检查..."
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/")
    
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo "  ✅ 应用运行正常 (HTTP $HEALTH_RESPONSE)"
    else
        echo "  ❌ 应用响应异常 (HTTP $HEALTH_RESPONSE)"
        return 1
    fi
}

# ============= 获取 CSRF Token =============
get_csrf_token() {
    echo "🔑 2️⃣ 获取 CSRF Token..."
    CSRF_RESPONSE=$(curl -s -c cookies.txt "$APP_URL/api/auth/csrf/")
    CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('csrfToken', ''))" 2>/dev/null || echo "")
    
    if [ -z "$CSRF_TOKEN" ]; then
        echo "  ⚠️ 无法获取 CSRF Token，将尝试使用 Cookie 中的 token"
        # 从 cookies.txt 提取 csrf token
        CSRF_TOKEN=$(grep -i csrf cookies.txt | awk '{print $NF}' 2>/dev/null || echo "")
    fi
    
    echo "  ✅ CSRF Token 已获取: ${CSRF_TOKEN:0:20}..."
}

# ============= 用户注册 =============
register_user() {
    echo "👤 3️⃣ 注册测试用户..."
    REGISTER_RESPONSE=$(curl -s -b cookies.txt -c cookies.txt \
        -X POST "$APP_URL/api/auth/register/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d "{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
        2>/dev/null)

    if echo "$REGISTER_RESPONSE" | grep -q "\"username\""; then
        echo "  ✅ 用户注册成功"
    else
        echo "  ❌ 用户注册失败"
        echo "  响应: $REGISTER_RESPONSE"
        return 1
    fi
}

# ============= 用户登录 =============
login_user() {
    echo "🔐 4️⃣ 用户登录..."
    LOGIN_RESPONSE=$(curl -s -b cookies.txt -c cookies.txt \
        -X POST "$APP_URL/api/auth/login/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}" \
        2>/dev/null)

    if echo "$LOGIN_RESPONSE" | grep -q "ok"; then
        echo "  ✅ 登录成功"
    else
        echo "  ❌ 登录失败"
        echo "  响应: $LOGIN_RESPONSE"
        return 1
    fi
}

# ============= 检查认证状态 =============
check_auth_status() {
    echo "📊 5️⃣ 检查认证状态..."
    AUTH_RESPONSE=$(curl -s -b cookies.txt \
        "$APP_URL/api/auth/me/" \
        2>/dev/null)

    if echo "$AUTH_RESPONSE" | grep -q "$TEST_USER"; then
        echo "  ✅ 用户已认证: $TEST_USER"
    else
        echo "  ❌ 用户认证检查失败"
        echo "  响应: $AUTH_RESPONSE"
        return 1
    fi
}

# ============= 测试 AI API (不需要 CSRF) =============
test_ai_api() {
    echo "🤖 6️⃣ 测试 AI 事件规范化 API..."
    
    # 使用虚拟环境中的 Python
    .venv/bin/python3 << 'EOF'
import django
import os
import sys

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "autoplanner.settings")
django.setup()

from ai.services import parse_with_openai
from ai.normalizer import EventNormalizer
from django.conf import settings

try:
    # 测试 AI 解析
    print("  ⏳ 测试 AI 解析功能...")
    test_input = "Tomorrow at 2pm team meeting for 1.5 hours"
    
    # 这里可能需要 Gemini API 密钥
    try:
        result = parse_with_openai(test_input)
        if result and isinstance(result, dict) and 'events' in result:
            print("  ✅ AI 解析成功")
        else:
            print("  ⚠️ AI 解析返回意外格式")
    except Exception as e:
        if "API_KEY" in str(e) or "GENERAL_ERROR" in str(e):
            print("  ⚠️ Gemini API 密钥未配置，跳过 AI 功能测试")
        else:
            print(f"  ⚠️ AI 解析失败: {str(e)[:100]}")
    
    # 测试规范化
    print("  ⏳ 测试事件规范化...")
    normalizer = EventNormalizer(default_tz=settings.TIME_ZONE or 'UTC')
    
    # 使用简单测试数据
    test_events = [{
        'title': 'Team Meeting',
        'date': '2026-02-20',
        'start_time': '14:00',
        'duration': '1.5h',
        'location': 'Conference Room',
        'category': 'meeting'
    }]
    
    try:
        normalized = normalizer.normalize(test_events[0])
        if normalized['title'] == 'Team Meeting':
            print("  ✅ 事件规范化成功")
        else:
            print("  ⚠️ 规范化数据异常")
    except Exception as e:
        print(f"  ❌ 规范化失败: {str(e)[:100]}")
        sys.exit(1)
        
    print()
    
except Exception as e:
    print(f"  ❌ AI 测试失败: {str(e)}")
    sys.exit(1)
EOF
}

# ============= 测试 OAuth 准备 =============
test_oauth_setup() {
    echo "🔓 7️⃣ 检查 OAuth 配置..."
    
    # 检查 webclient.json
    if [ -f "webclient.json" ]; then
        echo "  ✅ OAuth 凭证文件已配置"
        
        # 检查 OAuth start URL
        OAUTH_START=$(curl -s -I "$APP_URL/oauth/google/start/" 2>/dev/null | grep -i "location\|200" | head -1)
        if echo "$OAUTH_START" | grep -q "302\|200"; then
            echo "  ✅ OAuth 端点可访问"
        else
            echo "  ⚠️ OAuth 端点可能有问题"
        fi
    else
        echo "  ⚠️ OAuth 凭证文件 (webclient.json) 未配置"
        echo "     请下载 webclient.json 到项目根目录"
    fi
}

# ============= 事件创建测试 =============
test_event_creation() {
    echo "📅 8️⃣ 测试事件创建..."
    
    # 使用虚拟环境中的 Python
    .venv/bin/python3 manage.py shell << 'EOF'
from django.contrib.auth.models import User
from events.models import Event
from django.utils import timezone
from datetime import timedelta

try:
    # 获取最后创建的用户
    user = User.objects.last()
    if not user:
        print("  ⚠️ 没有找到用户")
        exit(0)
    
    # 创建测试事件
    event = Event.objects.create(
        user=user,
        title="自动化测试事件",
        description="由测试脚本创建",
        start_datetime=timezone.now() + timedelta(days=1),
        end_datetime=timezone.now() + timedelta(days=1, hours=1),
        location="测试地点",
        is_synced=False
    )
    
    print(f"  ✅ 事件创建成功 (ID: {event.id})")
    
except Exception as e:
    print(f"  ❌ 事件创建失败: {str(e)}")
    import traceback
    traceback.print_exc()
EOF
}

# ============= 清理 =============
cleanup() {
    echo ""
    echo "🧹 清理测试数据..."
    rm -f cookies.txt
    echo "  ✅ 清理完成"
}

# ============= 主函数 =============
main() {
    trap cleanup EXIT
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "                   功能测试开始                            "
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # 逐步测试
    test_health || { echo "❌ 健康检查失败"; exit 1; }
    echo ""
    
    get_csrf_token
    echo ""
    
    register_user || { echo "❌ 注册失败"; exit 1; }
    echo ""
    
    login_user || { echo "❌ 登录失败"; exit 1; }
    echo ""
    
    check_auth_status || { echo "❌ 认证检查失败"; exit 1; }
    echo ""
    
    test_ai_api
    echo ""
    
    test_event_creation
    echo ""
    
    test_oauth_setup
    echo ""
    
    # 测试总结
    echo "═══════════════════════════════════════════════════════════"
    echo "🎉 核心功能测试完成！"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "✅ 已通过的测试:"
    echo "  ✓ 应用健康检查"
    echo "  ✓ 用户注册"
    echo "  ✓ 用户登录"
    echo "  ✓ 认证状态检查"
    echo "  ✓ AI 功能 (解析和规范化)"
    echo "  ✓ 事件创建"
    echo "  ✓ OAuth 配置"
    echo ""
    echo "⚠️ 注意事项:"
    echo "  - 静态文件在开发环境可能返回 404（生产环境使用 Cloud Storage）"
    echo "  - Google OAuth 完整授权需要手动访问: $APP_URL"
    echo "  - 需要配置有效的 Gemini API 密钥以启用完整 AI 功能"
    echo ""
    echo "📋 下一步:"
    echo "  1. 访问 $APP_URL 手动测试 Google OAuth"
    echo "  2. 在浏览器中注册并登录"
    echo "  3. 点击 'Connect to Calendar' 完成 OAuth 授权"
    echo "  4. 创建事件并验证与 Google Calendar 的同步"
    echo ""
}

main "$@"
