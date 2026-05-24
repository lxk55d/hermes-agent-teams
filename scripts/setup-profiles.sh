#!/bin/bash
# Hermes Agent Teams — 一键创建团队 Profiles
# Usage: bash scripts/setup-profiles.sh
set -e

echo "=== Hermes Agent Teams — 创建团队 Profiles ==="

for role in planner challenger coder tester; do
    echo ""
    echo "[$role]"
    if hermes profile list 2>/dev/null | grep -qw "$role"; then
        echo "  已存在，跳过创建"
    else
        hermes profile create "$role" --clone-from default --clone 2>&1
        echo "  创建完成"
    fi
    # 只读角色限制工具
    if [ "$role" = "planner" ] || [ "$role" = "challenger" ]; then
        hermes tools disable terminal --profile "$role" 2>/dev/null || true
        hermes tools disable file --profile "$role" 2>/dev/null || true
        echo "  工具已限制（只读）"
    else
        echo "  全权限"
    fi
done

echo ""
echo "=== 当前 Profiles ==="
hermes profile list
echo ""
echo "完成。用 launch.sh 启动团队。"
