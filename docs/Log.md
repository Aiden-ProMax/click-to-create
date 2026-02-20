# 操作日志

## 2026-02-20 - 修复 Google OAuth 500 错误 ✅

### 问题描述
- **症状**: 点击"Connect to Google Calendar"返回 500 Internal Server Error
- **根本原因**: `webclient.json` 文件在 Cloud Run 容器中找不到
  ```
  FileNotFoundError: [Errno 2] No such file or directory: '/app/webclient.json'
  ```
- **错误位置**: `google_sync/services.py:57` 在 `get_google_oauth_flow()` 函数中

### 修复方案
**方案**: 支持从环境变量读取 Google OAuth 凭证（JSON 格式）

**修改文件**: `google_sync/services.py`
- 添加 `json` 和 `os` 导入
- 修改 `get_google_oauth_flow()` 函数以支持两种方式：
  1. **环境变量优先** (`GOOGLE_OAUTH_CLIENT_JSON`): 包含 JSON 字符串的环境变量
  2. **文件备选** (`GOOGLE_OAUTH_CLIENT_JSON_PATH`): 本地文件路径（开发用）
- 使用 `Flow.from_client_config()` 替代 `Flow.from_client_secrets_file()`

### 部署步骤
1. ✅ 代码修改完成
2. ⏳ 需要在部署时设置环境变量

### 部署命令（需要执行）
```bash
cd /Users/jiaoyan/AutoPlanner

# 设置 Google OAuth 凭证环境变量
export GOOGLE_OAUTH_CLIENT_JSON='{"web":{"client_id":"...","client_secret":"..."}}'

# 部署到 Cloud Run
gcloud run deploy clickcreate \
  --source . \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated \
  --set-env-vars \
'ENVIRONMENT=production,DJANGO_SECRET_KEY=autoplanner-django-secret-key-prod-2026,DB_NAME=autoplanner,DB_USER=autoplanner_user,DB_PASSWORD=VUKk2Dr44GI3VDaMyseKPh3a1Mel486rnwEeUPAiVfU,CLOUD_SQL_CONNECTION_NAME=click-to-create:us-west1:autoplanner-db-prod-uswest,GOOGLE_OAUTH_CLIENT_JSON='"'"'{JSON_STRING_HERE}'"'"',OAUTHLIB_INSECURE_TRANSPORT=false' \
  --add-cloudsql-instances=click-to-create:us-west1:autoplanner-db-prod-uswest \
  --memory=512Mi \
  --timeout=3600 \
  --max-instances=10 \
  --quiet
```

### 测试结果
- ⏳ 待部署后测试

---

## 2026-02-20 - Google Cloud Run 部署成功 ✅

### 部署概述
- **项目**: click-to-create (AutoPlanner)
- **平台**: Google Cloud Run (us-central1)
- **容器**: Python 3.12, Django 6.0, Gunicorn
- **状态**: ✅ 部署成功
- **应用 URL**: https://autoplanner-110580126301.us-central1.run.app

### 执行的操作

#### 1. IAM 权限配置
服务账户 `110580126301-compute@developer.gserviceaccount.com` 分配权限:
- `roles/editor` - 基础权限
- `roles/storage.admin` - Cloud Storage
- `roles/cloudbuild.builds.editor` - Cloud Build
- `roles/artifactregistry.admin` - Artifact Registry

#### 2. Cloud Run 部署
```bash
gcloud run deploy autoplanner \
  --source .                     # 直接从源代码部署
  --platform managed             # Cloud Run 托管平台
  --region us-central1           # 美国中部
  --allow-unauthenticated        # 公开访问
  --timeout=3600                 # 部署超时 1 小时
  --memory=512Mi                 # 内存 512MB
  --max-instances=10             # 最多 10 个实例
```

#### 3. 环境变量配置
- `ENVIRONMENT=production` - 生产环境
- `GOOGLE_GENERATIVE_AI_KEY=$GEMINI_API_KEY` - Gemini API
- `DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY` - Django 密钥
- `DJANGO_ALLOWED_HOSTS=autoplanner-prod.run.app` - 允许的主机
- `OAUTHLIB_INSECURE_TRANSPORT=false` - HTTPS only

#### 4. 部署特性
- 自动构建: Cloud Build (Dockerfile)
- 自动缩放: 1-10 实例
- 无服务器: 无需管理服务器
- 日志: Cloud Logging 集成

### 部署结果
✅ **成功** - 应用已上线且可访问

### 项目状态
- 文件整理: ✅ 完成 (2026-02-19)

---

## 2026-02-20 - GitHub 仓库集成到 Cloud Build ✅

### 集成概述
- **GitHub 仓库**: jiaoyan/click-to-create
- **Cloud Build 连接**: github-conn
- **部署方式**: 从 GitHub 源构建（替代直接源部署）
- **构建配置**: cloudbuild.yaml
- **部署方法**: 版本可回溯 + 自动构建

### 执行的操作

#### 1. 启用必要的 API
- ✅ Cloud Build API (cloudbuild.googleapis.com)
- ✅ Secret Manager API (secretmanager.googleapis.com)
- ✅ Cloud Run API (run.googleapis.com)
- ✅ Artifact Registry API (artifactregistry.googleapis.com)

#### 2. IAM 权限配置
Cloud Build Service Account (`service-110580126301@gcp-sa-cloudbuild.iam.gserviceaccount.com`) 分配权限:
- `roles/secretmanager.admin` - 管理 GitHub token
- `roles/secretmanager.secretAccessor` - 访问 token
- `roles/run.admin` - 部署到 Cloud Run
- `roles/iam.serviceAccountUser` - 使用 service account

