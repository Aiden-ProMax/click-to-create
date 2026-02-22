# 常见错误与解决方案

## 1. AI 模型 404 错误
**错误消息**: `404 models/gemini-1.5-flash is not found for API version v1beta`

**原因**: 旧 SDK (google.generativeai) 不支持 Gemini 3 系列模型

**解决方案**:
```bash
# 1. 更新 requirements.txt
google-generativeai>=0.5.0  →  google-genai>=0.3.0

# 2. 更新 ai/services.py
# 旧代码
import google.generativeai as genai
model = genai.GenerativeModel('gemini-1.5-flash')

# 新代码
from google import genai
from google.genai import types
client = genai.Client(api_key=settings.GOOGLE_GENERATIVE_AI_KEY)
response = client.models.generate_content(
    model='gemini-3-flash-preview',
    contents=user_prompt,
    config=types.GenerateContentConfig(
        system_instruction=SYSTEM_PROMPT,
        thinking_config=types.ThinkingConfig(thinking_level="low")
    )
)

# 3. 部署到 Cloud Run
gcloud run deploy clickcreate --source . --region us-west2 ...
```

---

## 2. OAuth 流程 500 错误
**错误消息**: `Internal Server Error: /oauth/google/start/`

**原因**: 
- `GOOGLE_OAUTH_REDIRECT_URI` 未设置或使用本地开发地址
- `GOOGLE_OAUTH_CLIENT_JSON` 环境变量缺失

**解决方案**:
```bash
# 1. 更新 deploy_vars.env
GOOGLE_OAUTH_REDIRECT_URI=https://clickcreate-110580126301.us-west2.run.app/oauth/google/callback
GOOGLE_OAUTH_CLIENT_JSON='{"web":{"client_id":"...","project_id":"click-to-create",...}}'

# 2. 修改 entrypoint.sh，在启动时创建 webclient.json
if [ -n "$GOOGLE_OAUTH_CLIENT_JSON" ]; then
    echo "$GOOGLE_OAUTH_CLIENT_JSON" > /app/webclient.json
fi

# 3. 创建 env-vars.yaml 文件（YAML 格式）
ENVIRONMENT: production
GOOGLE_OAUTH_REDIRECT_URI: https://clickcreate-...app/oauth/google/callback
GOOGLE_OAUTH_CLIENT_JSON: '{"web":{...}}'

# 4. 部署时使用 env-vars.yaml
gcloud run deploy clickcreate --source . \
  --region us-west2 \
  --env-vars-file env-vars.yaml \
  --set-cloudsql-instances click-to-create:us-west1:autoplanner-db-prod-uswest
```

**关键点**:
- `GOOGLE_OAUTH_REDIRECT_URI` 必须匹配 Google Cloud Console 中 OAuth 凭证的重定向 URI
- `GOOGLE_OAUTH_CLIENT_JSON` 需要在容器中从环境变量读取
- 启用 `OAUTHLIB_INSECURE_TRANSPORT=false` 用于 HTTPS 生产环境

---

## 3. Google Calendar API 未启用
**错误消息**: `Google Calendar API has not been used in project 110580126301 before or it is disabled`

**原因**: Calendar API 在 Google Cloud 项目中未启用

**解决方案**:
```bash
# 访问 Google Cloud Console
https://console.cloud.google.com/apis/library/calendar-json.googleapis.com?project=click-to-create

# 点击 "启用" 按钮
# 等待 1-2 分钟使 API 配置生效
```

**验证**:
```bash
gcloud services list --enabled --project=click-to-create | grep calendar
```

---

## 4. CSRF Referer 检查失败
**错误消息**: `CSRF Failed: Referer checking failed - no Referer`

**原因**: Cloud Run HTTPS 环境中浏览器未发送 Referer 头

**解决方案**:
```python
# autoplanner/csrf_middleware.py
from django.middleware.csrf import CsrfViewMiddleware

class CloudRunCsrfViewMiddleware(CsrfViewMiddleware):
    def _get_failure_view(self):
        return super()._get_failure_view()
    
    def process_view(self, request, *args, **kwargs):
        # 在 HTTPS 上禁用 Referer 检查（Cloud Run 安全）
        if request.is_secure():
            request.META['CSRF_TRUSTED_REFERERS_REQUIRED'] = False
        return super().process_view(request, *args, **kwargs)

# autoplanner/settings.py
MIDDLEWARE = [
    ...
    'autoplanner.csrf_middleware.CloudRunCsrfViewMiddleware',
    ...
]
```

---

## 5. Cloud SQL 连接失败
**错误消息**: `connection to server on socket "/cloudsql/None/.s.PGSQL.5432" failed`

**原因**: Cloud SQL Unix 套接字未正确配置

**解决方案**:
```bash
# settings.py - 使用 Unix 套接字
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'autoplanner'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': f"/cloudsql/{os.getenv('CLOUD_SQL_CONNECTION_NAME', '')}",
        'PORT': '',
    }
}

# 部署时必须使用 --set-cloudsql-instances
gcloud run deploy clickcreate \
  --source . \
  --set-cloudsql-instances click-to-create:us-west1:autoplanner-db-prod-uswest
```

---

## 快速检查清单

- [ ] `GOOGLE_OAUTH_REDIRECT_URI` 设为生产 Cloud Run URL
- [ ] `GOOGLE_OAUTH_CLIENT_JSON` 环境变量已设置
- [ ] `entrypoint.sh` 会从环境变量创建 `webclient.json`
- [ ] Calendar API 在 Google Cloud Console 已启用
- [ ] CSRF 中间件已在 settings.py 中配置
- [ ] Cloud SQL 连接使用 Unix 套接字路径
- [ ] 部署时使用 `--set-cloudsql-instances` 参数
- [ ] Gemini AI 使用 `google-genai` SDK 和 `gemini-3-flash-preview` 模型

---

## 部署命令参考

```bash
cd /Users/jiaoyan/AutoPlanner

# 完整部署命令
bash deploy_with_oauth.sh

# 或手动部署
gcloud run deploy clickcreate \
  --source . \
  --region us-west2 \
  --set-cloudsql-instances click-to-create:us-west1:autoplanner-db-prod-uswest \
  --env-vars-file env-vars.yaml \
  --timeout=3600 \
  --memory=1Gi \
  --allow-unauthenticated \
  --quiet
```

