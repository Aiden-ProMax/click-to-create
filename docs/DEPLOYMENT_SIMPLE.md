# 🚀 部署指南（简单版）

> **关键点：仅手动部署，无自动触发。**

---

## 部署就这么简单

```bash
./deploy_with_oauth.sh
```

**完成。** 就这么简单。

---

## 什么时候部署？

- 需要修复 bug 时
- 需要更新 API Key 时
- 需要推新功能时

**其他都不要碰。**

---

## 部署前检查清单

```bash
git status              # ✅ 工作区干净
git log -1 --oneline   # ✅ 确认代码版本
```

没问题？继续：

```bash
./deploy_with_oauth.sh
```

**就是这样。**

---

## 如果需要换版本

### 切换到新版本
```bash
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00022-9vg=100 \
  --region=us-west2
```

### 紧急回滚
```bash
gcloud run services update-traffic clickcreate \
  --to-revisions clickcreate-00015-sh8=100 \
  --region=us-west2
```

---

## 关键事实

| 项 | 说明 |
|----|------|
| **部署脚本** | `deploy_with_oauth.sh` （手动执行） |
| **区域** | us-west2 |
| **自动部署** | ❌ 没有。完全手动。 |
| **GitHub Actions** | ❌ 已删除 |
| **Webhooks** | ❌ 无 |
| **定时任务** | ❌ 无 |

---

## 记住这一点

🎯 **没有任何东西会自动部署。**

- Push 代码不会自动部署
- 提交 PR 不会自动部署  
- 定时不会自动部署
- 任何 webhook 都不会触发

**只有你手动执行 `./deploy_with_oauth.sh` 才会部署。**

---

**需要帮助？查看** [../DEPLOYMENT_POLICY.md](../DEPLOYMENT_POLICY.md)
