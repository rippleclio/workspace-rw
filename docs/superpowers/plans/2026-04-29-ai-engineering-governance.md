# AI Engineering Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single authoritative AI engineering governance source and reduce root Agent entry files to thin tool adapters.

**Architecture:** The long-lived governance content lives in `documents/shared/ai-engineering-governance.md`. Root entry files (`CLAUDE.md`, `AGENTS.md`) only instruct Agents to read the authority source and keep tool-specific rules that do not belong in the shared governance document.

**Tech Stack:** Markdown, Git, PowerShell.

---

## File Structure

- Create: `documents/shared/ai-engineering-governance.md`
  - Responsibility: single authoritative source for AI Agent governance rules, cross-repo constraints, required context matrix, verification discipline, delivery format, and trap registry.
- Modify: `CLAUDE.md`
  - Responsibility: Claude-specific entry adapter that points to the authority source and preserves Claude/gstack/frontend-design behavior.
- Modify: `AGENTS.md`
  - Responsibility: Codex/Agent entry adapter that points to the authority source and preserves local Agent execution rules that must remain visible on first read.
- Create only if missing: `docs/superpowers/plans/`
  - Responsibility: stores Superpowers implementation plans.

## Execution Notes

- Do not create a symlink between `CLAUDE.md` and `AGENTS.md`.
- Execute this plan in an isolated git worktree, not on `main`.
- Use small commits exactly as listed below.
- Do not modify business code.
- This plan changes Markdown governance files only, so validation is document-level plus git whitespace validation.

### Task 1: Add Authority Governance Source

**Files:**
- Create: `documents/shared/ai-engineering-governance.md`

- [ ] **Step 1: Create the authority source file**

Use `apply_patch` to add `documents/shared/ai-engineering-governance.md` with this content:

