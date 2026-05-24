---
name: hermes-agent-teams
description: "搭建 Agent 团队 / multi-agent / agent collaboration / AI 分工开发 / code review pipeline / agent orchestration. Multi-agent development teams using Hermes profiles + Kanban. Triggers on: '搭建 Agent 团队', '设置 Planner + Coder + Tester', 'AI 分工开发', 'code review pipeline', 'agent orchestration', 'agent collaboration', 'multi-agent'. Implements the Agent Teams pattern — Planner → Challenger → Coder → Tester — using Hermes-native only (no Claude Code needed). Works with any LLM provider."
version: 1.1.0
author: Hermes Agent Team
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [multi-agent, kanban, profiles, orchestration, workflow, agent-teams, code-review-pipeline, ai-collaboration, agent-orchestration, planner-coder-tester, dev-workflow]
    related_skills: [kanban-orchestrator, kanban-worker, hermes-agent]
    homepage: https://github.com/lxk55d/hermes-agent-teams
---

# Hermes Agent Teams

> **将 Claude Code Agent Teams 的多 Agent 协作模式，移植到 Hermes Agent 生态中。**  
> 用 Hermes Profile + Kanban 实现 Planner → Challenger → Coder → Tester 团队协作，  
> 无需 Claude Code、无需 Anthropic API，任何 LLM 提供商都能用。

## 快速安装

### 方式一：一键安装（推荐）

```bash
# 从 URL 安装
hermes skills install https://raw.githubusercontent.com/lxk55d/hermes-agent-teams/main/SKILL.md

# 或从技能市场搜索安装
hermes skills search agent-teams
hermes skills install hermes-agent-teams
```

### 方式二：手动安装

```bash
# 1. 下载 SKILL.md
mkdir -p ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/
curl -o ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/SKILL.md \
  https://raw.githubusercontent.com/lxk55d/hermes-agent-teams/main/SKILL.md

# 2. 创建脚本目录
mkdir -p ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/

# 3. 创建 setup-profiles.sh（见下方脚本内容）
# 4. 创建 launch.sh（见下方脚本内容）

# 5. 重新加载技能
hermes skills list
```

### 方式三：从 GitHub Tap 安装

```bash
hermes skills tap add lxk55d/hermes-agent-teams
hermes skills install hermes-agent-teams
```

---

## 触发关键词

当你的需求包含以下任意内容时，此 Skill 会自动加载：

| 关键词 | 场景示例 |
|--------|---------|
| 搭建 Agent 团队 | "帮我搭建 Agent 团队，实现用户登录" |
| multi-agent / agent collaboration | "用 multi-agent 方式重构这段代码" |
| 设置 Planner + Coder + Tester | "设置 Planner + Coder + Tester 分工开发" |
| AI 分工开发 / AI 分角色开发 | "来搞个 AI 分工开发，需要 code review" |
| code review pipeline | "启动 code review pipeline" |
| agent orchestration | "用 agent orchestration 调度这个任务" |

---

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│              Orchestrator (你的主 Hermes 会话)                 │
│   接收需求 → 拆解为 Kanban 任务 → 启动团队 → 汇总结果        │
└──────┬───────────────┬───────────────┬───────────┬──────────┘
       │               │               │           │
  ┌────▼────┐    ┌────▼────┐    ┌────▼────┐  ┌───▼────┐
  │ Planner │    │Challenger│    │  Coder  │  │ Tester │
  │ (只读)   │    │ (只读)   │    │ (读写)   │  │ (读写)  │
  │ profile │    │ profile  │    │ profile  │  │ profile │
  └────┬────┘    └────┬────┘    └────┬────┘  └────┬───┘
       │               │              │            │
       └───────────────┴─── Kanban Board ─────────┘
                          (SQLite-backed, 持久化)
```

### 核心概念映射

| 概念 | Hermes 实现 |
|------|------------|
| **Agent 角色定义** | `hermes profile create <role> --clone-from default --clone` |
| **只读权限控制** | `hermes tools disable terminal --profile <role>` |
| **任务池（持久化）** | Kanban board，SQLite 存储，崩溃可恢复 |
| **任务依赖链** | `kanban_create(parents=[id1, id2])` |
| **跨会话协作** | Dispatcher 自动路由 + profile 隔离 |
| **进度监控** | `hermes kanban tail` 实时看板 |

---

## 使用方法

### 一键启动（推荐）

```bash
# 精简 3 角色（默认）
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh "你的需求描述"

# 4 角色（含 Challenger 审查）
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh "实现限流中间件" full

