# AutoPlanner 部署调试报告 (完整版)

**日期**: 2026-02-20  
**项目**: AutoPlanner (Django REST Backend)  
**部署环境**: Google Cloud Run (us-central1)  
**部署URL**: https://autoplanner-110580126301.us-central1.run.app  
**实际服务URL**: https://autoplanner-aw36pbwf6a-uc.a.run.app  

---

## 问题分析

### 现象
- 访问主页返回 **HTTP 400 Bad Request** (使用自动生成的短 URL)
- 使用正确的 Host Header 访问时返回 **HTTP 301 重定向** (预期行为)
- 重定向目标: `https://autoplanner-110580126301.us-central1.run.app/`

### 问题根源

#### 问题 1: Cloud Run 自动分配的短 URL 不匹配 ALLOWED_HOSTS
**现象**: 使用 `https://autoplanner-aw36pbwf6a-uc.a.run.app/` 访问返回 400
```
HTTP/2 400 
Bad Request (400) - Host header does not match ALLOWED_HOSTS
```

**原因**: 
- Cloud Run 自动分配了短 URL: `autoplanner-aw36pbwf6a-uc.a.run.app`
- Django 配置的 ALLOWED_HOSTS 为完整地址: `autoplanner-110580126301.us-central1.run.app`
- Django SecurityMiddleware 拒绝了来自未授权 Host 的请求

**解决方案**:
```python
# 方案 A: 更新 ALLOWED_HOSTS 包含两个地址 (推荐)
DJANGO_ALLOWED_HOSTS=autoplanner-110580126301.us-central1.run.app,autoplanner-aw36pbwf6a-uc.a.run.app

# 方案 B: 使用通配符 (生产环境不推荐)
DJANGO_ALLOWED_HOSTS=*.run.app
```

#### 问题 2: 301 重定向是预期的 HTTPS 跳转
**现象**: 使用正确 Host header 访问时返回 301 重定向
```
HTTP/2 301 
location: https://autoplanner-110580126301.us-central1.run.app/
```

**原因**: Django 的 `SECURE_SSL_REDIRECT = True` 在生产环境启用，重定向所有流量到首选域名

**这是正常现象** ✅ - 不需要修复

---

## 修复步骤

### 步骤 1: 更新 ALLOWED_HOSTS
编辑 `deploy_vars.env`:
```bash
DJANGO_ALLOWED_HOSTS=autoplanner-110580126301.us-central1.run.app,autoplanner-aw36pbwf6a-uc.a.run.app
```

### 步骤 2: 重新部署
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
  --max-instances=10 \
  --quiet
```

### 步骤 3: 验证部署
```bash
# 测试短 URL
curl -I https://autoplanner-aw36pbwf6a-uc.a.run.app/
# 应该返回 301 (重定向)

# 测试完整 URL
curl -I https://autoplanner-110580126301.us-central1.run.app/
# 应该返回 301 或 200

# 跟随重定向进行端到端测试
curl -L https://autoplanner-aw36pbwf6a-uc.a.run.app/ | head -30
```

---

## 部署状态总结

| 项目 | 状态 | 详情 |
|------|------|------|
| **Cloud Run 服务** | ✅ | 正在运行，最新修订: `autoplanner-00008-nc7` |
| **HTTPS 连接** | ✅ | SSL/TLS 工作正常 |
| **ALLOWED_HOSTS** | ⚠️ | 需要包含短 URL: `autoplanner-aw36pbwf6a-uc.a.run.app` |
| **Cloud SQL 连接字符串** | ✅ | 已正确设置: `click-to-create:us-central1:autoplanner-db-prod` |
| **Cloud SQL 实例** | ❌ | 实例未创建（可选，取决于是否需要数据库） |
| **静态文件** | ⚠️ | GCS 配置已就位，需要创建 bucket 和上传文件 |
| **敏感数据保护** | ✅ | `deploy_vars.env` 已在 `.gitignore` 中 |

---

## 快速参考

### 当前部署信息
```bash
# 从 deploy_vars.env 读取
PROJECT_ID=click-to-create
REGION=us-central1
APP_NAME=autoplanner
DJANGO_ALLOWED_HOSTS=autoplanner-110580126301.us-central1.run.app,autoplanner-aw36pbwf6a-uc.a.run.app
CLOUD_SQL_CONNECTION_NAME=click-to-create:us-central1:autoplanner-db-prod
```

### 常用命令
```bash
# 查看服务状态
gcloud run services describe autoplanner --region=us-central1

# 查看最新部署日志
gcloud beta run revisions logs read autoplanner-00008-nc7 --region=us-central1 --limit=20

# 测试端点（带跟随重定向）
curl -L https://autoplanner-aw36pbwf6a-uc.a.run.app/

# 运行调试脚本
./tests/debug_deployment.sh

# 运行测试套件
./tests/test_deployment.sh
```

### 下一步操作

#### 如果需要完整数据库功能:
1. 创建 Cloud SQL 实例:
   ```bash
   gcloud sql instances create autoplanner-db-prod \
     --database-version=POSTGRES_15 \
     --region=us-central1 \
     --tier=db-f1-micro
   ```

2. 创建数据库和用户 (使用云 SQL 代理访问)

3. 设置 Cloud SQL 代理连接 (Cloud Run 需要)

#### 如果需要静态文件:
1. 创建 GCS bucket:
   ```bash
   gsutil mb gs://autoplanner-static
   ```

2. 运行 `collectstatic` 并上传到 GCS

3. 配置 bucket 权限

#### GitHub 推送安全性检查清单:
- [x] `deploy_vars.env` 在 `.gitignore` 中
- [x] `.env` 文件被忽略
- [x] `webclient.json` (OAuth 凭证) 被忽略  
- [x] `db.sqlite3` 被忽略
- [x] 创建了 `deploy_vars.env.example` 作为模板
- [ ] 验证 `git ls-files` 中没有敏感文件

---

## 测试脚本

### 部署完整测试
```bash
# 基础测试 (端点连接检查)
./tests/test_deployment.sh

# 完整诊断 (包括环境变量、GCP 资源检查)
./tests/debug_deployment.sh
```

---

## 常见错误及解决方案

| 错误 | 原因 | 解决方案 |
|------|------|--------|
| **400 Bad Request** | Host header 不在 ALLOWED_HOSTS | 添加使用的 URL 到 ALLOWED_HOSTS |
| **psycopg2.OperationalError** | Cloud SQL 连接失败 | 创建实例或配置 Cloud SQL 代理 |
| **500 Internal Server Error** | 数据库迁移失败或缺少表 | 运行 `python manage.py migrate` |
| **Static files 404** | 静态文件未收集 | 配置 GCS 或运行 `collectstatic` |

---

## 安全检查 ✅

### 环境配置
- [x] DJANGO_SECRET_KEY 已设置
- [x] DEBUG = false (生产环境)
- [x] SECURE_SSL_REDIRECT = true
- [x] SESSION_COOKIE_SECURE = true
- [x] CSRF_COOKIE_SECURE = true

### 代码库安全  
- [x] 敏感文件在 .gitignore
- [x] API 密钥不在源代码中
- [x] 数据库密码通过环境变量传递
- [x] 示例配置文件已创建

### 待改进
- [ ] 将密钥迁移到 Google Secret Manager
- [ ] 配置 Cloud Armor 防火墙规则
- [ ] 启用 Cloud Monitoring 告警

---

**报告生成时间**: 2026-02-20 02:26:40 UTC  
**最后测试**: 2026-02-20 02:27:02 UTC  
**状态**: 🟡 部分就绪 (待 ALLOWED_HOSTS 更新)
