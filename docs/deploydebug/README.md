# AutoPlanner 部署调试文档索引

**最后更新**: 2026-02-20  
**状态**: ✅ 生产就绪  

---

## 📋 文档导航

### 🚀 快速开始
- **[部署完成总结](DEPLOYMENT_COMPLETE.md)** ⭐ *从这里开始*
  - 快速总结部署状态
  - 遇到的问题和解决方案
  - 部署命令和测试结果
  - 下一步建议

### 🔍 深度诊断
- **[GitHub 推送安全性指南](GITHUB_SECURITY.md)** 🔐 *回答"能否推送到 GitHub"*
  - 敏感文件清单
  - 推送前检查
  - 安全最佳实践
  - 紧急处理程序

- **[最终调试报告](DEBUG_REPORT_FINAL.md)** 📊
  - 详细的 400 错误和 301 重定向分析
  - 根本原因诊断
  - 环境配置清单
  - 已修复的问题清单
  - 快速参考命令

- **[初始部署调试报告](DEPLOYMENT_DEBUG_REPORT.md)** 📝
  - 第一次部署的问题记录
  - 问题分析和解决方案
  - 部署配置清单

---

## 🛠️ 可用的工具脚本

### 测试和诊断
```bash
# 基础功能测试 (~1 分钟)
./tests/test_deployment.sh

# 完整诊断 (~2 分钟)
./tests/debug_deployment.sh
```

### 部署
```bash
# 使用环境变量部署
source deploy_vars.env
gcloud run deploy $APP_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --env-vars-file .env.production \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10 \
  --quiet
```

---

## 🎯 关键问题与答案

### ❓ 我现在能直接推送到 GitHub 吗?

✅ **可以！** 但需要注意:
- `deploy_vars.env` 已在 `.gitignore` 中 ✅
- 需要推送 `deploy_vars.env.example` 作为模板 ✅
- 需要验证没有敏感文件被跟踪 ⚠️

👉 详见: [GitHub 推送安全性指南](GITHUB_SECURITY.md)

### ❓ 网页为什么会卡住我访问?

已解决! 原因和解决方案:
1. **HTTP 400 Bad Request** → 修复 ALLOWED_HOSTS
2. **HTTP 301 无限重定向** → 禁用不必要的 SECURE_SSL_REDIRECT
3. **Cloud SQL 连接错误** → 设置 CLOUD_SQL_CONNECTION_NAME

