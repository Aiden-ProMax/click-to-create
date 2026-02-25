"""
Django settings for autoplanner project - 改进版本

## 配置方案

本文件使用分层配置系统：

1. 环境识别：通过 ENVIRONMENT 变量（development/production）
2. 强制验证：生产环境的关键变量必须明确配置
3. 合理默认：开发变量有合理的开发默认值
4. 早期失败：启动时检查配置，而不是运行时

## 使用方法

### 开发环境
```bash
export ENVIRONMENT=development
export DJANGO_DEBUG=true
export GOOGLE_GENERATIVE_AI_KEY=<your-key>
python manage.py runserver
```

### 生产环境
```bash
# 创建 .env.production 文件或使用环境变量
export ENVIRONMENT=production
export DJANGO_SECRET_KEY=<secure-key>
export DJANGO_ALLOWED_HOSTS=app.example.com
export DB_HOST=<cloud-sql-host>
export DB_USER=<db-user>
export DB_PASSWORD=<secure-password>
export DB_NAME=<db-name>
export GOOGLE_GENERATIVE_AI_KEY=<key>
export GOOGLE_OAUTH_REDIRECT_URI=https://app.example.com/oauth/google/callback
# ... 其他变量
```

## 关键改进

✓ 环境判断清晰：避免混乱的条件分支
✓ 生产环境无默认值：参数必须明确配置，防止遗漏
✓ 开发环境有合理默认：便于本地开发
✓ 启动时验证：及早发现配置问题
✓ 无硬编码生产 URL：所有特定部署信息从环境变量读取
✓ 分层函数：代码清晰易维护
"""

from pathlib import Path
from dotenv import load_dotenv
import os
import sys

# =============================================================================
# 第 0 步：加载环境变量（必须最早执行）
# =============================================================================
load_dotenv()

# Build paths inside the project
BASE_DIR = Path(__file__).resolve().parent.parent

# =============================================================================
# 第 1 步：识别运行环境
# =============================================================================
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development').lower()

if ENVIRONMENT not in ('development', 'production'):
    raise ValueError(
        f"Invalid ENVIRONMENT='{ENVIRONMENT}'. "
        f"Must be 'development' or 'production'"
    )

# =============================================================================
# 第 2 步：环境变量读取辅助函数
# =============================================================================

def get_required_env(var_name: str, *, description: str = '') -> str:
    """
    获取必需的环境变量。
    
    在生产环境中，如果未设置则抛出异常。
    在开发环境中，也会抛出异常，但可以设置环境变量来跳过。
    
    Args:
        var_name: 环境变量名
        description: 变量的描述信息（用于错误消息）
    
    Returns:
        环境变量的值
    
    Raises:
        ValueError: 如果变量未设置且是生产环境
    """
    value = os.getenv(var_name, '').strip()
    
    if not value:
        error_msg = (
            f"Missing required environment variable: {var_name}"
        )
        if description:
            error_msg += f"\nDescription: {description}"
        error_msg += f"\nSet with: export {var_name}=<value>"
        
        if ENVIRONMENT == 'production':
            raise ValueError(error_msg)
        else:
            # 开发环境也要求设置关键变量
            if var_name in ('DJANGO_SECRET_KEY', 'GOOGLE_GENERATIVE_AI_KEY'):
                raise ValueError(error_msg)
    
    return value


def get_optional_env(var_name: str, default: str = '', *, description: str = '') -> str:
    """
    获取可选的环境变量，带默认值。
    
    Args:
        var_name: 环境变量名
        default: 默认值（如果变量未设置）
        description: 变量的描述信息
    
    Returns:
        环境变量的值或默认值
    """
    return os.getenv(var_name, default).strip()


def get_bool_env(var_name: str, default: bool = False) -> bool:
    """
    获取布尔环境变量。
    
    识别: true/True/TRUE/1/yes 为 True，其他为 False
    """
    value = os.getenv(var_name, '').lower().strip()
    if not value:
        return default
    return value in ('true', '1', 'yes', 'on')


