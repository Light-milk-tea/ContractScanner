---
name: commit-as-prompt
description: >-
  Creates structured Git commits with WHAT/WHY/HOW bodies (Commit-as-Prompt),
  splits unrelated changes, and aggregates prompt: commits into an AI <Context>
  block. Use when the user asks to commit, write commit messages, /commit-as-prompt,
  Commit-as-Prompt, WHAT/WHY/HOW commits, generate context from git history, or
  when git push fails due to SSH/proxy/fake-ip (e.g. Connection closed by 198.18.x).
---

# Commit-as-Prompt

将 Git 提交写成可供 AI 复用的结构化知识：标题用约定前缀，正文用 WHAT / WHY / HOW。

角色：Commit-to-Prompt Engineer。职责是按主题拆分提交、写清意图，并在需要时聚合 `prompt:` 提交为 `<Context>`。

## 何时使用

- 用户要求提交、写 commit message、`/commit-as-prompt`
- 需要按 WHAT/WHY/HOW 规范提交
- 需要从 `prompt:` 历史生成 AI 上下文

## Commit 类型

| 类型 | 标题前缀 | 是否进入 Prompt 聚合 |
|------|----------|----------------------|
| Context Prompt | `prompt(scope): 主题` | 是 |
| 常规变更 | Conventional Commits：`feat:` / `fix:` / `docs:` 等 | 否（正文仍建议 WHAT/WHY/HOW） |

两类变更分别提交，不要混在同一次 commit。

## 执行流程（按顺序）

### 1. 检查变更

```bash
git status -s
git diff
git diff --cached
git log -5 --oneline
```

并行跑 status / diff / log，再决定如何拆分与写消息。

### 2. 理解后再清理（可选）

先读懂相关代码；没把握就不要改。可清理：

- 无用导入、死代码
- 临时日志 / 调试（`console.log`、`debugger`）
- 临时命名（`TEMP`、`TEST`、`V2`）
- 临时脚手架或一次性文档

### 3. 挑选文件并拆分主题

```bash
git add <file> ...
```

原则：

- 只纳入实现当前主题所需的代码、配置、测试、文档
- 格式化、依赖升级、大规模重命名 → **独立提交**
- 多主题 → **多次提交**
- 不要用交互式 `git add -p` / `git add -i`（环境不支持交互）

### 4. 编写提交信息

**标题**：简洁祈使句，避免「修复 bug」「更新代码」。

**正文**（每条提交）：

```
WHAT: ...
WHY: ...
HOW: ...
```

编写要点：

- **WHAT**：一句话，动作 + 对象，无实现细节
- **WHY**：业务/用户/架构动机；可引用 `Fixes #1234`
- **HOW**：策略、兼容性、验证、风险与影响；不罗列文件（diff 已有）

### 5. 提交

仅在用户明确要求提交时执行。用 HEREDOC，避免 `-i` / `--no-verify`（除非用户明确要求）。

#### 默认提交者

除非用户另行指定，每次 commit 使用下列身份（通过环境变量注入，**不要**改 `git config`）：

| 字段 | 值 |
|------|-----|
| Name | `Light-milk-tea` |
| Email | `2362519919@qq.com` |

```bash
GIT_AUTHOR_NAME='Light-milk-tea' \
GIT_AUTHOR_EMAIL='2362519919@qq.com' \
GIT_COMMITTER_NAME='Light-milk-tea' \
GIT_COMMITTER_EMAIL='2362519919@qq.com' \
git commit -m "$(cat <<'EOF'
prompt(auth): 支持 OAuth2 登录

WHAT: 重构认证中间件以支持 OAuth2 登录
WHY: 符合新的安全策略，允许第三方登录，对应需求 #2345
HOW: 引入 OAuth2 授权码流程替换 BasicAuth；向下兼容旧 Token；通过单元测试验证
EOF
)"
```

常规功能示例：