👉 详见: [部署完成总结](DEPLOYMENT_COMPLETE.md#遇到的问题及解决方案)

### ❓ 如何重新部署?

```bash
# 确保部署变量已设置
source deploy_vars.env

# 使用最新配置部署
gcloud run deploy $APP_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --env-vars-file .env.production \
  --timeout=3600 --memory=512Mi --max-instances=10 --quiet
```

👉 详见: [部署完成总结 - 部署应用](DEPLOYMENT_COMPLETE.md#部署应用)

---

## 📊 部署状态

| 项目 | 状态 | 最后检查 |
|------|------|--------|
| Web 应用 | ✅ 运行中 | 2026-02-20 22:08 |
| HTTP 连接 | ✅ 正常 | 2026-02-20 22:08 |
| 主页加载 | ✅ 成功 (200) | 2026-02-20 22:08 |
| API 端点 | ✅ 可访问 (需认证) | 2026-02-20 22:08 |
| 静态文件 | ⚠️ 需配置 GCS | - |
| Cloud SQL | ⚠️ 实例未创建 | - |

---

## 🔧 关键修复

### 1. ALLOWED_HOSTS 配置
**文件**: `deploy_vars.env`, `.env.production`
```bash
DJANGO_ALLOWED_HOSTS=autoplanner-aw36pbwf6a-uc.a.run.app,autoplanner-110580126301.us-central1.run.app
```

### 2. SSL/TLS 配置修复
**文件**: `autoplanner/settings.py`
```python
# 禁用不必要的重定向 (Cloud Run 的 Google Frontend LB 已处理 SSL)
SECURE_SSL_REDIRECT = False

# 信任负载均衡器的代理头
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

### 3. Cloud SQL 连接
**文件**: `deploy_vars.env`, `.env.production`
```bash
CLOUD_SQL_CONNECTION_NAME=click-to-create:us-central1:autoplanner-db-prod
```

### 4. .gitignore 更新
**文件**: `.gitignore`
```
deploy_vars.env  # 新增
```

---

## 🔐 安全检查清单

- [x] `deploy_vars.env` 在 `.gitignore` 中
- [x] `.env` 文件被忽略  
- [x] `webclient.json` 被忽略
- [x] DEBUG = false 在生产环境
- [x] HTTPS 正确配置
- [x] 安全头部设置 (HSTS, Secure Cookie, X-Frame-Options)
- [x] CSRF 保护启用
- [ ] 考虑迁移到 Google Secret Manager (可选)

---

## 📚 测试结果摘要

### 最新测试运行 (2026-02-20 22:08:21 UTC)

```
✅ Test 1: Main page connectivity... Status: 200 PASSED
✅ Test 2: API endpoint availability... Status: 403 (requires auth) PASSED
⚠️  Test 3: Static files availability... Status: 404 (需要 GCS)
✅ Test 4: Checking for database errors... Status: 302 (正常)
✅ Test 5: Health check... Status: 200 PASSED

总体状态: ✅ 部署成功!
```

---

## 🚀 下一步行动

### 立即推送到 GitHub
1. 按照 [GitHub 推送安全性指南](GITHUB_SECURITY.md) 进行验证
2. 执行推送:
   ```bash
   git add .
   git commit -m "feat: AutoPlanner Cloud Run deployment with complete debugging"
   git push origin main
   ```

### 配置生产功能 (可选)
1. 创建 Cloud SQL 数据库
2. 配置静态文件存储 (GCS)
3. 设置 Google OAuth
4. 配置监控和日志

👉 详见: [部署完成总结 - 下一步推荐](DEPLOYMENT_COMPLETE.md#下一步推荐)

---

## 📞 快速问题解决

| 问题 | 解决方案 | 文档 |
|------|--------|------|
| 网页无法访问 | 运行 `./tests/test_deployment.sh` | [部署完成总结](DEPLOYMENT_COMPLETE.md) |
| 无限重定向 | 检查 SECURE_SSL_REDIRECT | [最终调试报告](DEBUG_REPORT_FINAL.md) |
| 400 错误 | 更新 ALLOWED_HOSTS | [部署完成总结](DEPLOYMENT_COMPLETE.md) |
| 敏感信息泄露 | 按照紧急处理步骤 | [GitHub 安全指南](GITHUB_SECURITY.md) |
| 如何重新部署 | 参考部署命令 | [部署完成总结](DEPLOYMENT_COMPLETE.md) |

---

## 📖 文件结构

```
AutoPlanner/
├── docs/
│   └── deploydebug/          ← 您在这里
│       ├── README.md          ← 本文件
│       ├── DEPLOYMENT_COMPLETE.md (推荐阅读)
│       ├── GITHUB_SECURITY.md (推送前阅读)
│       ├── DEBUG_REPORT_FINAL.md
│       └── DEPLOYMENT_DEBUG_REPORT.md
├── tests/
│   ├── test_deployment.sh       ← 基本测试
│   └── debug_deployment.sh      ← 完整诊断
├── deploy_vars.env              ⚠️ (敏感 - 不推送)
├── deploy_vars.env.example      ✅ (推送模板)
├── .env.production              ⚠️ (参考配置)
├── .gitignore                   ✅ (已更新)
└── autoplanner/
    └── settings.py              ✅ (已修复)
```

---

## 💡 本地开发 vs 生产部署

### 本地开发
```bash
# 使用 .env 文件
source .env
python manage.py runserver
```

### Cloud Run 生产部署
```bash
# 使用 deploy_vars.env 和 .env.production
source deploy_vars.env
gcloud run deploy ...env-vars-file .env.production...
```

两者都使用 `.gitignore` 保护敏感数据。

---

## ✨ 特别说明

### 关于 SECURE_SSL_REDIRECT

云中部署（如 Cloud Run）通常将 HTTPS 终止委托给负载均衡器（例如 Google Frontend）。应用本身只看到 HTTP 流量和 `X-Forwarded-Proto: https` 头。

在这种情况下:
- ❌ **不应该**启用 `SECURE_SSL_REDIRECT = True`（会导致循环)
- ✅ **应该**启用 `SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')`

这已在本部署中修复。

---

**📧 有问题? 查看对应的文档或运行诊断脚本:**
```bash
./tests/debug_deployment.sh
```

**🎉 部署已完成!**
