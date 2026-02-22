#!/bin/bash

# 获取详细的云日志

cd "$(dirname "$0")" || exit 1

source deploy_vars.env 2>/dev/null

echo "🔎 获取最近的完整错误日志..."
echo "================================================================"
echo ""

gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=clickcreate AND severity=ERROR" \
  --limit=10 \
  --format='value(textPayload,jsonPayload)' \
  --project=$PROJECT_ID 2>/dev/null | head -50

echo ""
echo "================================================================"
echo ""
echo "📊 检查部署版本信息..."
gcloud run services describe clickcreate \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format='table(
    status.traffic[0].revisionName,
    status.traffic[0].percent,
    metadata.generation
  )' 2>/dev/null

echo ""
echo "📋 检查环境变量..."
gcloud run services describe clickcreate \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format=json 2>&1 | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    env_vars = data['spec']['template']['spec']['containers'][0]['env']
    for var in sorted(env_vars, key=lambda x: x['name']):
        name = var['name']
        val = var['value']
        if 'KEY' in name or 'PASS' in name:
            val = val[:20] + '...' if len(val) > 20 else val
        print(f'{name}: {val}')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null

echo ""
echo "✅ 诊断完成"
