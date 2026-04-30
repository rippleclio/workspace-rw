# AGENTS.md（仓库根目录）

## 第一性原理（必须遵守）
- 商业目的优先：先做“能卖、稳定、可运营”的正确版本
- 质量优先：正确性 > 安全性 > 可维护性 > 性能 > 开发效率
- 自动化提效：能自动化就自动化，但**绝不为了快牺牲正确性**

## 工作方式（默认行为）
- 优先小步提交、小改动、可回滚
- 任何功能改动都要同步：测试 + 文档（默认 Markdown）
- 不要手改生成物，除非更新生成器
- 每次完成任务后，必须检查 IDE 是否还有红线/诊断问题；如发现问题，需同步修复后再交付
- 红线检查不能只看编辑器静态残留提示；必须至少补做与改动直接相关的真实校验（如 `go test`、`npm run build`、`npm run lint`、迁移/构建命令）后再判断是否已修复
- 如果命令行校验通过但 IDE 仍保留旧红线，必须继续做一次文件重读/重新触发诊断，并在交付说明中明确标注“属于 IDE 诊断缓存，还是实际代码错误”

## 仓库结构（示例）
- /core-platform              ：Go/Gin 后端核心平台
- /wabifair-commerce          ：Go/Gin 后端商品平台
- /wabifair-storefront-web    ：wabi商城前端 Web（React 18 + TS）
- /wabifair-admin-console     ：后台管理（React 18 + TS）
- /rippleclio-content         ：RippleClio 内容平台后端（Go/Gin 微服务）
- /rippleclio-admin-console   ：RippleClio 管理后台（React 19 + TS）
- /rippleclio-web             ：RippleClio 用户端 Web（React 19 + TS）
- /documents                  ：产品/工程文档（Markdown 为主）

## 项目文档目录（必须知道）
- `documents/rippleclio`：RippleClio 相关产品、架构、运行说明、专项方案文档
- `documents/wabifair`：Wabifair 相关产品、架构、业务与交付文档
- `documents/shared`：跨项目共享主题文档，如分账、协作机制、通用制度与共用方案

## 全局硬性约束（MUST）
1) **数据库迁移优先检索（Migration-first）**
   - 写任何涉及表/字段/索引/枚举/约束的代码前，必须先看：
     - core-platform\db\migrations
     - wabifair-commerce\db\migrations
    - rippleclio-content\db\migrations
   - 如果缺字段/缺表：**先补迁移，再写代码**，禁止“代码里先假设存在”

2) **API 改动必须同步契约**
   - 改动请求/响应结构时，要同步：
     - wabi商城前端类型
     - 后台管理类型
    - RippleClio OpenAPI 契约（`rippleclio-content/contracts/openapi/*.yaml`）
    - RippleClio 管理端生成类型（`rippleclio-admin-console/src/api/generated/*`）
    - RippleClio 用户端类型（如消费相关接口）

3) **网关优先（Gateway-first）**
  - `rippleclio-admin-console`、`rippleclio-web`、`wabifair-*` 前端只允许通过 API Gateway 访问后端
  - 禁止在前端环境变量、代理、README、部署脚本中写死内部服务地址、容器名、数据库代理地址

4) **脚本同步更新（Script-sync）**
   - 修改 `.bat` 脚本时，必须同步更新对应的 `.sh` 脚本，反之亦然
   - 涉及的脚本对包括但不限：
     - `*/build-services.bat` ↔ `*/build-services.sh`
     - `*/run-migrations.bat` ↔ `*/run-migrations.sh`

6) **端口变更必须同步文档（Port-change-sync）**
   - 任何涉及服务端口的变更（修改 `.env`、`.env.example`、`docker-compose.dev.yml` 默认值、代码中硬编码的默认端口），必须**同一次提交**同步更新：
     - `documents/shared/service-port-database-map.md`（唯一端口数据源）
     - 对应仓库的 `.env.example`
     - 所有 `docker-compose.dev.yml` 中引用该端口的默认值（`${VAR:-默认值}` 形式）
   - **严禁** `.env` 与 `.env.example` 端口不一致；如需临时覆盖，必须在 `.env` 中加注释说明原因
   - **严禁**在未阅读 `service-port-database-map.md` 的情况下推断端口号（"猜端口"属于违规操作）
   - 端口变更前必须先确认：是否有其他服务/配置文件以硬编码或默认值形式引用了旧端口

5) **依赖版本统一（Dependency-version-sync）**
   - 添加新依赖前，必须先检索同类仓库是否已使用该依赖：
     - Go 后端：检查 `core-platform`、`wabifair-commerce`、`rippleclio-content` 的 `go.mod`
     - Node.js 前端：检查 `wabifair-storefront-web`、`wabifair-admin-console`、`rippleclio-admin-console`、`rippleclio-web` 的 `package.json`
   - 如果其他仓库已使用该依赖，**必须使用相同版本**
   - 如需升级版本，**必须同步升级所有使用该依赖的仓库**