```markdown
# AI 工程化治理权威源

本文件是本工作区 AI 编程 Agent 的唯一长期治理规则源。`CLAUDE.md`、`AGENTS.md` 和未来其他 Agent 入口文件只是适配层，不承载长期规则正文。

任何 Agent 在修改代码、配置、脚本、契约或文档前，必须先读取本文件。若无法读取本文件，必须停止执行并说明原因。

## 适用范围

本文件第一阶段服务 AI 编程 Agent。目标是让 Agent 在多仓库工作区中稳定完成上下文读取、同步改动、真实验证和可审计交付。

本文件不替代产品 PRD、设计系统文档、测试计划或部署文档。遇到具体任务时，Agent 仍必须读取对应业务文档。

## 第一性原则

1. 商业目的优先：先做能卖、稳定、可运营的正确版本。
2. 质量优先：正确性 > 安全性 > 可维护性 > 性能 > 开发效率。
3. 自动化提效：能自动化就自动化，但绝不为了快牺牲正确性。
4. 小步可回滚：优先小改动、小提交，避免一次性大范围重写。

## 工作区结构

| 路径 | 职责 |
| --- | --- |
| `core-platform` | Go/Gin 后端核心平台 |
| `wabifair-commerce` | Go/Gin 后端商品平台 |
| `wabifair-storefront-web` | Wabifair 商城前端 Web，React 18 + TypeScript |
| `wabifair-admin-console` | Wabifair 后台管理，React 18 + TypeScript |
| `rippleclio-content` | RippleClio 内容平台后端，Go/Gin 微服务 |
| `rippleclio-admin-console` | RippleClio 管理后台，React 19 + TypeScript |
| `rippleclio-web` | RippleClio 用户端 Web，React 19 + TypeScript |
| `documents` | 产品、工程、测试、部署文档 |

## 文档索引

| 路径 | 使用场景 |
| --- | --- |
| `documents/rippleclio` | RippleClio 产品、架构、运行说明、专项方案 |
| `documents/wabifair` | Wabifair 产品、架构、业务与交付文档 |
| `documents/shared` | 跨项目共享主题，包括分账、协作机制、端口、通用制度 |
| `DESIGN.md` | Wabifair 设计系统和 UI 决策入口 |
| `documents/shared/service-port-database-map.md` | 服务端口和数据库映射的唯一数据源 |

## 跨仓库硬约束

### 1. Migration-first

写任何涉及表、字段、索引、枚举或约束的代码前，必须先读取：

```text
core-platform/db/migrations
wabifair-commerce/db/migrations
rippleclio-content/db/migrations
```

如果缺字段或缺表，必须先补迁移，再写业务代码。禁止在代码中假设数据库对象已经存在。

### 2. API Contract Sync

改动请求或响应结构时，必须同步所有调用方和契约：

```text
wabifair-storefront-web
wabifair-admin-console
rippleclio-content/contracts/openapi/*.yaml
rippleclio-admin-console/src/api/generated/*
rippleclio-web
```

RippleClio OpenAPI 改动后，必须同步生成管理端类型。不得只改后端 handler 或前端调用方。

### 3. Gateway-first

`rippleclio-admin-console`、`rippleclio-web`、`wabifair-storefront-web`、`wabifair-admin-console` 只能通过 API Gateway 访问后端。

禁止在前端环境变量、代理、README、部署脚本中写死内部服务地址、容器名或数据库代理地址。

### 4. Script-sync

修改 `.bat` 脚本时，必须同步更新对应 `.sh` 脚本；反向也一样。

必须同步的脚本对包括：

```text
*/build-services.bat <-> */build-services.sh
*/run-migrations.bat <-> */run-migrations.sh
```

### 5. Port-change-sync

任何服务端口变更，必须同一次改动同步：

```text
documents/shared/service-port-database-map.md
对应仓库的 .env.example
所有 docker-compose.dev.yml 中引用该端口的默认值
```

禁止在未阅读 `documents/shared/service-port-database-map.md` 的情况下推断端口号。端口变更前必须检索旧端口是否被硬编码或作为默认值引用。

### 6. Dependency-version-sync

添加新依赖前，必须先检索同类仓库是否已使用该依赖。

Go 后端检查：

```text
core-platform/go.mod
wabifair-commerce/go.mod
rippleclio-content/go.mod
```

Node.js 前端检查：

```text
wabifair-storefront-web/package.json
wabifair-admin-console/package.json
rippleclio-admin-console/package.json
rippleclio-web/package.json
```

如果其他仓库已使用该依赖，必须使用相同版本。如需升级版本，必须同步升级所有使用该依赖的仓库。

### 7. Wabifair Commerce Repo Mirror

`wabifair-commerce/services/admin-service` 和 `wabifair-commerce/services/catalog-service` 各自持有同源代码：

```text
internal/repository/merchant_repository.go
internal/model/product.go
```

改动 `GetMerchantProductDetail`、`UpdateMerchantProduct`、`CreateMerchantProduct` SQL 时，必须同时修改两个 service 的 repository。

改动 `model.ProductDetail`、`model.ProductRow`、`model.ProductSku` 字段时，必须同时修改两个 service 的 model。

长期目标是抽取共享逻辑到 `pkg/merchantrepo`，或让 admin-service 通过 RPC/HTTP 调用 catalog-service。短期按 mirror 原则同步。

### 8. Decimal NULL Defense

`decimal.Decimal` 非指针字段对应数据库 nullable 列时，SELECT 必须使用 `COALESCE(col, 0) AS col`。

适用范围是任何 `decimal.Decimal` 非指针字段对应 nullable 列。`*decimal.Decimal` 可以接收 nil，不需要这个防御。

## Agent 默认工作流

1. Intake：识别任务类型和影响面，判断是否涉及 DB、API、端口、脚本、依赖、UI、E2E。
2. Context Scan：按影响面读取必读文件，不得跳过迁移、契约、设计系统或端口源。
3. Plan / Small Step：复杂任务先写方案或计划；执行时保持小步可回滚。
4. Implementation：代码、测试、文档同步改。禁止只改实现不改契约、类型或文档。
5. Verification：运行与改动直接相关的真实校验。
6. Delivery：交付说明必须包含变更摘要、影响范围、修改文件清单、本地验证命令、风险点与回滚方案。

## 任务类型上下文矩阵

| 任务类型 | 必读上下文 | 关键验证 |
| --- | --- | --- |
| DB 表、字段、索引、枚举、约束 | 三个后端 `db/migrations` | 迁移命令、相关服务测试、必要时联调 |
| API 请求或响应结构 | OpenAPI、生成类型、前后端调用方 | 类型生成、前后端构建、接口测试 |
| 前端 UI/UX | `DESIGN.md`、对应产品文档、相关页面代码 | build、lint、test、必要时浏览器验证 |
| 端口变更 | `documents/shared/service-port-database-map.md`、`.env.example`、`docker-compose.dev.yml` | 端口引用检索、启动或构建验证 |
| 依赖变更 | 同类仓库 `go.mod` 或 `package.json` | 安装、构建、测试 |
| Bug 修复 | 复现路径、日志、相关测试、Trap Registry | root cause 证据、回归测试、失败三次停止盲修 |

## 验证纪律

功能改动必须同步测试和文档。完成任务后，必须做与改动直接相关的真实校验。

前端改动至少运行 build、lint、test 中与改动相关的一项。后端改动至少运行 go test 或 build。涉及数据库、跨 service 或跨进程行为时，必须补充迁移验证、curl、浏览器联调或端到端验证。

命令行校验通过但 IDE 仍有旧诊断时，必须重新读取文件或重新触发诊断，并在交付说明中明确这是诊断缓存还是实际代码错误。

## 调试纪律

没有 root cause 就不要提出修复。诊断 bug 时必须先收集证据，再做最小实验。

同一个 bug 修复失败三次后，必须停止继续盲修，回到 root cause 分析。

看到 pgx `can't scan into dest[N]` 时，必须先确认是哪一段 query 的第 N 个 destination。N 是单个 query 内部索引，不跨 query 累加。

