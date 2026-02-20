#!/bin/bash

# AutoPlanner 自动测试脚本
# 测试 OAuth、AI API 和核心功能

set -e

echo "🚀 开始 AutoPlanner 自动化测试"

# 配置变量
APP_URL="${APP_URL:-http://localhost:8000}"
TEST_USER="testuser_$(date +%s)"
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"

echo "📋 测试配置:"
echo "  APP_URL: $APP_URL"
echo "  TEST_USER: $TEST_USER"
echo "  TEST_EMAIL: $TEST_EMAIL"

# 函数：获取 CSRF token
get_csrf_token() {
    echo "🔑 获取 CSRF token..."
    CSRF_RESPONSE=$(curl -s -c cookies.txt "$APP_URL/api/auth/csrf/")
    CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['csrfToken'])")
    echo "  CSRF Token: ${CSRF_TOKEN:0:20}..."
}

# 函数：注册用户
register_user() {
    echo "👤 注册测试用户..."
    REGISTER_RESPONSE=$(curl -s -b cookies.txt -c cookies.txt \
        -X POST "$APP_URL/api/auth/register/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d "{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

    if echo "$REGISTER_RESPONSE" | grep -q "username"; then
        echo "  ✅ 用户注册成功"
    else
        echo "  ❌ 用户注册失败: $REGISTER_RESPONSE"
        exit 1
    fi
}

# 函数：登录
login_user() {
    echo "🔐 用户登录..."
    LOGIN_RESPONSE=$(curl -s -b cookies.txt -c cookies.txt \
        -X POST "$APP_URL/api/auth/login/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}")

    if echo "$LOGIN_RESPONSE" | grep -q "ok"; then
        echo "  ✅ 登录成功"
    else
        echo "  ❌ 登录失败: $LOGIN_RESPONSE"
        exit 1
    fi
}

# 函数：测试 AI 规范化
test_ai_normalize() {
    echo "🤖 测试 AI 事件规范化..."
    NORMALIZE_RESPONSE=$(curl -s -b cookies.txt \
        -X POST "$APP_URL/api/ai/normalize/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d '{
            "events": [{
                "title": "测试会议",
                "date": "tomorrow",
                "start_time": "14:00",
                "duration": "1.5h",
                "location": "会议室A",
                "category": "meeting"
            }]
        }')

    if echo "$NORMALIZE_RESPONSE" | grep -q '"ok":true'; then
        echo "  ✅ AI 规范化成功"
    else
        echo "  ❌ AI 规范化失败: $NORMALIZE_RESPONSE"
        exit 1
    fi
}

# 函数：测试事件调度
test_event_schedule() {
    echo "📅 测试事件调度..."
    SCHEDULE_RESPONSE=$(curl -s -b cookies.txt \
        -X POST "$APP_URL/api/ai/schedule/" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: $CSRF_TOKEN" \
        -d '{
            "events": [{
                "title": "测试会议",
                "start_datetime": "2026-02-20T14:00:00+08:00",
                "end_datetime": "2026-02-20T15:30:00+08:00",
                "location": "会议室A",
                "description": "自动化测试会议"
            }]
        }')

    if echo "$SCHEDULE_RESPONSE" | grep -q '"ok":true'; then
        echo "  ✅ 事件调度成功"
        EVENT_ID=$(echo "$SCHEDULE_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('event_ids', [None])[0])")
        echo "  📝 创建的事件 ID: $EVENT_ID"
    else
        echo "  ❌ 事件调度失败: $SCHEDULE_RESPONSE"
        exit 1
    fi
}

# 函数：测试用户认证状态
test_auth_status() {
    echo "👤 检查认证状态..."
    AUTH_RESPONSE=$(curl -s -b cookies.txt "$APP_URL/api/auth/me/")

    if echo "$AUTH_RESPONSE" | grep -q "$TEST_USER"; then
        echo "  ✅ 用户已认证"
    else
        echo "  ❌ 用户未认证: $AUTH_RESPONSE"
        exit 1
    fi
}

# 函数：测试健康检查
test_health() {
    echo "💚 健康检查..."
    # 测试首页而不是 /health/ 端点
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/")

    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo "  ✅ 应用健康 (HTTP $HEALTH_RESPONSE)"
    else
        echo "  ❌ 应用不健康: HTTP $HEALTH_RESPONSE"
        exit 1
    fi
}

# 函数：测试静态文件
test_static_files() {
    echo "📄 测试静态文件..."
    STATIC_RESPONSE=$(curl -s -I "$APP_URL/static/css/style.css")

    if echo "$STATIC_RESPONSE" | grep -q "200 OK"; then
        echo "  ✅ 静态文件正常"
    else
        echo "  ⚠️ 静态文件可能有问题: $(echo "$STATIC_RESPONSE" | head -1)"
    fi
}

# 函数：清理测试数据
cleanup() {
    echo "🧹 清理测试数据..."
    # 这里可以添加清理逻辑，如果需要
    rm -f cookies.txt
    echo "  ✅ 清理完成"
}

# 主测试流程
main() {
    echo "🧪 开始功能测试..."

    # 健康检查
    test_health

    # 静态文件检查
    test_static_files

    # 获取 CSRF token
    get_csrf_token

    # 用户注册和登录
    register_user
    login_user

    # 认证状态检查
    test_auth_status

    # AI 功能测试
    test_ai_normalize
    test_event_schedule

    echo ""
    echo "🎉 所有测试通过！"
    echo ""
    echo "📊 测试总结:"
    echo "  ✅ 应用健康检查"
    echo "  ✅ 用户注册"
    echo "  ✅ 用户登录"
    echo "  ✅ AI 事件规范化"
    echo "  ✅ 事件调度"
    echo "  ✅ 认证状态"
    echo ""
    echo "⚠️ 注意: Google Calendar 同步测试需要手动 OAuth 授权"
    echo "   请访问: $APP_URL"
    echo "   1. 注册/登录"
    echo "   2. 点击 'Connect to Calendar'"
    echo "   3. 完成 Google OAuth 授权"

    # 清理
    cleanup
}

# 错误处理
trap cleanup EXIT

# 运行测试
main "$@"