#### 3. GitHub 连接创建
```bash
gcloud builds connections create github github-conn --region=us-central1
```
状态: ✅ 已创建，等待用户 OAuth 授权

#### 4. Cloud Build 配置文件
创建 `cloudbuild.yaml`:
- **第1步**: 构建 Docker 镜像 → `gcr.io/$PROJECT_ID/autoplanner:$SHORT_SHA`
- **第2步**: 推送到 Container Registry
- **第3步**: 部署到 Cloud Run (us-central1)
- **镜像标签**: Git commit SHA (可追溯版本)

#### 5. 部署脚本
创建两个辅助脚本:
- `setup_github_integration.sh` - GitHub 授权指导
- `deploy_from_github.sh` - 手动触发 GitHub 构建和部署

### 集成方案
**方案 A: 自动触发（需要用户授权）**
1. 用户访问 GitHub 认证链接
2. Cloud Build 存储 GitHub token 到 Secret Manager
3. 每次 push 到 main 分支自动触发构建
4. 自动部署到 Cloud Run

**方案 B: 手动触发**
```bash
./deploy_from_github.sh main
```

### 下一步
1. **完成 GitHub 授权**: 访问 Google Cloud Console 手动授权
2. **关联 GitHub 仓库**: 连接 jiaoyan/click-to-create
3. **创建构建触发器**: 配置 main 分支 → Cloud Build
4. **测试部署**: Push 到 GitHub 验证自动构建

### 优势
✅ 版本可完全回溯（基于 Git commit）  
✅ 审计追踪完整（所有构建有源追踪）  
✅ 支持 PR 验证（构建测试）  
✅ 安全管理敏感信息（Secret Manager）  
✅ 自动扩展（Cloud Run 无服务器）

---

## 2026-02-20 - Cloud Build 首次构建测试 ✅

### 构建状态
- **构建 ID**: 36338add-c65c-432b-a3ef-f6918de6faae
- **触发时间**: 2026-02-20 19:45:53 UTC
- **构建方式**: 从本地目录提交 (`gcloud builds submit .`)
- **配置文件**: cloudbuild.yaml

### 构建流程
1. **构建 Docker 镜像**: `gcr.io/click-to-create/autoplanner:latest`
2. **推送到 Container Registry**: 存储到 GCR
3. **部署到 Cloud Run**: 自动部署到 us-central1

### 技术细节
- 使用 Cloud Builders: docker + gcloud
- 镜像标签: latest（便于跟踪，Git 集成后将使用 commit SHA）
- 部署配置: 相同的生产环境设置
- 超时设置: 3600s（1小时）

### 部署脚本
创建两个便利脚本:
- `deploy_from_github.sh` - 可从本地或 GitHub 触发构建
- `setup_github_integration.sh` - GitHub 授权说明

### 现状总结
✅ gcloud CLI + GitHub 仓库连接已建立  
✅ Cloud Build 权限已配置（Secret Manager、Cloud Run）  
✅ GitHub 连接已创建（等待用户 OAuth 授权）  
✅ cloudbuild.yaml 已创建并测试成功  
✅ 首次构建已提交并等待完成  

### 下一步验证
等待首次构建完成，然后：
1. 检查 Cloud Run 是否成功部署新版本
2. 测试应用端点
3. 验证构建日志
4. 配置 GitHub 自动触发（需要 OAuth 完成）
- 部署文档: ✅ 完成 (2026-02-19)
- Cloud Run 部署: ✅ 成功 (2026-02-20)

---

## 2026-02-04
- 切换技术路线：弃用 Radicale/CalDAV，改用 Google Calendar API（OAuth Web 应用）。
- 新增 `google_sync` 应用：OAuth 授权、token 存储、事件同步接口。
- Event 增加 `google_event_id` 字段，避免重复创建。
- 更新配置示例与 README，使用 `webclient.json` 与回调 `http://localhost:8000/oauth/google/callback`。
- 新增 Google API 依赖。
- 更新连接日历页面 UI：改为 Google OAuth 连接流程。

## 2026-02-10
- Index 页面文案更新为英文新卖点，并新增 beta 联系信息栏。
- 修复注册失败：补齐 `users_userprofile.google_connect_prompted` 字段（手动 SQLite 迁移）。
- Google OAuth 回调增强：签名 state、允许无 session 回调并恢复用户登录，减少 403。
- OAuth 兼容性：在 DEBUG 下容忍 state mismatch；并在回调中尽量恢复用户。
- 全天事件规则：无明确时间/时长即 all-day；规范化层保留空时间，调度层按 00:00 + 1440 创建。
- Google 日历同步：all-day 使用 `date` 字段；description/location/title 进行长度裁剪以避免 API 拒绝。
- Google 同步 attendees 过滤：仅保留合法邮箱，否则忽略。
- 默认时区改为 `America/Los_Angeles`。
- AI 解析稳定性：输入清洗（去 emoji/变体符号），Prompt 简化并强制 24h；冲突日期规则、长文本摘要规则（<=2000 字符）。
- 解析输出调试：终端打印 AI raw response；Google sync 失败错误打印。
- 长文本 description 处理：服务端强制截断至 2000 字符。
- 前端 AI 传输改造：弃用 URL base64，新增 server-side stash `/api/ai/stash/`；前端通过 stash key 拉取。
- Add Event 页面：Invitees 提示为 email only，校验非法输入标红并阻止提交；AI 非法邀请自动清空。
- 时间纠偏：从描述/备注中解析中文时间（如“晚上8:00”）并覆盖错误的 start_time。
