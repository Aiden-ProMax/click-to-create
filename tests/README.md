# 测试文件目录

本目录包含 AutoPlanner 项目的所有测试文件。

## 📋 测试文件

| 文件 | 用途 |
|------|------|
| `test_ai_flow.py` | AI 流程完整测试 |
| `test_api_endpoints.py` | API 端点功能测试 |
| `test_api_integration.py` | 集成测试（用户、登录、事件） |
| `test_google_sync.py` | Google Calendar 同步测试 |
| `test_normalize_schedule.py` | 数据规范化和调度测试 |
| `verify_fix.py` | Bug 修复验证脚本 |
| `test_api_curl.sh` | curl 命令测试脚本 |

## 🚀 运行测试

### 单个测试
```bash
python manage.py test ai.tests
python manage.py test tests.test_api_endpoints
```

### 运行所有测试
```bash
python manage.py test
```

### 手动测试（curl）
```bash
bash tests/test_api_curl.sh
```

## ✅ 验证修复
```bash
python tests/verify_fix.py
```

---

**最后更新**: 2026-02-19
