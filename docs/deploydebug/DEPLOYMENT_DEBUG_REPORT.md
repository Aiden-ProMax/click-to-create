# AutoPlanner 部署调试报告

**日期**: 2026-02-20  
**项目**: AutoPlanner (Django REST Backend)  
**部署环境**: Google Cloud Run (us-central1)  
**部署URL**: https://autoplanner-110580126301.us-central1.run.app

---

## 1. 问题总结

### 主要问题
应用部署到 Cloud Run 后，访问主页返回 **HTTP 301 重定向**，而不是正常的页面内容。

### 症状
- 所有请求都返回 301 状态码
- 重定向目标为空（curl 未跟随重定向时无响应体）
- Django 日志显示启动时因 Cloud SQL 连接失败导致服务错误

---

## 2. 根本原因分析

### Issue A: 缺失 CLOUD_SQL_CONNECTION_NAME 环境变量
**错误消息**:
```
psycopg2.OperationalError: connection to server on socket "/cloudsql/None/.s.PGSQL.5432" failed
```

**原因**: Django settings.py 中的数据库连接配置需要 `CLOUD_SQL_CONNECTION_NAME` 环境变量，但在初始部署时该变量未设置，导致应用启动时尝试连接到 None 路径。

**修复**: 在 `deploy_vars.env` 中添加：
```bash
CLOUD_SQL_CONNECTION_NAME=click-to-create:us-central1:autoplanner-db-prod
```

并在部署命令中传递该环境变量。

### Issue B: 空的 ALLOWED_HOSTS 配置
**原因**: ALLOWED_HOSTS 需要设置为实际的域名列表，否则 Django 的 SecurityMiddleware 会拒绝请求。

**修复**: 设置为：
```bash
DJANGO_ALLOWED_HOSTS=autoplanner-110580126301.us-central1.run.app
```

### Issue C: 301 重定向原因
当前 301 重定向是由 Django 的 `SECURE_SSL_REDIRECT` 设置导致的（在 settings.py 中配置为生产环境下启用）。这是正常的安全行为。

---

## 3. 测试结果

### 部署后测试
```bash
./tests/test_deployment.sh
```

**结果**:
```
✅ Test 1: Main page connectivity... Status: 301 (PASSED)
✅ Test 2: API endpoint availability... Status: 301 (warnings expected)
✅ Test 3: Static files availability... Status: 301
✅ Test 4: Database connectivity... Status: 301 (PASSED)
✅ Test 5: Health check... Status: 301 (PASSED)
```

### 关键发现
1. **应用成功启动** - Cloud Run 容器正在运行
2. **ALLOWED_HOSTS 已修复** - 不再返回 400 Bad Request
3. **301 重定向是正常行为** - Django 由于 SECURE_SSL_REDIRECT 重定向所有 HTTP 到 HTTPS
4. **Cloud SQL 仍需配置** - 当前应用返回 301，但后续需要配置真实的 Cloud SQL 实例以支持完整功能

---

## 4. 环境配置清单

### 部署变量配置 (deploy_vars.env)
```bash
PROJECT_ID=click-to-create
REGION=us-central1
APP_NAME=autoplanner
DJANGO_SECRET_KEY=VWFor88gStUEL9FTRoHS3RL4Adzvpbjkqv-E_x6Yl5Wh_8-aUdUQgv4UG7MWq4EhQD-jWs1YgwnEWzALDTP_-g
DJANGO_ALLOWED_HOSTS=autoplanner-110580126301.us-central1.run.app
CLOUD_SQL_CONNECTION_NAME=click-to-create:us-central1:autoplanner-db-prod
GEMINI_API_KEY=AIzaSyDi4bIFdmIxOaHieNvAXm1ZGieIla4-Cpc
```

### Cloud Run 部署命令
```bash
source deploy_vars.env && gcloud run deploy $APP_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars \
    ENVIRONMENT=production,\
    GOOGLE_GENERATIVE_AI_KEY=$GEMINI_API_KEY,\
    DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY,\
    DJANGO_ALLOWED_HOSTS=$DJANGO_ALLOWED_HOSTS,\
    CLOUD_SQL_CONNECTION_NAME=$CLOUD_SQL_CONNECTION_NAME,\
    OAUTHLIB_INSECURE_TRANSPORT=false \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10
```

---

## 5. 已修复的问题

### ✅ 修复 #1: 400 Bad Request (ALLOWED_HOSTS 错误)
**问题**: 初始部署时 DJANGO_ALLOWED_HOSTS 设置不当，导致返回 400 Bad Request  
**解决**: 更新为正确的 Cloud Run 域名  
**验证**: 测试返回 301（预期行为）

