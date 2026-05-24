# Hermes Agent Teams

> 将 Claude Code Agent Teams 的多 Agent 协作模式，移植到 Hermes Agent 生态中。
> 用 Hermes Profile + Kanban 实现 Planner → Challenger → Coder → Tester 团队协作。
> 无需 Claude Code、无需 Anthropic API，任何 LLM 提供商都能用。

## 快速开始

```bash
# 1. 安装 skill
hermes skills install https://raw.githubusercontent.com/<你的用户名>/<仓库名>/main/SKILL.md

# 2. 启动团队
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh "实现用户登录"

# 启动 4 角色团队
bash ~/.hermes/skills/autonomous-ai-agents/hermes-agent-teams/scripts/launch.sh "实现限流中间件" full
```

## 文件结构

```
hermes-agent-teams/
├── SKILL.md               # 主技能文件（含完整文档 + 脚本内容）
└── scripts/
    ├── setup-profiles.sh   # 创建团队 Profiles
    └── launch.sh           # 一键启动（自动检查 Profiles/Gateway/Kanban）
```

## 三种团队模板

| 模板 | 角色 | 命令 |
|------|------|------|
| 精简 3 角色 | Planner → Coder → Tester | `launch.sh "需求"` |
| 标准 4 角色 | Planner → Challenger → Coder → Tester | `launch.sh "需求" full` |
| 探索型 3 角色 | Explorer → Coder → Reviewer | `launch.sh "需求" explorer` |

## 触发关键词

在 Hermes 会话中，提到以下关键词自动加载此 Skill：

- 搭建 Agent 团队
- multi-agent / agent collaboration
- 设置 Planner + Coder + Tester
- AI 分工开发
- code review pipeline
- agent orchestration

## 环境要求

- Hermes Agent（2026年5月后版本）
- 任意 LLM 提供商
- Bash shell（Linux / macOS / WSL）

## 许可

MIT
