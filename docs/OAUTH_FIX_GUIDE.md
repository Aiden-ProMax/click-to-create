# 🔧 OAuth redirect_uri 修复指南

## 问题诊断 ✅ 已解决

**错误**: `Error 400: redirect_uri_mismatch`

**根本原因**:
- 代码中使用的 redirect_uri 与 Google OAuth 应用配置不匹配
- 生产环境未设置正确的 `GOOGLE_OAUTH_REDIRECT_URI` 环境变量

---

## 已完成的修复

### ✅ 部署环境已更新

生产环境的 redirect_uri 现已设置为：
```
https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback
```

应用已重新部署，环境变量已更新。✅

---

## 🔴 还需要的一步：更新 Google OAuth 应用配置

现在需要在 Google Cloud Console 中告诉 Google OAuth 应用接受这个 redirect_uri。

### 操作步骤：

1. **打开 Google Cloud Console OAuth 凭证**
   - 访问：https://console.cloud.google.com/apis/credentials
   - 或在 GCP Console 中：
     1. 左侧菜单 → "API 和服务" (APIs & Services)
     2. 点击 "凭证" (Credentials)

2. **找到你的 OAuth 2.0 客户端**
   - 在 "OAuth 2.0 客户端 ID" 部分找到名为 "Web application" 的应用
   - 应该显示 Client ID: `110580126301-numum3bhq595fc4pnse3a7lgj24ua00s.apps.googleusercontent.com`

3. **编辑 OAuth 应用**
   - 点击该条目打开编辑窗口

4. **添加新的授权重定向 URI**
   - 找到 "授权的重定向 URI" (Authorized redirect URIs) 部分
   - 添加以下地址：
   ```
   https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback
   ```
   - 如果存在旧的本地地址（如 `http://localhost:8000/oauth/google/callback`），可以保留它用于本地开发

5. **保存更改**
   - 点击 **保存** (Save) 按钮

---

## 🧪 验证修复

完成上述步骤后，测试 OAuth 连接：

1. 访问你的应用：https://clickcreate-110580126301.us-west1.run.app
2. 登录到应用
3. 点击 **Connect to Google Calendar**
4. 应该可以看到 Google OAuth 登录界面而不是 redirect_uri_mismatch 错误

---

## 📋 快速参考

| 项目 | 值 |
|------|-----|
| 应用 URL | https://clickcreate-110580126301.us-west1.run.app |
| OAuth Redirect URI | https://clickcreate-110580126301.us-west1.run.app/oauth/google/callback |
| Google Project ID | click-to-create |
| Client ID | 110580126301-numum3bhq595fc4pnse3a7lgj24ua00s.apps.googleusercontent.com |

---

## 💡 故障排查

如果修复后仍然出现问题：

1. **清除浏览器缓存**
   - 清除所有 cookies 和缓存数据

2. **检查 Google Console 是否已保存**
   - 再次打开凭证页面，确认新的 redirect_uri 已保存

3. **等待缓存更新**
   - Google 可能需要几分钟来更新配置

4. **查看日志**
   - 在 Google Cloud Console 中查看 Cloud Run 日志：
   ```bash
   gcloud run logs read clickcreate --region us-west1 --limit 50
   ```

---

## 🔐 安全提示

在本地开发时，可以添加额外的 redirect_uri：
- `http://localhost:8000/oauth/google/callback` - 本地开发
- `http://127.0.0.1:8000/oauth/google/callback` - 可选

这样可以支持本地开发和生产环境。

---

**完成日期**: 2026-02-20
**状态**: ✅ 代码和部署已修复，等待 Google Console 配置更新
