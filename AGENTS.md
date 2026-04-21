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

## 常用根目录脚本用途
- `reset-and-build.bat`
  - 用于一键重置并重建本地后端环境
  - 会检查 Docker、停止并删除现有容器、删除卷
  - 会依次构建 `core-platform`、`wabifair-commerce`、`rippleclio-content`
  - 会依次执行对应迁移，并重启相关应用服务
  - 适用于后端 Go 代码、容器构建、数据库迁移变更后的重新部署验证

- `start-frontends.bat`
  - 用于一键启动所有前端开发服务器
  - 会启动：
    - `wabifair-storefront-web`（3000）
    - `wabifair-admin-console`（3001）
    - `rippleclio-web`（5173）
    - `rippleclio-admin-console`（5174）
  - 适用于本地联调、浏览器验证、前端改动后的 dev server 启动

- `stop-frontends.bat`
  - 用于一键停止所有前端开发服务器
  - 会清理 3000、3001、5173、5174 端口对应进程
  - 也会关闭由 `start-frontends.bat` 拉起的命令行窗口
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

## 使用中文进行回复


For UI/UX audits, redesigns, and polish tasks, use the frontend-design skill in `.claude/skills/frontend-design/`.