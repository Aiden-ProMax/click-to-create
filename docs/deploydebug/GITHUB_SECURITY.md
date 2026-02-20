# GitHub 推送安全性指南

**项目**: AutoPlanner  
**日期**: 2026-02-20  

---

## 📋 快速答案

### ❓ 我现在能直接把整个项目文件夹推送到 GitHub 吗?

**❌ 不能直接推送 — 有敏感信息需要排除**

但您已经有了安全的 `.gitignore` 配置，所以只要遵循正确的步骤，可以安全地推送。

---

## 🔒 敏感文件清单

### 必须排除的文件 (已在 .gitignore 中)
| 文件 | 内容 | 必要性 |
|------|------|--------|
| `deploy_vars.env` | GCP 密钥、数据库密码 | **强制** |
| `.env` | 本地环境变量 | **强制** |
| `.env.local` | 本地覆盖 | 强制 |
| `webclient.json` | Google OAuth 凭证 | **强制** |
| `db.sqlite3` | 本地 SQLite 数据库 | 强制 |

### 可以推送的配置文件
| 文件 | 用途 | 注意 |
|------|------|------|
| `deploy_vars.env.example` | 配置模板 | ✅ 无敏感信息 |
| `.env.production` | 参考配置 | ⚠️ 本地只用，不推送生产key |
| `.gitignore` | 排除规则 | ✅ 必须推送 |

---

## ✅ 推送前检查清单

### 步骤 1: 验证 .gitignore

已确认以下内容在 `.gitignore` 中：
```
✅ .env*
✅ deploy_vars.env  (已添加)
✅ webclient.json
✅ *.json (某些 JSON 文件)
✅ db.sqlite3
✅ __pycache__/
```

### 步骤 2: 检查已跟踪的敏感文件

```bash
# 运行这个命令检查是否有敏感文件已被 Git 跟踪
git ls-files | grep -E "(\.env|deploy_vars|webclient\.json|\.git ignore)"
```

**预期结果**: 应该只看到 `deploy_vars.env.example`

**如果看到其他敏感文件**:
```bash
# 移除 Git 跟踪（但保留本地文件）
git rm --cached deploy_vars.env
git commit -m "Remove deploy_vars.env from git tracking"
```

### 步骤 3: 最终验证

```bash
# 查看所有待推送的更改
git status

# 应该看不到:
# ❌ deploy_vars.env
# ❌ .env
# ❌ webclient.json

# 应该看到:
# ✅ deploy_vars.env.example
# ✅ docs/deploydebug/DEPLOYMENT_*.md
# ✅ tests/debug_deployment.sh
# ✅ tests/test_deployment.sh
# ✅ autoplanner/settings.py (修复后)
```

---

## 📤 正确的推送流程

### 完整步骤

```bash
# 1. 确保在项目根目录
cd /Users/jiaoyan/AutoPlanner

# 2. 检查 Git 状态
git status

# 3. 查看要推送的内容（不包括已忽略的文件）
git diff --cached  # 如果已经 add，则查看这个

# 4. 添加所有合法文件
git add .

# 5. 再次验证（确保没有敏感文件）
git status | grep -E "(deploy_vars|\.env|webclient)"
# 应该返回空

# 6. 提交
git commit -m "feat: AutoPlanner deployment to Cloud Run - complete debugging and fix SSL/TLS configuration

- Add deployment debugging scripts and reports
- Fix DJANGO_ALLOWED_HOSTS to include Cloud Run URLs
- Fix SECURE_SSL_REDIRECT loop by trusting X-Forwarded-Proto header
- Add environment variable files for Cloud Run deployment
- Create comprehensive testing and diagnostic tools"

# 7. 推送
git push origin main
```

---

## 🔐 敏感信息处理最佳实践

### 部署变量管理

**方法 A: 本地文件 (当前方式)**
- ✅ 开发时方便
- ❌ 容易意外推送
- 保护方式: 在 `.gitignore` 中
- 恢复方式: 从安全备份或设置管理系统获取

**方法 B: Google Secret Manager (推荐用于生产)**
```bash
# 存储密钥
gcloud secrets create DJANGO_SECRET_KEY --data-file=-

# 在 Cloud Run 部署时引用
gcloud run deploy autoplanner \
  --set-env-vars DJANGO_SECRET_KEY=projects/PROJECT_ID/secrets/DJANGO_SECRET_KEY/versions/latest
```

**方法 C: Cloud Build Secrets (CI/CD)**
- 在 Cloud Build 配置中引用 Secret Manager
- GitHub Actions 的 Secrets