Bisection 优于理论化。能用对照数据、二分删除字段、隔离 JOIN 或对比分支快速定位时，优先做实验。

`go build` 或 `go test` 通过不等于行为正确。数据库交互、跨服务、并发、浏览器链路必须用真实路径验证。

## Trap Registry

### F-25 Decimal NULL Scan

触发条件：`decimal.Decimal` 非指针字段扫描 nullable 数值列。

症状：pgx 报错 `can't scan into dest[N]`，并可能提示无法把 nil 转为 byte array。

正确做法：SELECT 中对 nullable 数值列使用 `COALESCE(col, 0) AS col`，或把 Go 字段改为 `*decimal.Decimal` 并完整处理 nil。

关联范围：`wabifair-commerce` 商品 SKU、价格、金额类字段。

### F-26 Admin/Catalog Mirror Drift

触发条件：只修改 `catalog-service` 或只修改 `admin-service` 的商家商品 repository。

症状：商家自营路径正常，后台代管路径异常，或反向异常。

正确做法：修改 merchant product 相关 SQL 时，同步修改两个 service 的 repository 和 model。

关联范围：`wabifair-commerce/services/admin-service`、`wabifair-commerce/services/catalog-service`。

### F-27 Brand Story Translation Drift

触发条件：商品 i18n 字段只在一个 service 的 SQL 或 model 中更新。

症状：主 tab 或品牌故事在某一条路径下为空，另一条路径正常。

正确做法：按 Repo Mirror 规则同步 admin-service 和 catalog-service。

关联范围：商品详情、商品翻译、品牌故事字段。

## 入口文件维护规则

`CLAUDE.md` 和 `AGENTS.md` 必须保持薄入口。它们可以包含：

1. 读取本文件的硬性入口指令。
2. 当前 Agent 工具特有规则。
3. 必须第一屏可见的少量红线。

它们不应重复维护长期规则正文。长期规则只在本文件维护。

## 交付输出

每次功能实现交付必须包含：

1. 变更摘要：做了什么、为什么。
2. 影响范围：哪些模块、接口、数据受影响。
3. 修改文件清单：列出路径。
4. 本地验证命令：test、lint、build、migrate 或联调命令。
5. 风险点与回滚方案：涉及 DB、合同、权限或部署时必须写清楚。

## 浏览器与外部工具