# 探索型（先调研再实现）
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh "重构 util 模块" explorer
```

首次运行会自动：
1. ✅ 创建团队 Profile（如果不存在）
2. ✅ 检查并启动 Gateway（如果未运行）
3. ✅ 初始化 Kanban 看板
4. ✅ 创建带依赖链的任务
5. ✅ 显示看板状态

### 手动创建 Profiles

```bash
# 创建 4 个角色
hermes profile create planner --clone-from default --clone
hermes profile create challenger --clone-from default --clone
hermes profile create coder --clone-from default --clone
hermes profile create tester --clone-from default --clone

# 只读角色限制工具
hermes tools disable terminal --profile planner
hermes tools disable file --profile planner
hermes tools disable terminal --profile challenger
hermes tools disable file --profile challenger
```

### 工具权限策略

| Profile | 允许的工具集 | 说明 |
|---------|------------|------|
| **planner** | web, search, session_search | 只读。查资料、读代码，不能改文件 |
| **challenger** | web, search, session_search | 只读。审查计划，不能改计划 |
| **coder** | terminal, file, web, vision | 全权限。实现代码、跑构建 |
| **tester** | terminal, file, web | 全权限。写测试、跑测试套件 |
| **orchestrator** | kanban, delegation, terminal | 协调。创建任务链、汇总结果 |

---

## 团队模板

### 模板 A：标准 4 角色（质量优先）

```
Planner → Challenger → Coder → Tester
```

| 角色 | 职责 | 成本占比 |
|------|------|---------|
| **Planner** | 拆需求、定计划、输出依赖图 | ~10% |
| **Challenger** | 审查方案、找风险、提替代方案 | ~8% |
| **Coder** | 实现代码、按依赖逐任务开发 | ~55% |
| **Tester** | 写测试、跑验证、报告失败 | ~17% |
| **Orchestrator** | 创建任务链、汇总结果 | ~10% |

```bash
bash launch.sh "需求" full
```

### 模板 B：精简 3 角色（效率优先）

```
Planner → Coder → Tester
```

省掉 Challenger，降低成本 ~30%。适合需求明确、风险低的场景。

```bash
bash launch.sh "需求"
```

### 模板 C：探索型 3 角色（调研优先）

```
Explorer → Coder → Reviewer
```

适合需要先摸清代码库再做小范围修改的场景。

```bash
bash launch.sh "需求" explorer
```

---

## 任务生命周期

```
用户提出需求
    │
    ▼
[Orchestrator] 拆解 → 创建 Kanban 任务（带 parents 依赖）
    │
    ▼
[Planner] 分析请求 → 输出任务计划 + 依赖链
    │  kanban_complete(summary="...")
    ▼
[Challenger] 审查计划 → 输出风险清单
    │  批准 → kanban_complete(summary="approved")
    │  拒绝 → kanban_block(reason="需要修改")
    ▼
[Coder] 逐项实现 → 代码变更
    │  kanban_complete(summary="实现了X, Y, Z")
    ▼
[Tester] 逐项验证 → 测试报告
    │  通过 → kanban_complete(summary="14/14 tests pass")
    │  失败 → kanban_block(reason="test failures")
    ▼
[用户] 最终判断
```

---

## 编程式使用（在 Hermes 会话中）

```python
# 3 角色：分析 → 实现 → 验证
t1 = kanban_create(title="[Plan] 分析需求", assignee="planner",
    body="拆解为原子任务，标注受影响文件")
t2 = kanban_create(title="[Code] 实现功能", assignee="coder",
    body="按计划实现", parents=[t1])
t3 = kanban_create(title="[Test] 验证", assignee="tester",
    body="写测试并报告", parents=[t2])

# 4 角色：分析 → 审查 → 实现 → 验证
t1 = kanban_create(title="[Plan] 设计方案", assignee="planner", body="...")
t2 = kanban_create(title="[Challenge] 审查方案", assignee="challenger",
    body="至少指出 3 个风险", parents=[t1])
t3 = kanban_create(title="[Code] 实现", assignee="coder",
    body="按批准计划实现", parents=[t1, t2])
t4 = kanban_create(title="[Test] 测试", assignee="tester",
    body="写测试并报告", parents=[t3])
