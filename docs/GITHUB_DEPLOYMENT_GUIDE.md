# GitHub 自动部署配置指南

## 概述
本项目已配置使用 GitHub Actions 自动部署到 Google Cloud Run。每次推送到 `main` 分支时，会自动触发构建和部署。

## 部署流程
1. **推送代码**到 GitHub main 分支
2. **GitHub Actions 自动触发**
3. **Docker 镜像构建**并推送到 Google Container Registry (GCR)
4. **部署到 Cloud Run**服务
5. **完成部署**并验证服务

## 需要配置的 GitHub Secrets

在 GitHub 仓库设置中，添加以下 Secrets：

| Secret 名称 | 说明 | 获取方式 |
|-------------|------|--------|
| `GCP_SA_KEY` | Google Cloud Service Account JSON Key | 见下方 |
| `DJANGO_SECRET_KEY` | Django 应用密钥 | `deploy_vars.env` 中的 `DJANGO_SECRET_KEY` |
| `DB_NAME` | 数据库名称 | `deploy_vars.env` 中的 `DB_NAME` |
| `DB_USER` | 数据库用户 | `deploy_vars.env` 中的 `DB_USER` |
| `DB_PASSWORD` | 数据库密码 | `deploy_vars.env` 中的 `DB_PASSWORD` |
| `CLOUD_SQL_CONNECTION_NAME` | Cloud SQL 连接字符串 | `deploy_vars.env` 中的 `CLOUD_SQL_CONNECTION_NAME` |
| `GEMINI_API_KEY` | Google Gemini API 密钥 | `deploy_vars.env` 中的 `GEMINI_API_KEY` |
| `DJANGO_ALLOWED_HOSTS` | Django 允许的主机 | `deploy_vars.env` 中的 `DJANGO_ALLOWED_HOSTS` |

## 步骤 1: 创建 Google Cloud Service Account

### 使用 gcloud 命令创建
```bash
# 创建 Service Account
gcloud iam service-accounts create github-deployer \
  --display-name="GitHub Deployer" \
  --project=click-to-create

# 赋予 Cloud Run 权限
gcloud projects add-iam-policy-binding click-to-create \
  --member="serviceAccount:github-deployer@click-to-create.iam.gserviceaccount.com" \
  --role="roles/run.admin" \
  --quiet

# 赋予 Service Account User 权限
gcloud projects add-iam-policy-binding click-to-create \
  --member="serviceAccount:github-deployer@click-to-create.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser" \
  --quiet

# 赋予 Container Registry 权限
gcloud projects add-iam-policy-binding click-to-create \
  --member="serviceAccount:github-deployer@click-to-create.iam.gserviceaccount.com" \
  --role="roles/storage.admin" \
  --quiet

# 创建 JSON Key
gcloud iam service-accounts keys create ~/gcp-sa-key.json \
  --iam-account=github-deployer@click-to-create.iam.gserviceaccount.com
```

### 添加 Secret
1. 打开 GitHub 仓库设置 → Secrets → New repository secret
2. 名称: `GCP_SA_KEY`
3. 内容: 复制 `~/gcp-sa-key.json` 文件的完整内容

## 步骤 2: 添加其他 Secrets

1. 打开 GitHub 仓库设置 → Secrets → New repository secret
2. 为上表中的每个 Secret 添加相应的值

## 步骤 3: 验证工作流

### 查看工作流日志
1. 打开 GitHub 仓库 → Actions 标签页
2. 选择 "Deploy to Cloud Run" 工作流
3. 查看最新的运行日志

### 手动触发部署
1. 在 GitHub 仓库 → Actions 标签页
2. 选择 "Deploy to Cloud Run" 工作流
3. 点击 "Run workflow" → "Run workflow" 按钮

## 当前部署配置

### 服务信息
- **项目**: click-to-create
- **区域**: us-west1
- **服务名**: clickcreate
- **服务 URL**: https://clickcreate-110580126301.us-west1.run.app

### 部署配置
- **Docker 镜像**: gcr.io/click-to-create/autoplanner:latest
- **内存**: 512Mi
- **超时**: 3600 秒
- **最大实例数**: 10

## 故障排查

### 如果部署失败

1. **检查 GitHub Actions 日志**
   - 查看具体错误信息

2. **检查权限**
   ```bash
   gcloud projects get-iam-policy click-to-create \
     --flatten="bindings[].members" \
     --format="table(bindings.role)"
   ```

3. **检查 Cloud Build 日志**
   ```bash
   gcloud builds list --project=click-to-create --limit=10
   ```

4. **检查 Cloud Run 部署日志**
   ```bash
   gcloud run services logs read clickcreate \
     --region=us-west1 \
     --project=click-to-create \
     --limit=50
   ```

## 禁用自动部署

如果需要禁用 GitHub Actions 自动部署，编辑 `.github/workflows/deploy-to-cloudrun.yml` 文件，注释掉 `on:` 部分。

## 使用本地 Cloud Build 部署（替代方案）

如果不想使用 GitHub Actions，也可以从本地使用 Cloud Build：

```bash
cd /Users/jiaoyan/AutoPlanner
source deploy_vars.env
gcloud builds submit . \
  --region=us-west1 \
  --project=$PROJECT_ID \
  --config=cloudbuild.yaml
```