浏览器验证、gstack、Chrome DevTools、Playwright、MCP 等工具的具体调用方式由入口适配文件维护。无论使用哪种工具，验证结论必须基于真实页面、真实接口或真实命令输出。
```

- [ ] **Step 2: Verify the authority file has no placeholder markers**

Run:

```powershell
$markers = @('T' + 'BD', 'TO' + 'DO', '待' + '定', '占' + '位', 'implement' + ' later', 'fill in' + ' details')
Select-String -Path 'documents\shared\ai-engineering-governance.md' -Pattern ([string]::Join('|', $markers))
```

Expected: no output and exit code 0.

- [ ] **Step 3: Validate Markdown whitespace**

Run:

```powershell
git diff --check -- documents/shared/ai-engineering-governance.md
```

Expected: no output and exit code 0.

- [ ] **Step 4: Commit Task 1**

Run:

```powershell
git add -- documents/shared/ai-engineering-governance.md
git commit -m "docs: add AI engineering governance authority"
```

Expected: commit succeeds with one new file.

### Task 2: Convert CLAUDE.md To Thin Adapter

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Replace `CLAUDE.md` with Claude adapter content**

Use `apply_patch` to replace the full file with:

```markdown
# CLAUDE.md

本文件是 Claude Code 入口适配层，不是长期治理规则源。

## 必须先读

在处理任何代码、配置、脚本、契约或文档改动前，必须先读取：

```text
documents/shared/ai-engineering-governance.md
```

如果无法读取该文件，必须停止执行并说明原因。长期规则只在该权威源维护，不在本文件重复维护。

## 第一屏红线

- 使用中文回复。
- 不要跳过与改动直接相关的真实校验。
- 不要手改生成物，除非同步更新生成器。
- 不要在前端写死内部服务地址、容器名或数据库代理地址。
- UI/UX 决策前必须读取 `DESIGN.md`。

## Claude 专属规则

For UI/UX audits, redesigns, and polish tasks, use the frontend-design skill in `.claude/skills/frontend-design/`.

## gstack

Use the /browse skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available skills:

```text
/office-hours
/plan-ceo-review
/plan-eng-review
/plan-design-review
/design-consultation
/design-shotgun
/design-html
/review
/ship
/land-and-deploy
/canary
/benchmark
/browse
/connect-chrome
/qa
/qa-only
/design-review
/setup-browser-cookies
/setup-deploy
/retro
/investigate
/document-release
/codex
/cso
/autoplan
/careful
/freeze
/guard
/unfreeze
/gstack-upgrade
/learn
```

If gstack skills are not working, run:

```powershell
cd .claude/skills/gstack
./setup
```

## 设计系统入口

Wabifair 设计系统文档在 `DESIGN.md`。做任何 UI 决策前必须读取该文件。
```

- [ ] **Step 2: Verify `CLAUDE.md` points to the authority source**

Run:

```powershell
Select-String -Path 'CLAUDE.md' -Pattern 'documents/shared/ai-engineering-governance.md'
```

Expected: one or more matches containing the authority path.

- [ ] **Step 3: Verify removed long duplicated sections**

Run:

```powershell
Select-String -Path 'CLAUDE.md' -Pattern 'Migration-first|Dependency-version-sync|Trap Registry|F-25|F-26|F-27'
```

Expected: no output and exit code 0.

- [ ] **Step 4: Validate Markdown whitespace**

Run:

```powershell
git diff --check -- CLAUDE.md
```

Expected: no output and exit code 0.

- [ ] **Step 5: Commit Task 2**

Run:

```powershell
git add -- CLAUDE.md
git commit -m "docs: make CLAUDE entry use governance authority"
```

Expected: commit succeeds with one modified file.

### Task 3: Convert AGENTS.md To Thin Adapter

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Replace `AGENTS.md` with Agent adapter content**

Use `apply_patch` to replace the full file with:

```markdown
# AGENTS.md

本文件是 Codex/Agent 入口适配层，不是长期治理规则源。

## 必须先读

在处理任何代码、配置、脚本、契约或文档改动前，必须先读取：

