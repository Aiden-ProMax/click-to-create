# 🚀 AutoPlanner 部署完整指南

**完成日期**: 2026年2月19-20日
**状态**: ✅ 准备就绪

## 📊 现状总结

### ✅ 已完成

1. **开发环境设置**
   - ✅ gcloud CLI 安装和认证
   - ✅ Python 虚拟环境配置
   - ✅ 所有依赖包安装
   - ✅ SQLite 本地数据库配置

2. **自动化测试**
   - ✅ 用户注册/登录功能
   - ✅ 认证系统
   - ✅ AI 事件规范化
   - ✅ 事件创建和存储
   - ✅ OAuth 配置验证

3. **云基础设施准备**
   - ✅ Google Cloud 项目配置 (click-to-create)
   - ✅ gcloud 认证完成
   - ✅ 所有必要文件准备完毕

4. **关键配置文件**
   - ✅ webclient.json (Google OAuth)
   - ✅ deploy_vars.env (部署变量)
   - ✅ 自动化脚本已准备

## ⚠️ 待办事项（优先顺序）

### 🔴 第1步：启用项目计费（必需）

**为什么**: Google Cloud Run 和 Cloud SQL 都需要计费账户

**如何操作**:
1. 访问 https://console.cloud.google.com/billing
2. 在左侧菜单选择 "Billing" (计费)
3. 选择项目 "Click-To-Create"
4. 添加支付方式（信用卡）
5. 启用计费
6. 等待 5-10 分钟生效

**验证方法**:
```bash
gcloud billing projects describe click-to-create
```

---

### 🟡 第2步：运行自动化部署脚本

一旦计费启用，运行：

```bash
cd /Users/jiaoyan/AutoPlanner
./deploy_to_cloud.sh
```

脚本将自动执行：
- 启用必要的 APIs
- 创建 Cloud SQL 数据库
- 配置 Secret Manager
- 创建 Service Account
- 部署应用到 Cloud Run

**预期耗时**: 8-12 分钟（其中 Cloud SQL 创建需要 3-5 分钟）

---

### 🟡 第3步：更新 OAuth 重定向 URI

部署后，脚本会输出您的 Cloud Run URL，例如：
```
https://autoplanner-xxx.run.app
```

需要在 Google Cloud Console 中更新：

1. 访问 https://console.cloud.google.com/apis/credentials
2. 找到 OAuth 2.0 Client ID (Web application)
3. 编辑凭证
4. 在 **Authorized redirect URIs** 中添加：
   ```
   https://autoplanner-xxx.run.app/oauth/google/callback
   ```
5. 保存

---

## 🎯 部署命令速查

### 查看当前部署状态
```bash
gcloud run services describe autoplanner --region us-central1 --project click-to-create
```

### 查看应用日志
```bash
gcloud run logs read autoplanner --region us-central1 --project click-to-create --limit 50
```

### 更新环境变量
```bash
gcloud run deploy autoplanner \
  --update-env-vars "KEY=value" \
  --region us-central1 \
  --project click-to-create
```

### 获取服务 URL
```bash
gcloud run services describe autoplanner \
  --region us-central1 \
  --format="value(status.url)" \
  --project click-to-create
```

---

## 📋 部署后验证清单

部署完成后，按照以下步骤验证：

### ✅ 1. 应用可访问
```bash
# 获取 URL
APP_URL=$(gcloud run services describe autoplanner \
  --region us-central1 \
  --format="value(status.url)" \
  --project click-to-create)

# 测试访问
curl -I $APP_URL
```

### ✅ 2. 测试用户功能
1. 访问 `$APP_URL`
2. 注册新账户
3. 登录
4. 创建测试事件

### ✅ 3. 测试 Google OAuth
1. 登录后点击右上角 ⚙️
2. 点击 "Connect to Calendar"
3. 通过 Google 账户授权
4. 确认回到应用并显示成功

### ✅ 4. 测试 AI 功能
1. 在输入框输入自然语言事件描述：
   ```
   Tomorrow at 2pm team meeting for 1 hour in room 301
   ```
2. 事件应该被解析和规范化
3. 创建事件应该成功

### ✅ 5. 检查数据库连接
```bash
# 在 Cloud Run 日志中检查
gcloud run logs read autoplanner --region us-central1 --limit 20
```