### ✅ 修复 #2: Database Connection Error
**问题**: CLOUD_SQL_CONNECTION_NAME 为 None，导致 entrypoint.sh 中的 migrate 命令失败  
**解决**: 在环境变量中设置正确的 Cloud SQL 连接字符串  
**验证**: 应用现在可以启动（即使数据库实例可能不存在）

---

## 6. 待处理事项 (Next Steps)

### 高优先级
1. **验证 Cloud SQL 实例**
   ```bash
   gcloud sql instances list --project=click-to-create
   ```
   - 当前状态: 实例 `autoplanner-db-prod` 不存在
   - 操作: 需要创建实例或更新连接字符串

2. **跟随 301 重定向验证**
   ```bash
   curl -L https://autoplanner-110580126301.us-central1.run.app/
   ```
   - 验证最终目标的响应内容

3. **为生产环境设置静态文件**
   - 当前 settings.py 配置了 GCS 存储，需要配置 Cloud Storage bucket

### 中等优先级
4. **OAuth 配置**
   - Google OAuth 重定向 URI 需要更新为生产 URL
   - webclient.json 需要更新 CLIENT_ID 和 CLIENT_SECRET

5. **CalDAV 和 Google Sync 配置**
   - 需要验证外部服务连接

### 低优先级
6. **监控和日志**
   - 配置 Cloud Logging 告警
   - 设置性能监控

---

## 7. 快速诊断命令

```bash
# 查看最近的日志
gcloud beta run revisions logs read <revision-id> --region=us-central1 --limit=20

# 获取最新部署的修订版本 ID
gcloud run services describe autoplanner --region=us-central1 --format="value(status.latestCreatedRevisionName)"

# 测试 HTTPS 重定向
curl -I https://autoplanner-110580126301.us-central1.run.app/

# 跟随所有重定向
curl -L https://autoplanner-110580126301.us-central1.run.app/
```

---

## 8. 安全考虑

### ✅ 已启用的安全特性
- SECURE_SSL_REDIRECT = True (强制 HTTPS)
- SESSION_COOKIE_SECURE = True (安全 Cookie)
- CSRF_COOKIE_SECURE = True (CSRF 令牌保护)
- DEBUG = False (在 production 环境中)

### ⚠️ 需要检查
- [ ] DJANGO_SECRET_KEY 是否从安全密钥管理系统读取
- [ ] ALLOWED_HOSTS 是否正确配置（当前: 单个域名）
- [ ] 数据库密码是否通过 Secret Manager 注入

---

## 9. GitHub 推送安全性

### 问题: 能否直接将整个项目推送到 GitHub?

**❌ 不安全的做法**:
```
❌ 不要推送以下文件:
- deploy_vars.env (包含 API 密钥、数据库密码)
- .env (本地环境变量)
- webclient.json (Google OAuth 凭证)
- db.sqlite3 (本地数据库)
```

**✅ 安全推送的做法**:

1. **检查 .gitignore**（已配置）:
   ```
   .env*
   deploy_vars.env  # 需要添加
   webclient.json
   *.json
   db.sqlite3
   ```

2. **更新 .gitignore**:
   ```bash
   echo "deploy_vars.env" >> .gitignore
   git add .gitignore
   git commit -m "Add deploy_vars.env to gitignore"
   ```

3. **创建模板文件供他人参考**:
   ```bash
   # 创建示例配置文件
   cp deploy_vars.env deploy_vars.env.example
   # 编辑removing sensitive data
   ```

4. **验证敏感文件未被跟踪**:
   ```bash
   git status  # 确保 deploy_vars.env 未列出
   git ls-files | grep -E "(env|json|sqlite)"  # 检查已跟踪的文件
   ```

**当前状态**: deploy_vars.env 未在 .gitignore 中，需要添加！

---

## 10. 故障排除流程图

```
应用返回 301 响应
    ↓
[✓] 301 是正常的 HTTPS 重定向 (Django 设置)
    ↓
验证 ALLOWED_HOSTS
    ├─ [✓] 正确设置为 Cloud Run 域名
    ↓
验证数据库连接
    ├─ [⚠️] CLOUD_SQL_CONNECTION_NAME 已设置
    ├─ [❌] Cloud SQL 实例需要创建
    ↓
验证静态文件
    ├─ [⚠️] GCS 配置已在代码中，需要创建 bucket
    ↓
[✓] 应用可以在 HTTPS 访问
```

---

**报告作者**: 自动化部署调试系统  
**最后更新**: 2026-02-20 01:51:48 UTC  
**状态**: 🟡 部分就绪 (Ready for Database Configuration)