7) **wabifair-commerce 双 service 同源代码 Mirror（Repo-mirror）**
   - `wabifair-commerce/services/admin-service` 和 `wabifair-commerce/services/catalog-service` 各自持有一份 `internal/repository/merchant_repository.go` 和 `internal/model/product.go`。**这两份是同源代码,必须保持同步**
   - 改动 `GetMerchantProductDetail` / `UpdateMerchantProduct` / `CreateMerchantProduct` SQL 时,**必须同时修改两个 service 的 repo**,否则会出现"merchant 自营路径 ✓ / admin 代管路径 ✗"或反过来的不对称 bug
   - 改动 `model.ProductDetail` / `model.ProductRow` / `model.ProductSku` 字段时,**必须同时修改两个 service 的 model**
   - 历史教训:
     - F-26: Phase 3 后端修复(移除主 tab zh-CN 双写)只改了 catalog-service,admin 代管路径仍然擦 zh-CN 数据,被 E2E 暴露
     - F-27: Phase 1 i18n 迁移加 brand_story 翻译只改了 catalog-service repo SQL,admin 代管路径主 tab 品牌故事永远空白
   - 长期目标:把这部分共享逻辑提取到 `pkg/merchantrepo` 或让 admin-service 通过 RPC/HTTP 调 catalog-service,消除重复;短期任何改动按 mirror 原则同步

8) **`decimal.Decimal` 列 nullable 防御（Decimal-NULL-defense）**
   - `model.ProductSku.Price` 等 `decimal.Decimal`(非指针)字段对应 DB 列允许 NULL 时,SELECT 必须用 `COALESCE(col, 0) AS col`
   - 不加 COALESCE 的后果:pgx scan plan fallback 到 byte array codec,错误 `can't scan into dest[N]: could not convert value '<nil>' to byte array of type '<nil>'`,且错误位置非常误导(N 是单个 query 内部索引)
   - 适用范围:任何 `decimal.Decimal`(非 `*decimal.Decimal`)字段对应 nullable 列;`*decimal.Decimal` 类型不需要 COALESCE 因为 Go 端能接 nil
   - 历史教训:F-25 在这个 trap 上耗了 7 次盲修才找到根因

## 常用根目录脚本用途
- `scripts/reset-and-build.bat`
  - 用于一键重置并重建本地后端环境
  - 会检查 Docker、停止并删除现有容器、删除卷
  - 会依次构建 `core-platform`、`wabifair-commerce`、`rippleclio-content`
  - 会依次执行对应迁移，并重启相关应用服务
  - 适用于后端 Go 代码、容器构建、数据库迁移变更后的重新部署验证

- `scripts/start-frontends.bat`
  - 用于一键启动所有前端开发服务器
  - 会启动：
    - `wabifair-storefront-web`（3000）
    - `wabifair-admin-console`（3001）
    - `rippleclio-web`（5173）
    - `rippleclio-admin-console`（5174）
  - 适用于本地联调、浏览器验证、前端改动后的 dev server 启动

- `scripts/stop-frontends.bat`
  - 用于一键停止所有前端开发服务器
  - 会清理 3000、3001、5173、5174 端口对应进程
  - 也会关闭由 `scripts/start-frontends.bat` 拉起的命令行窗口
  - 适用于重启前端环境、端口冲突处理、联调结束后的清理

## Chrome DevTools MCP 调用流程
- **适用场景**
  - 需要对 `rippleclio-web`、`rippleclio-admin-console`、`wabifair-*` 做真实浏览器联调
  - 需要验证 OAuth 跳转、页面交互、网络请求、控制台报错

- **前置条件**
  - Chrome 必须以标准 CDP 模式启动，且 `http://127.0.0.1:9333/json/version` 返回 `200`
  - 用户级 MCP 配置 `C:\Users\Administrator\.codeium\windsurf\mcp_config.json` 中，`chrome-devtools` 需连接 `chrome-devtools-mcp@0.20.0`
  - `chrome-devtools-mcp` 的 `--browserUrl` 需指向 `http://127.0.0.1:9333`
  - 变更 MCP 配置后，必须重载或重启 Windsurf，确保工具重新连接

- **推荐调用顺序**
  - 先用 `mcp0_list_pages` 确认 Chrome DevTools MCP 已成功接管浏览器
  - 用 `mcp0_take_snapshot` 获取当前页面结构与可交互元素 `uid`
  - 用 `mcp0_click`、`mcp0_fill`、`mcp0_press_key` 执行真实页面交互
  - 用 `mcp0_list_network_requests` 检查关键跳转、接口请求与状态码
  - 用 `mcp0_list_console_messages` 检查前端运行时错误
  - 必要时用 `mcp0_take_snapshot` 或 `mcp0_evaluate_script` 二次确认页面状态与 URL