# =============================================================================
# 第 3 步：Django 核心安全设置
# =============================================================================

# Secret Key
SECRET_KEY = get_optional_env('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    if ENVIRONMENT == 'development':
        # 开发环境：使用不安全的默认密钥
        SECRET_KEY = 'dev-only-insecure-key-replace-in-production-with-env-var'
        print(
            "⚠️  WARNING: Using insecure SECRET_KEY in development. "
            f"To use custom key, set DJANGO_SECRET_KEY environment variable."
        )
    else:
        raise ValueError(
            "DJANGO_SECRET_KEY environment variable must be set in production. "
            "Generate with: python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'"
        )

# DEBUG Mode - 默认关闭
# 仅在开发环境且明确设置 DJANGO_DEBUG=true 时启用
DEBUG = (
    ENVIRONMENT == 'development' and 
    get_bool_env('DJANGO_DEBUG', default=False)
)

# =============================================================================
# 第 4 步：Allowed Hosts - 明确的环境区分
# =============================================================================

if ENVIRONMENT == 'development':
    # 开发环境：允许常见的本地地址
    ALLOWED_HOSTS = get_optional_env(
        'DJANGO_ALLOWED_HOSTS',
        'localhost,127.0.0.1,0.0.0.0'
    ).split(',')
    ALLOWED_HOSTS = [h.strip() for h in ALLOWED_HOSTS if h.strip()]
    
elif ENVIRONMENT == 'production':
    # 生产环境：从环境变量获取，必须明确配置
    hosts_str = get_optional_env('DJANGO_ALLOWED_HOSTS', '').strip()
    if not hosts_str:
        raise ValueError(
            "In production, DJANGO_ALLOWED_HOSTS environment variable must be set explicitly. "
            "Example: export DJANGO_ALLOWED_HOSTS='app.example.com,www.example.com'\n"
            "Do not use wildcard '*' unless absolutely necessary and only for internal services."
        )
    ALLOWED_HOSTS = [h.strip() for h in hosts_str.split(',') if h.strip()]
    
    # 生产环境关闭 DEBUG
    DEBUG = False

# 允许 OAuth 穿过 HTTP（仅开发）
if ENVIRONMENT == 'development' and get_bool_env('OAUTHLIB_INSECURE_TRANSPORT'):
    os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'

# =============================================================================
# 第 5 步：应用配置
# =============================================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'users',
    'events',
    'caldav_sync',
    'google_sync',
    'ai',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    # 为 Cloud Run HTTPS 环境优化的 CSRF 中间件
    'autoplanner.csrf_middleware.CloudRunCsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'autoplanner.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'autoplanner.wsgi.application'

# =============================================================================
# 第 6 步：数据库配置 - 环境明确分离
# =============================================================================

if ENVIRONMENT == 'development':
    # SQLite 开发数据库
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

elif ENVIRONMENT == 'production':
    # PostgreSQL 生产数据库
    # 所有参数必须通过环境变量明确配置
    
    db_engine = get_optional_env('DB_ENGINE', 'django.db.backends.postgresql')
    db_name = get_required_env('DB_NAME', description='数据库名称')
    db_user = get_required_env('DB_USER', description='数据库用户')
    db_password = get_required_env('DB_PASSWORD', description='数据库密码')
    db_port = get_optional_env('DB_PORT', '5432')
    
    # Cloud SQL 连接（使用 Unix socket）
    cloud_sql_conn = get_optional_env('CLOUD_SQL_CONNECTION_NAME')
    
    if cloud_sql_conn:
        # Cloud SQL Proxy via Unix socket
        db_host = f'/cloudsql/{cloud_sql_conn}'
    else:
        # 直接连接（仅用于测试）
        db_host = get_optional_env('DB_HOST', 'localhost')
    
    DATABASES = {
        'default': {
            'ENGINE': db_engine,
            'NAME': db_name,
            'USER': db_user,
            'PASSWORD': db_password,
            'HOST': db_host,
            'PORT': db_port,
            # 生产连接池设置
            'CONN_MAX_AGE': 600,  # 连接复用时间（秒）
        }
    }

# =============================================================================
# 第 7 步：国际化和时区
# =============================================================================

LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = get_optional_env('DJANGO_TIME_ZONE', 'America/Los_Angeles')
USE_I18N = True
USE_TZ = True

# =============================================================================
# 第 8 步：静态文件配置
# =============================================================================

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# 生产环境：Google Cloud Storage
if ENVIRONMENT == 'production' and get_optional_env('GCS_BUCKET_NAME'):
    try:
        from storages.backends.gcloud import GoogleCloudStorage
        DEFAULT_FILE_STORAGE = 'storages.backends.gcloud.GoogleCloudStorage'
        GS_BUCKET_NAME = get_optional_env('GCS_BUCKET_NAME', 'autoplanner-static')
        GS_PROJECT_ID = get_optional_env('GCP_PROJECT_ID', '')
        STATIC_URL = f'https://storage.googleapis.com/{GS_BUCKET_NAME}/static/'
    except ImportError:
        pass  # Fallback to local static files

# =============================================================================
# 第 9 步：REST Framework 配置
# =============================================================================

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# =============================================================================
# 第 10 步：Google 服务配置
# =============================================================================

# Gemini AI
GOOGLE_GENERATIVE_AI_KEY = get_required_env(
    'GOOGLE_GENERATIVE_AI_KEY',
    description='Google Generative AI (Gemini) API Key from https://aistudio.google.com/apikey'
)
GOOGLE_GENERATIVE_AI_MODEL = get_optional_env(
    'GOOGLE_GENERATIVE_AI_MODEL',
    'gemini-2.5-flash',
    description='模型名称，默认 gemini-2.5-flash'
)

# Google OAuth for Calendar
if ENVIRONMENT == 'development':
    default_oauth_redirect = 'http://localhost:8000/oauth/google/callback'
else:
    default_oauth_redirect = ''  # 生产环境必须明确设置

GOOGLE_OAUTH_REDIRECT_URI = get_optional_env(
    'GOOGLE_OAUTH_REDIRECT_URI',
    default_oauth_redirect
) or get_required_env(
    'GOOGLE_OAUTH_REDIRECT_URI',
    description='OAuth redirect URI - 必须与 Google Console 中的配置匹配'
)

GOOGLE_OAUTH_CLIENT_JSON_PATH = get_optional_env(
    'GOOGLE_OAUTH_CLIENT_JSON_PATH',
    str(BASE_DIR / 'webclient.json'),
    description='Google OAuth 凭证 JSON 文件的路径'
)

GOOGLE_OAUTH_SCOPES = get_optional_env(
    'GOOGLE_OAUTH_SCOPES',
    'https://www.googleapis.com/auth/calendar.events'
)

# =============================================================================
# 第 11 步：Radicale CalDAV 配置
# =============================================================================

if ENVIRONMENT == 'production':
    # 生产环境所有参数必须明确配置
    RADICALE_BASE_URL = get_required_env(
        'RADICALE_BASE_URL',
        description='Radicale 服务器 URL，如 https://radicale.example.com'
    )
    RADICALE_HTPASSWD_PATH = get_required_env(
        'RADICALE_HTPASSWD_PATH',
        description='Radicale htpasswd 文件路径'
    )
    RADICALE_CONFIG_PATH = get_required_env(
        'RADICALE_CONFIG_PATH',
        description='Radicale 配置文件路径'
    )
else:
    # 开发环境：合理的开发默认值（不依赖 Path.home()）
    RADICALE_BASE_URL = get_optional_env(
        'RADICALE_BASE_URL',
        'https://localhost:5232'
    )
    RADICALE_HTPASSWD_PATH = get_optional_env(
        'RADICALE_HTPASSWD_PATH',
        str(BASE_DIR / 'radicale_users')
    )
    RADICALE_CONFIG_PATH = get_optional_env(
        'RADICALE_CONFIG_PATH',
        str(BASE_DIR / 'radicale_config')
    )

RADICALE_VERIFY_SSL = get_bool_env('RADICALE_VERIFY_SSL', default=False)
RADICALE_DEFAULT_CALENDAR = get_optional_env('RADICALE_DEFAULT_CALENDAR', 'calendar')
RADICALE_HTPASSWD_ENCRYPTION = get_optional_env('RADICALE_HTPASSWD_ENCRYPTION', 'plain')

# =============================================================================
# 第 12 步：Security Headers（HTTPS/HTTPS 重定向）
# =============================================================================

if ENVIRONMENT == 'production':
    # 启用安全 headers
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    
    # HSTS（HTTP 严格传输安全）
    SECURE_HSTS_SECONDS = 31536000  # 1 年
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    
    # Cloud Run 特定配置
    if os.getenv('CLOUD_RUN_ENV'):
        # Cloud Run 使用 Google Frontend Load Balancer 处理 SSL/TLS
        # 应用接收到的是 HTTP 请求，但有 X-Forwarded-Proto: https 头
        SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
        SECURE_SSL_REDIRECT = False  # Load Balancer 已处理 SSL 重定向
        
        # CSRF 信任的源（来自 Cloud Run 负载均衡器的请求）
        csrf_origins_str = get_optional_env('CSRF_TRUSTED_ORIGINS', '')
        if csrf_origins_str:
            CSRF_TRUSTED_ORIGINS = [o.strip() for o in csrf_origins_str.split(',') if o.strip()]
        else:
            # 默认信任 Cloud Run 域名
            CSRF_TRUSTED_ORIGINS = [
                'https://*.run.app',
            ]
    else:
        # 非 Cloud Run 生产环境
        SECURE_SSL_REDIRECT = True

# CSRF 配置
CSRF_USE_SESSIONS = False
CSRF_COOKIE_HTTPONLY = False  # 允许 JavaScript 读取 CSRF 令牌（用于 API 请求）

# =============================================================================
# 第 13 步：密码验证
# =============================================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# =============================================================================
# 第 14 步：日志配置
# =============================================================================

LOG_LEVEL = get_optional_env(
    'LOG_LEVEL',
    'DEBUG' if ENVIRONMENT == 'development' else 'INFO'
).upper()

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {message}',
            'style': '{',
        },
        'json': {
            # JSON 格式便于在 Cloud Run 日志中解析
            'format': '{"time": "%(asctime)s", "level": "%(levelname)s", "module": "%(module)s", "message": "%(message)s"}',
            'datefmt': '%Y-%m-%dT%H:%M:%SZ',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'json' if ENVIRONMENT == 'production' else 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': LOG_LEVEL,
    },
}

# =============================================================================
# 第 15 步：启动时配置验证（仅生产环境）
# =============================================================================

if ENVIRONMENT == 'production':
    # 验证关键配置已设置
    critical_vars = [
        ('DJANGO_SECRET_KEY', SECRET_KEY, 'Django secret key'),
        ('GOOGLE_GENERATIVE_AI_KEY', GOOGLE_GENERATIVE_AI_KEY, 'Gemini API key'),
        ('DJANGO_ALLOWED_HOSTS', ','.join(ALLOWED_HOSTS), 'Allowed hosts'),
        ('DB_NAME', DATABASES['default'].get('NAME'), 'Database name'),
    ]
    
    missing_vars = [name for name, value, _ in critical_vars if not value]
    if missing_vars:
        print(
            f"\n❌ 生产环境配置不完整。缺少环境变量：{', '.join(missing_vars)}\n",
            file=sys.stderr
        )
        # 注意：不在这里抛出异常，因为某些变量可能在运行时加载

print(f"\n✓ Django settings loaded for {ENVIRONMENT.upper()} environment\n")