```text
documents/shared/ai-engineering-governance.md
```

如果无法读取该文件，必须停止执行并说明原因。长期规则只在该权威源维护，不在本文件重复维护。

## 第一屏红线

- 使用中文回复。
- 不要跳过与改动直接相关的真实校验。
- 不要手改生成物，除非同步更新生成器。
- 不要在前端写死内部服务地址、容器名或数据库代理地址。
- UI/UX 决策前必须读取 `DESIGN.md`。
- 涉及 DB、API、端口、脚本、依赖或 Bug 修复时，必须按权威源的任务类型上下文矩阵读取必读文件。

## Codex 执行约束

- 优先小步改动、小步提交、可回滚。
- 搜索文件优先使用 `rg` 或 `rg --files`。
- 写文件优先使用补丁方式，避免不必要的批量重写。
- 不要回滚用户或其他 Agent 的未授权改动。
- 完成交付时按权威源的交付输出格式说明变更、影响、文件、验证和风险。
```

- [ ] **Step 2: Verify `AGENTS.md` points to the authority source**

Run:

```powershell
Select-String -Path 'AGENTS.md' -Pattern 'documents/shared/ai-engineering-governance.md'
```

Expected: one or more matches containing the authority path.

- [ ] **Step 3: Verify removed long duplicated sections**

Run:

```powershell
Select-String -Path 'AGENTS.md' -Pattern 'Migration-first|Dependency-version-sync|Chrome DevTools MCP|F-25|F-26|F-27'
```

Expected: no output and exit code 0.

- [ ] **Step 4: Validate Markdown whitespace**

Run:

```powershell
git diff --check -- AGENTS.md
```

Expected: no output and exit code 0.

- [ ] **Step 5: Commit Task 3**

Run:

```powershell
git add -- AGENTS.md
git commit -m "docs: make AGENTS entry use governance authority"
```

Expected: commit succeeds with one modified file.

### Task 4: Final Governance Validation

**Files:**
- Verify: `documents/shared/ai-engineering-governance.md`
- Verify: `CLAUDE.md`
- Verify: `AGENTS.md`

- [ ] **Step 1: Verify authority file exists**

Run:

```powershell
Test-Path 'documents\shared\ai-engineering-governance.md'
```

Expected:

```text
True
```

- [ ] **Step 2: Verify both entry files point to the authority source**

Run:

```powershell
Select-String -Path 'CLAUDE.md','AGENTS.md' -Pattern 'documents/shared/ai-engineering-governance.md'
```

Expected: matches in both `CLAUDE.md` and `AGENTS.md`.

- [ ] **Step 3: Verify high-risk rules moved to authority source**

Run:

```powershell
Select-String -Path 'documents\shared\ai-engineering-governance.md' -Pattern 'Migration-first|API Contract Sync|Gateway-first|Port-change-sync|Dependency-version-sync|Trap Registry'
```

Expected: matches for all six phrases.

- [ ] **Step 4: Verify root adapters do not contain long duplicated governance sections**

Run:

```powershell
Select-String -Path 'CLAUDE.md','AGENTS.md' -Pattern 'core-platform\\db\\migrations|wabifair-commerce\\db\\migrations|rippleclio-content\\db\\migrations|decimal.Decimal'
```

Expected: no output and exit code 0.

- [ ] **Step 5: Validate all Markdown whitespace**

Run:

```powershell
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 6: Confirm working tree status**

Run:

```powershell
git status --short
```

Expected: no output after all commits.

- [ ] **Step 7: Report completion**

Report:

```text
变更摘要：新增 AI 工程化治理权威源，并将 CLAUDE.md / AGENTS.md 收敛为薄入口适配层。
影响范围：仅 Markdown 治理文档；不影响业务代码、数据库、API、前端构建或部署。
修改文件清单：documents/shared/ai-engineering-governance.md, CLAUDE.md, AGENTS.md。
本地验证命令：Select-String checks, Test-Path, git diff --check, git status --short。
风险点与回滚方案：风险是入口文件过薄导致部分 Agent 未深读权威源；回滚可 revert 三个文档提交。
```