### 代码审查清单

推送前，运行:
```bash
# 搜索可能的密钥泄露
git diff --cached | grep -E "(SECRET|PASSWORD|KEY|TOKEN|API)" 

# 检查大文件
git diff --cached --name-only | xargs -I {} git diff --cached {} | wc -l
```

---

## 🚪 如果意外推送了敏感信息

### 紧急处理步骤

```bash
# 1. 立即建议安全人员轮换所有密钥

# 2. 从 Git 历史中移除文件 (使用 BFG Repo-Cleaner)
# 安装: brew install bfg
bfg --delete-files deploy_vars.env
bfg --replace-text passwords.txt

# 3. 强制推送 (仅在 GitHub 账户的私有仓库中)
git reflog expire --expire=now --all && git gc --prune=now
git push origin --force-with-lease

# 4. 通知受影响的服务
# - 轮换 Google API 密钥
# - 重设数据库密码
# - 更新 OAuth 凭证
```

---

## 📝 文件推送检查表

```bash
✅ 要推送的文件:
  ├── docs/deploydebug/
  │   ├── DEPLOYMENT_COMPLETE.md
  │   ├── DEPLOYMENT_DEBUG_REPORT.md
  │   └── DEBUG_REPORT_FINAL.md
  ├── tests/
  │   ├── test_deployment.sh
  │   └── debug_deployment.sh
  ├── deploy_vars.env.example
  ├── .gitignore (已更新)
  ├── .env.production (仅参考)
  ├── autoplanner/settings.py (SSL/TLS 修复)
  └── README.md 的部署说明

❌ 不要推送:
  ├── deploy_vars.env (敏感信息)
  ├── .env (本地环境)
  ├── webclient.json (OAuth 凭证)
  ├── db.sqlite3 (本地数据库)
  └── .venv/ (虚拟环境)
```

---

## 🔍 验证命令集合

```bash
# 完整验证所有步骤
#!/bin/bash

echo "🔐 GitHub 推送安全性检查"
echo "=========================="

echo "\n1️⃣  检查 .gitignore 完整性..."
grep -E "(deploy_vars\.env|webclient\.json)" .gitignore && echo "✅ 敏感文件配置正确" || echo "❌ 缺少配置"

echo "\n2️⃣  检查已跟踪的敏感文件..."
SENSITIVE_FILES=$(git ls-files | grep -E "(deploy_vars\.env$|^\.env|webclient\.json|db\.sqlite3)")
if [ -z "$SENSITIVE_FILES" ]; then
    echo "✅ 没有敏感文件被跟踪"
else
    echo "❌ 发现被跟踪的敏感文件:"
    echo "$SENSITIVE_FILES"
fi

echo "\n3️⃣  检查工作目录中的敏感文件..."
if [ -f "deploy_vars.env" ] && ! grep "deploy_vars.env" .gitignore > /dev/null; then
    echo "⚠️  deploy_vars.env 存在但未被忽略"
else
    echo "✅ 敏感文件已被忽略"
fi

echo "\n4️⃣  显示要提交的文件列表..."
git status --short

echo "\n✅ 检查完成!"
```

---

## 📚 相关文档位置

```
项目根目录/
└── docs/
    ├── deploydebug/
    │   ├── DEPLOYMENT_COMPLETE.md (你在这里)
    │   ├── DEPLOYMENT_DEBUG_REPORT.md
    │   └── DEBUG_REPORT_FINAL.md
    └── README.md (项目文件)

部署配置:
├── deploy_vars.env (⚠️ 敏感 - 不推送)
├── deploy_vars.env.example (✅ 推送)
├── .env.production (⚠️ 本地参考)
└── .gitignore (✅ 推送 - 关键!)
```

---

## 🎯 总结

### 可以安全地推送吗? ✅ 可以

只要:
1. ✅ `deploy_vars.env` 在 `.gitignore` 中 (**已完成**)
2. ✅ 验证 `git status` 中没有敏感文件 
3. ✅ `deploy_vars.env.example` 被推送作为模板
4. ✅ 部署脚本和文档被推送

### 推送后: 
- 同事可以克隆仓库
- 他们复制 `deploy_vars.env.example` 为 `deploy_vars.env`
- 他们填入自己的敏感信息
- 该文件对他们保持本地，不会被推送

---

**✨ 您的项目现在可以安全地推送到 GitHub!**

建议: 添加一个 `SECURITY.md` 文件说明如何报告安全问题。