```

---

## 实测算力成本

> ⚠️ 按 token 计费环境下，多 Agent = 多倍成本。以下基于实际运行经验估算。

| 角色 | 调用次数 | Token 消耗 | 成本估测（¥） |
|------|---------|-----------|-------------|
| Orchestrator 拆解 | 2-3 | 30K-50K | ~¥0.1-0.18 |
| Planner 分析 | 3-5 | 50K-100K | ~¥0.18-0.36 |
| Challenger 审查 | 2-3 | 30K-60K | ~¥0.1-0.22 |
| Coder 实现 | 5-15 | 100K-500K | ~¥0.36-1.8 |
| Tester 验证 | 3-8 | 50K-200K | ~¥0.18-0.72 |
| **总计** | **15-34** | **260K-910K** | **~¥0.92-3.28** |

> 单 Agent 做同样任务约 ¥0.72（200K tokens），4 角色版本约 1.3-4.5 倍。**但质量提升减少了重试和修复成本，实际差距更小。**

### 省钱建议

1. **从 3 角色起步**（省掉 Challenger），成本降 ~30%
2. **复杂功能用 4 角色，简单 CRUD 单 Agent**
3. **给只读角色用更便宜的模型**（不同 Profile 可配不同模型）
4. **设置 API 日限额**防止失控
5. **运行 `kanban tail` 实时观察**，随时可中断

---

## 脚本内容

### scripts/setup-profiles.sh

将此文件保存至 `~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/setup-profiles.sh`：

```bash
#!/bin/bash
# 一键创建团队 Profiles
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
```

### scripts/launch.sh

将此文件保存至 `~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh`：

```bash
#!/bin/bash
# ============================================================
# Hermes Agent Teams — 一键启动脚本
# ============================================================
# 用法:
#   bash scripts/launch.sh "实现用户登录功能"            # 3 角色
#   bash scripts/launch.sh "实现限流中间件" full          # 4 角色
#   bash scripts/launch.sh "重构 util 模块" explorer      # 探索型
# ============================================================
# 自动检查: Profiles → Gateway → Kanban → 任务链
# ============================================================

GOAL="$1"
TEAM_TYPE="${2:-compact}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -z "$GOAL" ]; then
    echo "用法: bash scripts/launch.sh \"需求描述\" [团队类型]"
    echo "  团队类型: (留空)=3角色  full=4角色  explorer=探索型"
    exit 1
fi

case "$TEAM_TYPE" in
    full)      TEAM_LABEL="4 角色标准团队" ;;
    explorer)  TEAM_LABEL="3 角色探索型团队" ;;
    *)         TEAM_LABEL="3 角色精简团队" ;;
esac

echo ""
echo "=============================================="
echo "  Hermes Agent Teams — $TEAM_LABEL"
echo "  需求: $GOAL"
echo "=============================================="

# Step 1: Profiles
echo ""
echo "[1/5] 检查团队 Profiles..."
if [ -f "$SKILL_DIR/scripts/setup-profiles.sh" ]; then
    bash "$SKILL_DIR/scripts/setup-profiles.sh"
fi

# Step 2: Gateway
echo ""
echo "[2/5] 检查 Gateway 状态..."
GATEWAY_RUNNING=false
GW_STATUS=$(hermes gateway status 2>&1)
if echo "$GW_STATUS" | grep -qi "running"; then
    echo "  ✅ Gateway 运行中"
    GATEWAY_RUNNING=true
else
    echo "  ⚠️  Gateway 未运行，尝试启动..."
    if systemctl --user start hermes-gateway 2>/dev/null; then
        echo "    通过 systemd 启动成功"
        sleep 2; GATEWAY_RUNNING=true
    elif hermes gateway start 2>&1 | grep -qi "started\|running"; then
        echo "    通过 CLI 启动成功"
        sleep 2; GATEWAY_RUNNING=true
    else
        nohup hermes gateway run > /dev/null 2>&1 &
        GW_PID=$!; sleep 3
        if kill -0 "$GW_PID" 2>/dev/null; then
            echo "    后台进程已启动 (PID=$GW_PID)"
            GATEWAY_RUNNING=true
        else
            echo "  ⚠️  无法自动启动，请手动: hermes gateway start"
        fi
    fi
fi
[ "$GATEWAY_RUNNING" = true ] && echo "  ✅ Dispatcher 就绪" \
    || echo "  ⚠️  任务将停留在看板中"

# Step 3: Kanban
echo ""
echo "[3/5] 初始化 Kanban..."
hermes kanban init 2>/dev/null || true

# Step 4: 创建任务
echo ""
echo "[4/5] 创建任务链..."

