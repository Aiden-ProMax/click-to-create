#!/bin/bash
# 完整的部署调试脚本
# 用于诊断部署问题、验证配置、运行测试

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 辅助函数
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 加载部署变量
if [ ! -f "deploy_vars.env" ]; then
    print_error "deploy_vars.env not found. Copy deploy_vars.env.example and fill in your values."
    echo "  cp deploy_vars.env.example deploy_vars.env"
    exit 1
fi

source deploy_vars.env

print_header "AutoPlanner Deployment Debugger"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "App Name: $APP_NAME"
echo "Timestamp: $(date)"
echo ""

# 检查 1: 验证 gcloud 工具
print_header "1. Checking gcloud Setup"
if command -v gcloud &> /dev/null; then
    print_success "gcloud CLI installed"
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "none")
    echo "  Current project: $CURRENT_PROJECT"
else
    print_error "gcloud CLI not found"
    exit 1
fi
echo ""

# 检查 2: 验证部署变量
print_header "2. Checking Deployment Variables"
vars=("PROJECT_ID" "REGION" "APP_NAME" "DJANGO_SECRET_KEY" "DJANGO_ALLOWED_HOSTS" "GEMINI_API_KEY")
for var in "${vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "$var is not set"
    else
        val="${!var}"
        # 隐藏敏感信息
        if [[ "$var" == *"KEY"* ]] || [[ "$var" == *"PASSWORD"* ]] || [[ "$var" == *"SECRET"* ]]; then
            val="${val:0:5}...${val: -5}"
        fi
        print_success "$var = $val"
    fi
done
echo ""

# 检查 3: 验证 Cloud SQL 实例
print_header "3. Checking Cloud SQL Instance"
if gcloud sql instances list --project=$PROJECT_ID | grep -q $DB_INSTANCE; then
    print_success "Cloud SQL instance '$DB_INSTANCE' exists"
else
    print_warning "Cloud SQL instance '$DB_INSTANCE' not found"
    echo "  To create it, run:"
    echo "    gcloud sql instances create $DB_INSTANCE \\"
    echo "      --database-version=POSTGRES_15 \\"
    echo "      --region=$REGION \\"
    echo "      --tier=db-f1-micro"
fi
echo ""

# 检查 4: 获取当前部署状态
print_header "4. Checking Cloud Run Service"
if gcloud run services describe $APP_NAME --region=$REGION --project=$PROJECT_ID &>/dev/null; then
    print_success "Cloud Run service '$APP_NAME' exists"
    
    SERVICE_URL=$(gcloud run services describe $APP_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="value(status.url)" 2>/dev/null || echo "unknown")
    echo "  Service URL: $SERVICE_URL"
    
    LATEST_REVISION=$(gcloud run services describe $APP_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="value(status.latestCreatedRevisionName)" 2>/dev/null || echo "unknown")
    echo "  Latest Revision: $LATEST_REVISION"
else
    print_warning "Cloud Run service '$APP_NAME' not found"
fi
echo ""

# 检查 5: 测试端点连接
print_header "5. Testing Endpoint Connectivity"
if [ ! -z "$SERVICE_URL" ] && [ "$SERVICE_URL" != "unknown" ]; then
    echo "Testing: $SERVICE_URL"
    echo ""
    
    # 主页测试
    MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/")
    echo "GET / → Status: $MAIN_STATUS"
    if [ "$MAIN_STATUS" = "301" ] || [ "$MAIN_STATUS" = "200" ]; then
        print_success "Main page responsive"
    else
        print_warning "Unexpected status code"
    fi
    
    # API 测试
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/api/events/")
    echo "GET /api/events/ → Status: $API_STATUS"
    
    # 管理员面板测试
    ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/admin/")
    echo "GET /admin/ → Status: $ADMIN_STATUS"
else
    print_error "SERVICE_URL not available for testing"
fi
echo ""

# 检查 6: 查看最近日志
print_header "6. Recent Cloud Run Logs (last 10 lines)"
if [ ! -z "$LATEST_REVISION" ] && [ "$LATEST_REVISION" != "unknown" ]; then
    echo "Fetching logs from revision: $LATEST_REVISION"
    echo "---"
    gcloud beta run revisions logs read $LATEST_REVISION \
        --region=$REGION \
        --project=$PROJECT_ID \
        --limit=10 2>/dev/null || echo "Failed to fetch logs"
    echo "---"
else
    print_warning "Cannot fetch logs (revision unknown)"
fi
echo ""

# 检查 7: 环境变量验证
print_header "7. Environment Variables Validation"
echo "Variables that will be passed to Cloud Run:"
echo "  ENVIRONMENT=production"
echo "  DJANGO_ALLOWED_HOSTS=$DJANGO_ALLOWED_HOSTS"
echo "  OAUTHLIB_INSECURE_TRANSPORT=false"
if [ ! -z "$CLOUD_SQL_CONNECTION_NAME" ]; then
    echo "  CLOUD_SQL_CONNECTION_NAME=$CLOUD_SQL_CONNECTION_NAME"
    print_success "Cloud SQL connection name is set"
else
    print_warning "CLOUD_SQL_CONNECTION_NAME not set (required for database access)"
fi
echo ""

# 检查 8: 文件和依赖验证
print_header "8. Checking Required Files"
files=("Dockerfile" "entrypoint.sh" "requirements.txt" "autoplanner/settings.py")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file not found"
    fi
done
echo ""

# 检查 9: 敏感数据检查
print_header "9. Sensitive Data Security Check"
if grep -q "deploy_vars.env" .gitignore 2>/dev/null; then
    print_success "deploy_vars.env is in .gitignore"
else
    print_warning "deploy_vars.env not in .gitignore - add it: echo 'deploy_vars.env' >> .gitignore"
fi

if [ -f ".env" ]; then
    print_warning ".env file exists locally - ensure it's in .gitignore"
fi

if [ -f "webclient.json" ]; then
    print_warning "webclient.json (Google OAuth) should be in .gitignore"
fi
echo ""

print_header "Debugging Summary"
echo "1. Review logs: gcloud beta run revisions logs read $LATEST_REVISION --region=$REGION --limit=50"
echo "2. Test endpoint: curl -I $SERVICE_URL/"
echo "3. View traces: gcloud trace list --project=$PROJECT_ID"
echo "4. Redeploy: source deploy_vars.env && ./tests/deploy.sh"
echo ""
print_success "Debugging complete!"