```bash
GIT_AUTHOR_NAME='Light-milk-tea' \
GIT_AUTHOR_EMAIL='2362519919@qq.com' \
GIT_COMMITTER_NAME='Light-milk-tea' \
GIT_COMMITTER_EMAIL='2362519919@qq.com' \
git commit -m "$(cat <<'EOF'
feat(auth): support OAuth2 login

WHAT: Add OAuth2 authorization-code flow to auth middleware
WHY: Meet security policy and enable third-party login (#2345)
HOW: Replace BasicAuth; keep legacy tokens compatible; cover with unit tests
EOF
)"
```

提交后跑 `git status` 确认。不要 `push`，除非用户明确要求。

### 6. 推送（仅用户明确要求时）

默认：

```bash
git push -u origin HEAD
```

#### 故障：Clash / mihomo Fake-IP 导致 SSH push 失败

**现象**（任一条）：

- `Connection closed by 127.0.0.1 port 7890`
- `Connection closed by 198.18.x.x port 22`
- `Connection timed out during banner exchange` / `Connection to 198.18.x.x port 22 timed out`
- `fatal: Could not read from remote repository`

**原因**：本机代理（Clash / mihomo 等）开启 Fake-IP 后，`github.com` 被解析到 `198.18.0.0/16` 虚假地址，SSH 22 端口连不上；HTTPS 往往仍可用（可 `curl` / `git ls-remote https://...`），但无交互环境下 HTTPS push 常因无法弹出用户名密码而失败。

**排查**（确认是 Fake-IP，而非密钥问题）：

```bash
dig +short github.com
# 若结果落在 198.18.0.0/16 → Fake-IP
ssh -T -o ConnectTimeout=12 git@github.com
# 超时或 Connection closed by 198.18.* → 走下方绕过
```

**绕过（优先）**：经 GitHub SSH 的 443 端口（`ssh.github.com`），不改 `git config`：

```bash
# 先验证认证
ssh -T -p 443 -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new git@ssh.github.com
# 成功时仍可能 exit 1，但应看到：Hi <user>! You've successfully authenticated...

# 再 push（把 <remote-ref> 换成实际目标，如 main / HEAD:main）
GIT_SSH_COMMAND='ssh -p 443 -o StrictHostKeyChecking=accept-new -o HostName=ssh.github.com' \
  git push origin HEAD:<remote-ref>
```

推送后用 `git status -sb` 确认已与远程同步。

**不要**：为绕过问题去改全局 `~/.ssh/config` 或 `git config`（除非用户明确要求持久化）；不要 force push。

## 聚合 Prompt 模板

用户要求「生成上下文 / 聚合 prompt 提交」时：从 git log 提取 `prompt:` 提交的 WHAT/WHY/HOW，**只输出**下列模板内容（无解释、无代码围栏、无多余空行）：

```
<Context>
1. [WHAT] ...
   [WHY] ...
   [HOW] ...
2. [WHAT] ...
   [WHY] ...
   [HOW] ...
</Context>
```

每个编号项对应一次独立的 `prompt:` 提交。

提取可用：

```bash
git log --grep='^prompt' --format='%H%n%s%n%b%n---'
```

## 示例

两次 `prompt:` 提交后的聚合输出：

```
<Context>
1. [WHAT] 重构认证中间件以支持 OAuth2 登录
   [WHY] 符合新的安全策略，允许第三方登录，对应需求 #2345
   [HOW] 引入 OAuth2 授权码流程替换 BasicAuth；向下兼容旧 Token；通过单元测试验证；需更新客户端配置
2. [WHAT] 移除废弃 API 端点
   [WHY] 为 v2.0 版本做清理，减少维护成本
   [HOW] 下线 v1 Legacy 端点并更新 API 文档；版本标识提升至 v2；通知客户端迁移
</Context>
```

## 安全约束

- 不更新 git config
- 不 force push、不硬重置（除非用户明确要求）
- 不提交疑似密钥（`.env`、`credentials.json` 等）；若用户坚持，先警告
- 用户未要求时不 commit、不 push

## 来源

基于 [kingkongshot/prompts](https://github.com/kingkongshot/prompts) 的 Commit-as-Prompt 工作流改编。
