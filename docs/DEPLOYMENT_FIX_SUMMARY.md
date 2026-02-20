# 🔧 部署问题修复总结

**完成日期**: 2026-02-20

## 已解决的问题

### 1️⃣ OAuth redirect_uri_mismatch 错误 ✅

**问题**: `Error 400: redirect_uri_mismatch`

**原因**: 生产环境的 redirect_uri 与 Google OAuth 应用配置不匹配

**解决方案**:
- ✅ 更新部署脚本，添加 `GOOGLE_OAUTH_REDIRECT_URI` 环境变量
- ✅ 需要在 Google Cloud Console 添加授权重定向 URI:
  ```
  https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback
  ```

**验证方法**:
- 访问应用，登录后点击 "Connect to Google Calendar"
- 应该显示 Google 登录界面而不是 redirect_uri_mismatch 错误

---

### 2️⃣ GOOGLE_GENERATIVE_AI_KEY 配置错误 ✅

**问题**: `GOOGLE_GENERATIVE_AI_KEY is not configured`

**原因**: 生产环境部分环境变量缺失

**解决方案**:
- ✅ 使用 `--env-vars-file` 部署，确保所有环境变量完整
- ✅ 包含 Gemini API 密钥: `AIzaSyDi4bIFdmIxOaHieNvAXm1ZGieIla4-Cpc`

**验证方法**:
- 创建新事件时使用自然语言，应该能成功解析

---

## 当前部署配置 ✅

**应用 URL**: https://clickcreate-110580126301.us-west1.run.app

**Cloud Run 版本**: clickcreate-00004-fnh

**已配置环境变量**:
```yaml
ENVIRONMENT: production
GOOGLE_GENERATIVE_AI_KEY: AIzaSyDi4bIFdmIxOaHieNvAXm1ZGieIla4-Cpc ✅
GOOGLE_OAUTH_CLIENT_JSON: (Google OAuth credentials) ✅
GOOGLE_OAUTH_REDIRECT_URI: https://clickcreate-...up.app/oauth/google/callback ✅
DJANGO_SECRET_KEY: (Configured) ✅
DJANGO_ALLOWED_HOSTS: clickcreate-110580126301.us-west1.run.app ✅
OAUTHLIB_INSECURE_TRANSPORT: false ✅
Cloud SQL: click-to-create:us-west1:autoplanner-db-prod-uswest ✅
```

---

## 待办事项 📋

### 🔴 重要：在 Google Cloud Console 中完成以下操作

1. **访问**: https://console.cloud.google.com/apis/credentials
2. **编辑** Web Application OAuth 客户端
3. **添加** 授权重定向 URI:
   ```
   https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback
   ```
4. **保存** 更改

这是 OAuth 功能工作的最后一步！

---

## 快速部署命令

如果需要重新部署，使用 `deploy_with_oauth.sh` 脚本：

```bash
cd /Users/jiaoyan/AutoPlanner
chmod +x deploy_with_oauth.sh
./deploy_with_oauth.sh
```

或手动部署：

```bash
source deploy_vars.env
gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated \
  --env-vars-file /path/to/env.yaml \
  --timeout=3600 \
  --memory=512Mi \
  --max-instances=10
```

---

## 关键学习 💡

1. **使用 `--env-vars-file` 而不是 `--set-env-vars` 或 `--update-env-vars`**
   - `--update-env-vars` 只更新指定变量，其他变量被保留
   - 大规模部署应使用完整的配置文件

2. **生产环境 vs 本地开发**
   - 本地开发可以保留: `http://localhost:8000/oauth/google/callback`
   - 生产环境需要: `https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback`

3. **验证部署的环境变量**
   ```bash
   gcloud run services describe clickcreate --region us-west1 \
     --format='value(spec.template.spec.containers[0].env)'
   ```

---

## 相关文档

- [OAUTH_FIX_GUIDE.md](OAUTH_FIX_GUIDE.md) - OAuth 修复详细指南
- [Log.md](Log.md) - 完整日志记录
- [deploy_with_oauth.sh](../deploy_with_oauth.sh) - 完整部署脚本

---

**状态**: ✅ 代码和部署配置完成
**下一步**: 在 Google Cloud Console 中完成 OAuth redirect_uri 配置