---

## 🔧 常见问题排查

### 问题：部门计费未启用导致 API 无法启用

**解决**:
1. 启用项目计费
2. 等待 10 分钟
3. 重新运行部署脚本

### 问题：Cloud SQL 创建失败

**原因**: 通常是权限或计费问题

**解决**:
1. 确认计费已启用
2. 检查您是否有项目所有者权限

### 问题：Cloud Run 部署失败，显示权限错误

**解决**:
1. 在 Google Cloud Console 中检查 IAM 权限
2. 确保您有以下角色：
   - Cloud Run Admin
   - Service Accounts Admin
   - Secret Manager Admin (用于 secrets)

### 问题：OAuth 授权后返回 404

**原因**: 重定向 URI 不匹配

**解决**:
1. 检查 Google Cloud Console 中的重定向 URI 是否正确
2. 确保 URL 完全匹配（包括协议和路径）
3. 重新授权

### 问题：AI 功能不工作

**原因**: Gemini API 密钥未正确配置

**解决**:
1. 验证 `.env.production` 中有正确的 API 密钥
2. 重新部署：
   ```bash
   gcloud run deploy autoplanner \
     --set-env-vars "GOOGLE_GENERATIVE_AI_KEY=AIzaSyDi4bIFdmIxOaHieNvAXm1ZGieIla4-Cpc" \
     --region us-central1 \
     --project click-to-create
   ```

---

## 📚 文件清单

### 部署脚本
- `deploy_to_cloud.sh` - 自动化云部署脚本
- `deploy_generate_vars.sh` - 生成部署变量
- `deploy_vars.env` - 部署配置（已生成）

### 测试脚本
- `test_complete.sh` - 完整功能测试
- `test_automated.sh` - 自动化 API 测试

### 配置文件
- `webclient.json` - Google OAuth 凭证
- `.env.production` - 生产环境配置（根据需要创建）
- `deployment_info.txt` - 部署后生成，包含 URL 信息

### 文档
- `DEPLOYMENT_CHECKLIST.md` - 详细部署检查清单
- `DEPLOYMENT_README.md` - 本文件

---

## 🎯 预计时间表

| 步骤 | 耗时 | 备注 |
|------|------|------|
| 启用项目计费 | 立即 | 需要添加支付方式 |
| APIs 启用 | 1-2 分钟 | 自动化 |
| Service Account 创建 | 1 分钟 | 自动化 |
| Cloud SQL 创建 | 3-5 分钟 | 等待 PostgreSQL 启动 |
| Secret 配置 | 1 分钟 | 自动化 |
| Cloud Run 部署 | 2-3 分钟 | 自动化 |
| **总计** | **8-12 分钟** | 完全自动化 |

---

## 🔐 安全注意事项

### API 密钥保护
- ✅ Gemini API 密钥已配置在环境变量
- ✅ OAuth 凭证存储在 Secret Manager
- ✅ 数据库密码存储在 Secret Manager

### HTTPS 和安全性
- ✅ Cloud Run 自动使用 HTTPS
- ✅ CSRF 保护已启用
- ✅ 会话机制已配置

### 数据库安全
- ✅ Cloud SQL 使用强密码
- ✅ 公网访问已禁用
- ✅ 通过私有连接访问

---

## 📞 支持和反馈

如果部署过程中遇到问题：

1. **检查日志**
   ```bash
   gcloud run logs read autoplanner --region us-central1 --limit 50
   ```

2. **查看 Google Cloud Console**
   https://console.cloud.google.com

3. **运行本地测试**
   ```bash
   ./test_complete.sh
   ```

4. **查看部署文档**
   - docs/DEPLOYMENT/01-DEPLOYMENT-GUIDE.md
   - DEPLOYMENT_CHECKLIST.md

---

## ✨ 下一步

一旦部署成功，考虑：

1. **配置自定义域名**
   - 使用 Cloud Load Balancer 或 Cloud CDN
   
2. **启用自动缩放**
   - 配置最少/最多实例数
   
3. **设置监控和告警**
   - Cloud Monitoring
   - Error Reporting

4. **配置备份**
   - Cloud SQL 自动备份
   - Firestore 备份

5. **性能优化**
   - 启用 Cloud CDN
   - 配置缓存策略

---

**祝部署顺利！🎉**