case "$TEAM_TYPE" in
    full)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "需求: $GOAL. 拆解任务. 定义依赖. 标注文件." \
            "[Plan] $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)
        R2=$(hermes kanban create --assignee challenger --priority 2 \
            --parent "$ID1" --body "审查计划. 指出≥3风险." \
            "[Challenge] 审查计划" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)
        R3=$(hermes kanban create --assignee coder --priority 3 \
            --parent "$ID1" --parent "$ID2" \
            --body "按批准计划实现. 目标: $GOAL" \
            "[Code] $GOAL" 2>&1)
        echo "  $R3" | head -1
        ID3=$(echo "$R3" | grep -o 't_[a-f0-9]*' | head -1)
        R4=$(hermes kanban create --assignee tester --priority 4 \
            --parent "$ID3" --body "写测试并验证. 不改业务代码." \
            "[Test] 验证" 2>&1)
        echo "  $R4" | head -1
        ;;
    explorer)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "勘探代码库. 识别相关文件. 不实现代码." \
            "[Explore] $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)
        R2=$(hermes kanban create --assignee coder --priority 2 \
            --parent "$ID1" --body "按探索结果实现. 目标: $GOAL" \
            "[Code] $GOAL" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)
        R3=$(hermes kanban create --assignee tester --priority 3 \
            --parent "$ID2" --body "审查代码质量. 不改代码." \
            "[Review] 代码审查" 2>&1)
        echo "  $R3" | head -1
        ;;
    *)
        R1=$(hermes kanban create --assignee planner --priority 1 \
            --body "需求: $GOAL. 拆解任务. 标注文件. 只输出计划." \
            "[Plan] $GOAL" 2>&1)
        echo "  $R1" | head -1
        ID1=$(echo "$R1" | grep -o 't_[a-f0-9]*' | head -1)
        R2=$(hermes kanban create --assignee coder --priority 2 \
            --parent "$ID1" --body "按计划实现. 目标: $GOAL" \
            "[Code] $GOAL" 2>&1)
        echo "  $R2" | head -1
        ID2=$(echo "$R2" | grep -o 't_[a-f0-9]*' | head -1)
        R3=$(hermes kanban create --assignee tester --priority 3 \
            --parent "$ID2" --body "写测试并验证. 不改业务代码." \
            "[Test] 验证" 2>&1)
        echo "  $R3" | head -1
        ;;
esac

# Step 5: 看板
echo ""
echo "[5/5] 看板状态:"
hermes kanban ls --sort priority 2>&1 | head -20
echo ""
if [ "$GATEWAY_RUNNING" = true ]; then
    echo "✅ 已启动！dispatcher 自动路由中..."
else
    echo "✅ 任务已创建，需手动: hermes gateway start"
fi
echo ""
echo "  实时监控: hermes kanban tail"
echo "  查看详情: hermes kanban show <id>"
echo "  中断任务: hermes kanban reclaim <id>"
echo "  重新分配: hermes kanban assign <id> <profile>"
```

---

## 硬边界规则

将此规则写入每个 Profile 的 instructions（`~/.hermes/profiles/<name>/config.yaml` 的 `agent.instructions`）：

```
## Agent Team 硬边界
1. Planner 只输出计划，不修改任何代码文件
2. Challenger 必须指出至少 3 个风险，或声明"无重大风险"
3. Coder 只处理 assigned 的 Kanban 任务，不自行新增
4. Tester 不改业务代码，除非明确授权
5. 发现范围扩大，立即 kanban_block 报告
6. 同一任务失败 3 次，标记 blocked，等待人工
7. 完成时输出结构化 metadata（changed_files, tests_passed）
```

---

## 与 kanban-orchestrator 的关系

| 维度 | kanban-orchestrator | hermes-agent-teams |
|------|--------------------|-------------------|
| 专注 | 通用任务路由 | Planner/Challenger/Coder/Tester 团队 |
| 角色 | 无预设 | 4 种预设角色 + 权限配置 |
| 制衡 | 无强制 | Challenger 审查 + Tester 验证 |
| 启动 | 手动 kanban_create | 一键脚本 launch.sh |

**组合使用**：`kanban-orchestrator` 做通用路由 + `hermes-agent-teams` 做标准开发团队。

---

## 验证清单

- [ ] `hermes profile list` 确认所有角色已创建
- [ ] planner / challenger 已限制 terminal + file 权限
- [ ] `hermes kanban init` 初始化看板
- [ ] Gateway 运行中（`hermes gateway status`）
- [ ] 在测试项目上运行一次完整流程
- [ ] 设置 API 消费上限
- [ ] 团队不超过 4 角色（建议 3 角色起步）

---

## 常见问题

### Dispatcher 在哪里运行？
Gateway 内嵌 dispatcher（`kanban.dispatch_in_gateway: true`）。Gateway 未运行时用 `hermes kanban daemon` 启动独立调度器。

### 一个 Profile 能处理多个任务吗？
可以。同一 Profile 的任务按优先级序列化执行。

### Coder 改完文件但测试失败？
Tester `kanban_block` 阻塞 → Dispatcher 通知 Coder 重做。**同任务重试不超过 3 次**。

### 和 delegate_task 什么区别？
`delegate_task` 同步一次性委托，崩溃丢失。Kanban 持久化到 SQLite，崩溃恢复，可跨天运行。

### WSL 网关问题？
参考 `hermes-agent` skill 中的 WSL 网关故障排除。确保 `/etc/wsl.conf` 中 `systemd=true`。

---

## 参考

- [Claude Code Agent Teams 原文](https://dev.to/nfrankel/designing-a-team-of-agents-j1b)
- [Hermes Kanban 文档](https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban)
- [Hermes Profiles 文档](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)
