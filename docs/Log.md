# 操作日志

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
