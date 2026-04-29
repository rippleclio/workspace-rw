# AI 工程化治理设计

日期：2026-04-29

## 背景

当前工作区是一个多项目仓库集合，包含 Go 后端、React 前端、部署脚本和产品/工程文档。根目录已有 `CLAUDE.md`、`AGENTS.md`、`DESIGN.md` 与 `.claude/` 配置，其中 `CLAUDE.md` 已经比 `AGENTS.md` 多出调试纪律和历史陷阱记录。

现状说明项目已经开始使用 AI Agent 规则文件进行协作，但核心风险是规则复制后漂移：同一条约束可能在不同入口文件中版本不同，Agent 读取不同入口后产生不一致行为。

## 目标

第一阶段只服务 AI 编程 Agent，不优先覆盖人类开发者手册，也不立即接入 CI 强制检查。

本设计要解决四个问题：

1. Agent 入口一致：不同 Agent 看到不同入口文件时，仍能读取同一个权威治理源。
2. 规则分层清晰：硬约束、上下文索引、工作流、历史陷阱不混在一起无限增长。
3. 任务流程稳定：Agent 在改动前知道要读什么，改动后知道要验证什么。
4. 历史教训可复用：事故经验以结构化陷阱库保存，避免变成散乱日志。

## 非目标

第一阶段不实现入口文件生成器，不把 `CLAUDE.md` 直接符号链接到 `AGENTS.md`，不把治理规则接入 CI 阻断流程，也不重写现有业务文档。

## 推荐方案

采用“权威源 + 轻适配层”模式。

`documents/shared/ai-engineering-governance.md` 作为唯一权威源，承载长期治理规则、跨仓库约束、任务工作流、验证纪律和历史陷阱库。

`CLAUDE.md`、`AGENTS.md` 作为薄入口文件，只保留三类内容：

1. 明确要求 Agent 先读取 `documents/shared/ai-engineering-governance.md`。
2. 当前工具特有规则，例如 Claude skills、gstack、Codex/AGENTS 兼容说明。
3. 必须让工具第一屏看到的少量红线，例如中文回复、不要跳过真实校验。

不建议把 `AGENTS.md` 符号链接到 `CLAUDE.md`。不同 Agent 对入口文件有不同语义，符号链接会掩盖工具差异。更稳的做法是让两者都成为工具适配层，共同指向同一个权威源。

## 文件结构

建议形成如下结构：

```text
documents/shared/ai-engineering-governance.md
CLAUDE.md
AGENTS.md
DESIGN.md
documents/shared/service-port-database-map.md
documents/rippleclio/
documents/wabifair/
```

`documents/shared/ai-engineering-governance.md` 是治理规则唯一写入点。`CLAUDE.md` 与 `AGENTS.md` 不承载长期规则正文，只承载入口指令和工具专属差异。

## 规则分层

权威源按以下层级组织：

1. 不可违背原则：商业目的优先、正确性优先、可运营、可回滚。这类规则少而稳定，不放具体工具命令。
2. 跨仓库硬约束：migration-first、API 契约同步、gateway-first、脚本双端同步、端口同步、依赖版本统一。这些是 Agent 最容易漏掉的规则，应放在权威源核心区。
3. 项目知识索引：仓库职责、文档目录、设计系统入口、端口地图、测试计划目录。这里不重复正文，只给路径和使用场景。
4. 工作流纪律：先读上下文、先查迁移、先定位 root cause、改动后跑相关真实校验、交付时说明风险和回滚。
5. 历史陷阱库：F-25、F-26、F-27 等事故单独维护。每条包含触发条件、错误症状、正确做法、关联文件。

历史陷阱不直接塞进硬约束区。只有重复发生、触发条件明确、且会造成高风险后果的陷阱，才升级为硬约束。

## Agent 工作流

AI Agent 默认流程固定为六个阶段：

