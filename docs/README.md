# 📚 AutoPlanner 文档中心

欢迎来到 AutoPlanner 完整文档。本目录包含项目的所有文档和资源。

---

## 📂 目录结构

### 🚀 [DEPLOYMENT/](DEPLOYMENT/) - Google Cloud Run 部署指南
包含完整的 Google Cloud Run 部署文档。

**开始**: [DEPLOYMENT/00-START-HERE.md](DEPLOYMENT/00-START-HERE.md)

**包含**:
- 完整部署指南（10 步）
- Gemini AI 助手提示词
- 快速参考卡片
- 故障排查指南

**状态**: ✅ 100% 就绪

---

### 🐛 [BUG_FIX/](BUG_FIX/) - Bug 修复文档
记录所有已修复的 Bug 和修复过程。

**状态**: ✅ 2026-02-10 完成

**包含**:
- Bug 修复总结
- 修复细节说明
- 验证步骤

---

## 📖 项目文档

### 核心文档

| 文件 | 说明 |
|------|------|
| [PROGRESS.md](PROGRESS.md) | 项目进度总结（更新至 2026-02-05） |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 应用架构和模块划分 |
| [QUICK_START.md](QUICK_START.md) | 本地快速开始指南 |

### API 和集成

| 文件 | 说明 |
|------|------|
| [AI_API.md](AI_API.md) | AI 处理 API 文档 |
| [AI_PROMPTS.md](AI_PROMPTS.md) | Gemini API 使用示例 |
| [GOOGLE_OAUTH_GUIDE.md](GOOGLE_OAUTH_GUIDE.md) | Google OAuth 配置指南 |

### 其他文档

| 文件 | 说明 |
|------|------|
| [SYSTEM_CHECK.md](SYSTEM_CHECK.md) | 系统检查和验证 |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | 测试指南 |
| [CONTEXT.md](CONTEXT.md) | 项目上下文信息 |
| [DECISIONS.md](DECISIONS.md) | 设计决策和权衡 |
| [OPS_LOG.md](OPS_LOG.md) | 运维日志 |

---

## 🎯 按用途查找

### "我想快速部署应用到 Cloud Run"
👉 [DEPLOYMENT/00-START-HERE.md](DEPLOYMENT/00-START-HERE.md)

### "我想了解项目进度"
👉 [PROGRESS.md](PROGRESS.md)

### "我想理解应用架构"
👉 [ARCHITECTURE.md](ARCHITECTURE.md)

### "我想本地启动项目"
👉 [QUICK_START.md](QUICK_START.md)

### "我想了解 AI 功能"
👉 [AI_API.md](AI_API.md)

### "我想配置 Google OAuth"
👉 [GOOGLE_OAUTH_GUIDE.md](GOOGLE_OAUTH_GUIDE.md)

### "我想运行测试"
👉 [TESTING_GUIDE.md](TESTING_GUIDE.md)

### "我想了解 Bug 修复"
👉 [BUG_FIX/README.md](BUG_FIX/README.md)

---

## 📊 项目状态总览

```
✅ 核心功能.......... 100% 完成
   - Django 应用框架
   - REST API 接口
   - 用户认证系统
   - AI 驱动的事件处理
   
✅ 集成功能.......... 100% 完成
   - Google Calendar OAuth
   - Gemini API 集成
   - 事件同步
   
✅ 部署准备.......... 100% 完成
   - Docker 容器化
   - Cloud Run 配置
   - Secret Manager 集成
   - 环境变量管理
   
✅ 文档齐全.......... 100% 完成
   - API 文档
   - 部署指南
   - 测试指南
   - 架构说明
```

---

## 🚀 推荐阅读顺序

### 如果您是新手开发者
1. [QUICK_START.md](QUICK_START.md) - 本地快速开始
2. [ARCHITECTURE.md](ARCHITECTURE.md) - 理解架构
3. [PROGRESS.md](PROGRESS.md) - 了解功能

### 如果您要部署到生产
1. [DEPLOYMENT/00-START-HERE.md](DEPLOYMENT/00-START-HERE.md)
2. [DEPLOYMENT/01-DEPLOYMENT-GUIDE.md](DEPLOYMENT/01-DEPLOYMENT-GUIDE.md) 或其他方式
3. [DEPLOYMENT/05-DEPLOYMENT-READY.md](DEPLOYMENT/05-DEPLOYMENT-READY.md)

### 如果您要集成 API
1. [AI_API.md](AI_API.md)
2. [GOOGLE_OAUTH_GUIDE.md](GOOGLE_OAUTH_GUIDE.md)
3. [AI_PROMPTS.md](AI_PROMPTS.md)

### 如果您要运行测试
1. [TESTING_GUIDE.md](TESTING_GUIDE.md)
2. [../tests/README.md](../tests/README.md)

---

## 📞 获取帮助

- **部署相关**: 查看 [DEPLOYMENT/](DEPLOYMENT/) 目录
- **Bug 修复**: 查看 [BUG_FIX/](BUG_FIX/) 目录
- **API 相关**: 查看 [AI_API.md](AI_API.md)
- **架构问题**: 查看 [ARCHITECTURE.md](ARCHITECTURE.md)
- **测试相关**: 查看 [../tests/README.md](../tests/README.md)

---

## 📅 最后更新

| 模块 | 日期 | 状态 |
|------|------|------|
| 项目核心 | 2026-02-05 | ✅ |
| 部署指南 | 2026-02-19 | ✅ |
| Bug 修复 | 2026-02-10 | ✅ |
| 文档整理 | 2026-02-19 | ✅ |

---

## 🎉 一句话总结

AutoPlanner 是一个功能完善的智能日程规划应用，包含完整的 Django 后端、REST API、Google Calendar 集成和 AI 自然语言处理。已完全准备好部署到 Google Cloud Run。

---

**👉 快速开始**: [DEPLOYMENT/00-START-HERE.md](DEPLOYMENT/00-START-HERE.md)
