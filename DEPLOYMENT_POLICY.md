# 🚀 部署策略文档

**状态**: ✅ 仅手动部署 | 无自动化
**更新日期**: 2026-03-03

---

## 📋 当前部署架构

### ✅ 已清理的自动化配置
- ❌ `.github/workflows/` - 已删除
- ❌ `cloudbuild.yaml` - 已删除  
- ❌ `app.yaml` - 已删除
- ❌ GitHub Actions workflow - 已删除
- ❌ 自动触发部署 - 已禁用

### ✅ 现存的手动部署工具
- ✅ `deploy_with_oauth.sh` - 纯手动部署脚本
- ✅ `deploy_vars.env` - 部署环境变量配置
- ✅ 测试脚本 - 仅用于验证，不会触发部署

---

## 🎯 部署流程（仅手动）

### **步骤 1: 验证代码**
```bash
cd /Users/jiaoyan/AutoPlanner
git status          # 确保工作区干净
git log -1 --oneline  # 确认当前分支
```

### **步骤 2: 更新配置（如需要）**
```bash
# 仅当需要更改 API Key 或其他环境变量时
vim env-vars.yaml
vim deploy_vars.env
```

### **步骤 3: 执行部署**
```bash
./deploy_with_oauth.sh
```

这会：
1. 读取 env-vars.yaml 和 deploy_vars.env
2. 构建 Docker 镜像
3. 推送到 Google Cloud Run
4. 部署到 us-west2 region
5. 自动测试新部署

---

## 🔐 部署配置细节

### 环境变量源 (env-vars.yaml)
```yaml
ENVIRONMENT: production
GOOGLE_GENERATIVE_AI_KEY: AIzaSyC88yUfgCEWK-8L5sikrFMMjnZk1cmYNAo
DJANGO_SECRET_KEY: (secure configured)
DJANGO_ALLOWED_HOSTS: clickcreate-110580126301.us-west2.run.app
GOOGLE_OAUTH_REDIRECT_URI: https://clickcreate-110580126301.us-west2.run.app/oauth/google/callback
CLOUD_SQL_CONNECTION_NAME: click-to-create:us-west1:autoplanner-db-prod-uswest
```

### 部署变量源 (deploy_vars.env)
```bash
PROJECT_ID=click-to-create
REGION=us-west2
APP_NAME=clickcreate
GEMINI_API_KEY=AIzaSyC88yUfgCEWK-8L5sikrFMMjnZk1cmYNAo
# ... 其他变量
```

---

## 🌐 Cloud Run 管理

### 查看当前状态
```bash
# 查看服务信息
gcloud run services describe clickcreate --region=us-west2

# 查看流量分配
gcloud run services describe clickcreate --region=us-west2 --format="value(status.traffic)"

# 列出所有版本
gcloud run revisions list --service=clickcreate --region=us-west2
```

### 手动流量管理
```bash
# 切换到新版本
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00022-9vg=100 \
  --region=us-west2

# 金丝雀部署（10% 新版本，90% 旧版本）
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00022-9vg=10,clickcreate-00015-sh8=90 \
  --region=us-west2

# 紧急回滚
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00015-sh8=100 \
  --region=us-west2
```

---

## ❌ 绝对不会自动触发部署的原因

1. **GitHub Actions** - 工作流已删除，入住 origin/main
2. **Cloud Build** - cloudbuild.yaml 已删除
3. **App Engine** - app.yaml 已删除
4. **Webhooks** - GitHub 中没有配置任何 webhook
5. **Cron 任务** - 没有定时部署任务
6. **CI/CD 管道** - 所有自动化管道都已禁用

---

## 📝 Git 历史参考

### 关键提交
- `07e7185` - 删除所有自动部署配置 (origin/main)
- `3d43a69` - 之前添加的 GitHub Actions（已在 07e7185 清理）

### 分支管理
- `main` - 生产代码，与 origin/main 同步 ✅
- `backup-before-rollback` - 回滚前的备份（仅参考用）
- `develop` - 开发分支（无自动部署）
- `feature/my-new-feature` - 功能分支（无自动部署）

---

## ✨ 部署安全检查清单

部署前务必检查：

- [ ] 确认在 `main` 分支
- [ ] `git status` 工作区干净
- [ ] 最新的代码已 pull
- [ ] API Key 有效
- [ ] 环境变量文件已更新
- [ ] 没有敏感信息提交到 git

---

## 🆘 故障排查

### 部署失败
```bash
# 查看最近的日志
gcloud run services logs read clickcreate --region=us-west2 --limit=100

# 查看特定版本的日志
gcloud run revisions logs read clickcreate-00022-9vg --region=us-west2
```

### 回滚步骤
```bash
# 立即回滚到上一个稳定版本
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00015-sh8=100 \
  --region=us-west2

# 然后诊断问题...
gcloud run services logs read clickcreate --region=us-west2
```

---

**最后更新**: 2026-03-03
**维护者**: GitHub Copilot
**状态**: ✅ **所有自动部署已清理，仅支持手动部署**