1. Intake：识别任务类型和影响面。判断是否涉及 DB、API、端口、脚本、依赖、UI、E2E。
2. Context Scan：按影响面读取必读文件。例如 DB 先读 migrations，UI 先读 `DESIGN.md`，端口先读 `service-port-database-map.md`。
3. Plan / Small Step：只做小步、可回滚改动。复杂任务先写方案或计划，不直接大改。
4. Implementation：代码、测试、文档同步改。禁止只改实现不改契约、类型、文档。
5. Verification：运行与改动直接相关的真实校验。前端至少 build、lint、test 之一；后端至少 go test 或 build，涉及 DB/跨服务时补迁移或联调验证。
6. Delivery：交付说明固定包含变更摘要、影响范围、文件清单、验证命令、风险与回滚。

## 任务类型到必读上下文

权威源应维护一个任务矩阵：

| 任务类型 | 必读上下文 | 关键验证 |
| --- | --- | --- |
| DB 表、字段、索引、枚举、约束 | `core-platform/db/migrations`、`wabifair-commerce/db/migrations`、`rippleclio-content/db/migrations` | 迁移命令、相关服务测试、必要时联调 |
| API 请求或响应结构 | OpenAPI、生成类型、前后端调用方 | 类型生成、前后端构建、接口测试 |
| 前端 UI/UX | `DESIGN.md`、对应产品文档、相关页面代码 | build/lint/test、必要时浏览器验证 |
| 端口变更 | `documents/shared/service-port-database-map.md`、`.env.example`、`docker-compose.dev.yml` | 端口引用检索、启动或构建验证 |
| 依赖变更 | 同类仓库 `go.mod` 或 `package.json` | 安装、构建、测试 |
| Bug 修复 | 复现路径、日志、相关测试、历史陷阱库 | root cause 证据、回归测试、失败三次停止盲修 |

## 维护机制

第一阶段采用轻量治理：

1. 唯一写入点：新增或修改长期规则时，只改 `documents/shared/ai-engineering-governance.md`。
2. 入口文件最小化：`CLAUDE.md`、`AGENTS.md` 保持短文件，明确要求 Agent 先读权威源，并列出本工具专属能力或限制。
3. Trap Registry 定期整理：历史事故按结构化格式沉淀，避免入口文件无限变长。
4. 人工同步检查：每次改治理文档时，至少检查 `CLAUDE.md` 和 `AGENTS.md` 是否仍指向正确权威源。
5. 延后自动化：规则稳定后，再考虑脚本生成入口文件、CI 检查入口文件漂移、任务类型 checklist 自动化。

## 取舍

该方案牺牲了一点入口文件的完整读取体验，换取长期规则一致性和低维护成本。

不立刻做生成器，是因为当前项目更需要先稳定 Agent 的上下文读取和真实验证纪律。生成器和 CI 检查应在规则稳定后再补，否则会把治理问题提前复杂化。

## 验收标准

第一阶段落地完成后应满足：

1. `documents/shared/ai-engineering-governance.md` 存在，并包含规则分层、Agent 工作流、任务矩阵、陷阱库入口。
2. `CLAUDE.md` 和 `AGENTS.md` 明确指向权威源，并只保留工具入口适配内容。
3. 任何长期规则只在权威源维护，不在入口文件重复维护正文。
4. Agent 接到 DB、API、UI、端口、依赖、Bug 任务时，能从权威源找到对应必读上下文和验证要求。

## 风险与缓解

风险一：部分 Agent 不会自动读取被引用文档。缓解方式是在入口文件第一屏明确写出“必须先读取权威源”，并保留少量高风险红线。

风险二：权威源变得过长。缓解方式是严格分层，项目知识只放索引，历史事故进入 Trap Registry，不把所有细节塞进核心规则。

风险三：短期仍需人工维护入口文件。缓解方式是第一阶段只允许入口文件保留适配层，减少需要同步的正文。

## 后续实施建议

后续应先编写 `documents/shared/ai-engineering-governance.md`，再收敛 `CLAUDE.md` 和 `AGENTS.md` 为薄入口。实施完成后运行文档级检查，并人工核对入口文件是否仍包含重复长期规则。
