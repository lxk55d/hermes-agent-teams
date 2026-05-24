#!/bin/bash
# ============================================================
# Hermes Agent Teams — 一键启动脚本
# ============================================================
# 用法:
#   bash scripts/launch.sh "实现用户登录功能"              # 默认 3 角色
#   bash scripts/launch.sh "实现限流中间件" full            # 4 角色
#   bash scripts/launch.sh "重构 util 模块" explorer        # 探索型
# ============================================================
# 自动检查:
#   - Profiles 是否创建（没有则自动创建）
#   - Gateway 是否运行（没有则自动启动）
#   - Kanban 是否初始化（没有则自动初始化）
# ============================================================

GOAL="$1"
TEAM_TYPE="${2:-compact}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -z "$GOAL" ]; then
    echo "用法: bash scripts/launch.sh \"需求描述\" [团队类型]"
    echo ""
    echo "团队类型:"
    echo "  (留空)    3 角色: Planner → Coder → Tester"
    echo "  full      4 角色: Planner → Challenger → Coder → Tester"
    echo "  explorer  3 角色: Explorer → Coder → Reviewer"
    echo ""
    echo "示例:"
    echo "  bash scripts/launch.sh \"实现用户登录功能\""
    echo "  bash scripts/launch.sh \"实现限流中间件\" full"
    echo "  bash scripts/launch.sh \"重构 util 模块\" explorer"
    exit 1
fi

case "$TEAM_TYPE" in
    full)      TEAM_LABEL="4 角色标准团队 (Planner→Challenger→Coder→Tester)" ;;
    explorer)  TEAM_LABEL="3 角色探索型团队 (Explorer→Coder→Reviewer)" ;;
    *)         TEAM_LABEL="3 角色精简团队 (Planner→Coder→Tester)" ;;
esac

echo ""
echo "=============================================="
echo "  Hermes Agent Teams — $TEAM_LABEL"
echo "  需求: $GOAL"
echo "=============================================="

# ==========================================
# Step 1: 创建/检查 Profiles
# ==========================================
echo ""
echo "[1/5] 检查团队 Profiles..."
if [ -f "$SKILL_DIR/scripts/setup-profiles.sh" ]; then
    bash "$SKILL_DIR/scripts/setup-profiles.sh"
fi

# ==========================================
# Step 2: 检查并启动 Gateway
# ==========================================
echo ""
echo "[2/5] 检查 Gateway 状态..."
GATEWAY_RUNNING=false

GW_STATUS=$(hermes gateway status 2>&1)
if echo "$GW_STATUS" | grep -qi "running"; then
    echo "  ✅ Gateway 运行中"
    GATEWAY_RUNNING=true
else
    echo "  ⚠️  Gateway 未运行，尝试启动..."
    # 尝试 systemd 模式
    if systemctl --user start hermes-gateway 2>/dev/null; then
        echo "    通过 systemd 启动成功"
        sleep 2
        GATEWAY_RUNNING=true
    # 尝试 CLI 启动
    elif hermes gateway start 2>&1 | grep -qi "started\|running"; then
        echo "    通过 CLI 启动成功"
        sleep 2
        GATEWAY_RUNNING=true
    else
        echo "    尝试后台进程启动..."
        nohup hermes gateway run > /dev/null 2>&1 &
        GW_PID=$!
        sleep 3
        if kill -0 "$GW_PID" 2>/dev/null; then
            echo "    后台进程已启动 (PID=$GW_PID)"
            GATEWAY_RUNNING=true
        else
            echo "  ⚠️  无法自动启动 Gateway"
            echo "    任务将创建但 dispatcher 不会自动路由"
            echo "    请手动运行: hermes gateway start"
        fi
    fi
fi

if [ "$GATEWAY_RUNNING" = true ]; then
    echo "  ✅ Dispatcher 就绪，任务将自动路由到对应 Profile"
else
    echo "  ⚠️  任务将停留在看板中，需手动 dispatch"
fi

# ==========================================
# Step 3: 初始化 Kanban
# ==========================================
echo ""
echo "[3/5] 初始化 Kanban..."
hermes kanban init 2>/dev/null || true

# ==========================================
# Step 4: 创建任务链
# ==========================================
echo ""
echo "[4/5] 创建任务链..."

case "$TEAM_TYPE" in
    full)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "需求: $GOAL. 拆解为具体的开发任务. 定义依赖关系. 标注受影响文件." \
            "[Plan] 分析需求: $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)

        R2=$(hermes kanban create --assignee challenger --priority 2 \
            --parent "$ID1" \
            --body "审查计划. 指出至少3个风险或确认无重大风险. 不修改文件." \
            "[Challenge] 审查计划方案" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)

        R3=$(hermes kanban create --assignee coder --priority 3 \
            --parent "$ID1" --parent "$ID2" \
            --body "按已批准计划实现. 不扩展范围. 目标: $GOAL" \
            "[Code] 实现: $GOAL" 2>&1)
        echo "  $R3" | head -1
        ID3=$(echo "$R3" | grep -o 't_[a-f0-9]*' | head -1)

        R4=$(hermes kanban create --assignee tester --priority 4 \
            --parent "$ID3" \
            --body "写测试并验证. 不改业务代码. 报告通过/失败/未测试. 目标: $GOAL" \
            "[Test] 验证: $GOAL" 2>&1)
        echo "  $R4" | head -1
        ;;

    explorer)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "勘探代码库. 识别相关文件. 评估技术选项. 不实现代码." \
            "[Explore] 代码库勘探: $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)

        R2=$(hermes kanban create --assignee coder --priority 2 \
            --parent "$ID1" \
            --body "按探索结果实现. 不扩展范围. 目标: $GOAL" \
            "[Code] 小范围实现: $GOAL" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)

        R3=$(hermes kanban create --assignee tester --priority 3 \
            --parent "$ID2" \
            --body "审查代码质量. 安全漏洞. 性能影响. 不要修改代码." \
            "[Review] 代码审查" 2>&1)
        echo "  $R3" | head -1
        ;;

    *)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "需求: $GOAL. 拆解任务. 定义顺序. 标注受影响文件. 只输出计划." \
            "[Plan] 分析需求: $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)

        R2=$(hermes kanban create --assignee coder --priority 2 \
            --parent "$ID1" \
            --body "按计划实现. 不扩展范围. 目标: $GOAL" \
            "[Code] 实现: $GOAL" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)

        R3=$(hermes kanban create --assignee tester --priority 3 \
            --parent "$ID2" \
            --body "写测试并验证. 不改业务代码. 报告通过/失败/未测试." \
            "[Test] 验证: $GOAL" 2>&1)
        echo "  $R3" | head -1
        ;;
esac

# ==========================================
# Step 5: 显示看板 + 总结
# ==========================================
echo ""
echo "[5/5] 看板状态:"
hermes kanban ls --sort priority 2>&1 | head -20

echo ""
if [ "$GATEWAY_RUNNING" = true ]; then
    echo "✅ 所有任务已创建，dispatcher 自动路由到对应 Profile！"
else
    echo "✅ 任务已创建，但 Gateway 未运行。需要手动 dispatch："
    echo "   hermes gateway start"
fi
echo ""
echo "=============================================="
echo "  实时监控进度:  hermes kanban tail"
echo "  查看任务详情:  hermes kanban show <id>"
echo "  中断重置任务:  hermes kanban reclaim <id>"
echo "  重新分配任务:  hermes kanban assign <id> <profile>"
echo "=============================================="