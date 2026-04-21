## gstack

Use the /browse skill from gstack for all web browsing. Never use mcp__claude-in-chrome__* tools.

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