- **本次 Google OAuth 验证结论**
  - 通过 Chrome DevTools MCP 成功进入 `http://localhost:5173/login`
  - 成功点击“使用 Google 登录”
  - 已真实跳转到 Google 授权页
  - Google 返回 `redirect_uri_mismatch`
  - 该结果说明当前发起的 OAuth 请求已经使用 `http://localhost:5173/auth/google/callback`
  - 若要完成完整登录链路，需在 Google Cloud Console 的 OAuth Redirect URI 白名单中补充 `http://localhost:5173/auth/google/callback`

## 默认验收输出（你每次实现功能都要给出）
- 变更摘要（做了什么、为什么）
- 影响范围（哪些模块/接口/数据受影响）
- 修改文件清单（路径）
- 本地验证命令（test/lint/build/migrate）
- 风险点与回滚方案（若涉及 DB / 合同 / 权限）

## 调试纪律（Debugging discipline）

诊断 bug 时必须遵循 systematic-debugging 原则,**没有 root cause 就不要 propose fix**。本仓库已发生过多次"盲修反复失败"的事故,以下是必须遵守的纪律:

1) **3 次修复失败必停**
   - 同一个 bug 尝试 3 次修复仍然失败,**立刻停止**新的修复尝试
   - 回到 Phase 1 重新 root cause 分析,或者 explicitly 调用 `superpowers:systematic-debugging` skill
   - 历史教训:F-25 调试时,第 4-7 次尝试(各种 pgx 类型/cast/ExecMode)全部基于错误的 root cause 假设。如果在第 3 次失败时停下,能省 1 小时

2) **错误信息的索引必须与具体 query 绑定**
   - pgx 错误 `can't scan into dest[N]` 中的 N 是**单个 query 内部的 destination 索引**,不跨 query 累加
   - repo 函数跑 5 段 SQL 时,每段 SQL 都有自己的 dest[0..k]。错误 dest[3] 可能是任意一段的第 4 个目标
   - **看到 dest[N] 错误,先问"这是哪段 query 的 dest[N]"**,不要默认是函数顶部第一段 query
   - 历史教训:F-25 误以为 dest[3] = 主 SELECT 的 CollaborationID *int64 NULL,实际是 SKU SELECT 的 sku.Price decimal.Decimal NULL。7 次盲修都针对错误位置

3) **Bisection 优于理论化**
   - 当 bug 涉及"为什么 X 失败 Y 不失败"时,先做 cheap experiment 对比两组数据,**不要先猜原因**
   - F-25 通过创建 fresh product 10002(对照组)+ 删 product_skus 行(精确隔离)在 3 分钟内定位问题。之前 1 小时的纯理论调试一无所获
   - Cheap experiments:复制有问题的实体到新 ID 看是否复现、二分删除字段/JOIN 逐一确认、`git stash` 比对 main 和当前分支

4) **`go build` / `go test` 通过 ≠ 行为正确**
   - 编译通过和单元测试通过只能保证语法/接口正确,不能保证数据库交互、跨服务、并发场景的行为正确
   - 任何涉及 DB / 跨 service / 跨进程的改动,**必须实际跑端到端验证**(reset-and-build + 真实浏览器或 curl 操作),不能只跑 `go test ./...`
   - 历史教训:F-25/F-26/F-27 都通过 build + 单元测试,但被 E2E 暴露真问题

## 使用中文进行回复


For UI/UX audits, redesigns, and polish tasks, use the frontend-design skill in `.claude/skills/frontend-design/`.

## gstack

Use the /browse skill from gstack for general web browsing.

Available skills:
/office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review, /design-consultation, /design-shotgun, /design-html, /review, /ship, /land-and-deploy, /canary, /benchmark, /browse, /connect-chrome, /qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy, /retro, /investigate, /document-release, /codex, /cso, /autoplan, /careful, /freeze, /guard, /unfreeze, /gstack-upgrade, /learn

If gstack skills aren't working, run `cd .claude/skills/gstack && ./setup` to rebuild.

## Design System

Wabifair 设计系统文档在 `DESIGN.md`。做任何 UI 决策前必须读取该文件。

关键规则：
- 主题：`data-theme="apple"` 是唯一品牌主题，其余三个（ocean/forest/sunset）为平台级
- 主交互色：哑光金 `#C4A24E`（accent-400），不用蓝色
- 页面底色：暖石 `#FAF9F7`（secondary-50），不用纯白
- Logo 字体：Noto Serif SC 500
- 所有新 UI 组件遵循 8px 间距体系 + rounded-apple/apple-sm/apple-xs 圆角系统
- i18n UI 规格（语言切换器、结算税费面板、地区不可用状态）见 DESIGN.md 和 `documents/wabifair/multi-country-expansion-plan.md` § 5.7.6–5.7.11
