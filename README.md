# workspace-rw

该目录是本地多仓库工作区根目录，用来统一管理以下仓库：

- `core-platform`
- `documents`
- `rippleclio-admin-console`
- `rippleclio-content`
- `rippleclio-web`
- `wabifair-admin-console`
- `wabifair-commerce`
- `wabifair-storefront-web`

根目录自身也是一个 Git 仓库，主要保存工作区级脚本、说明文档和协作配置。

## 目录说明

- `scripts/setup.sh` / `scripts/setup.bat`：首次 clone 后执行，安装前端依赖并检查工作区仓库布局。
- `scripts/reset-and-build.sh` / `scripts/reset-and-build.bat`：一键重置并重建本地后端环境。
- `scripts/start-frontends.sh` / `scripts/start-frontends.bat`：启动 4 个前端开发服务器。
- `scripts/stop-frontends.sh` / `scripts/stop-frontends.bat`：停止所有前端开发服务器。
- `scripts/install-frontends.sh` / `scripts/install-frontends.bat`：安装 4 个前端仓库的 npm 依赖。
- `scripts/package-selected-files.sh` / `scripts/package-selected-files.bat`：打包关键 `.env` 文件到 `documents/selected-files.zip`。
- `scripts/commit_all.sh` / `scripts/commit_all.bat`：执行 `git add -A` 并按统一提交信息提交。
- `scripts/pull_all.sh` / `scripts/pull_all.bat`：按当前分支执行安全拉取。
- `scripts/push_all.sh` / `scripts/push_all.bat`：按当前分支执行推送。
- `scripts/status_all.sh` / `scripts/status_all.bat`：统一查看根仓库和全部子仓库的当前 Git 状态。

## 使用方式

在根目录执行：

```bash
bash scripts/setup.sh
bash scripts/reset-and-build.sh
bash scripts/start-frontends.sh
bash scripts/stop-frontends.sh
bash scripts/install-frontends.sh
bash scripts/package-selected-files.sh
bash scripts/commit_all.sh "chore: update multiple repos"
bash scripts/pull_all.sh
bash scripts/push_all.sh
bash scripts/status_all.sh
```

```bat
scripts\setup.bat
scripts\reset-and-build.bat
scripts\start-frontends.bat
scripts\stop-frontends.bat
scripts\install-frontends.bat
scripts\package-selected-files.bat
scripts\commit_all.bat "chore: update multiple repos"
scripts\pull_all.bat
scripts\push_all.bat
scripts\status_all.bat
```

可选地在命令后追加仓库名，只操作指定仓库：

```bash
bash scripts/pull_all.sh wabifair-commerce rippleclio-content
bash scripts/status_all.sh workspace-rw wabifair-admin-console
bash scripts/commit_all.sh "docs: sync readme" workspace-rw documents
```

```bat
scripts\pull_all.bat wabifair-commerce rippleclio-content
scripts\status_all.bat workspace-rw wabifair-admin-console
scripts\commit_all.bat "docs: sync readme" workspace-rw documents
```

首次 clone：

```bash
bash scripts/setup.sh
```

```bat
scripts\setup.bat
```

首次安装完成后再构建后端与启动前端。

首次 clone 的推荐顺序：

```bash
bash scripts/setup.sh
bash scripts/reset-and-build.sh
bash scripts/start-frontends.sh
```

```bat
scripts\setup.bat
scripts\reset-and-build.bat
scripts\start-frontends.bat
```


## 脚本行为

- 默认处理根仓库与 8 个子仓库；传入仓库名参数后只处理指定仓库。
- 如果目录不存在或不是 Git 仓库，会自动跳过。
- `commit_all.sh` 只会对存在变更的仓库提交；无改动仓库会跳过。
- `pull_all.sh` 和 `push_all.sh` 只处理工作区干净的仓库，避免把本地未提交改动卷入批量同步。
- `status_all` 会输出每个仓库的 `git status --short --branch` 结果，方便集中查看状态。
- 遇到 `detached HEAD`、未配置上游分支、分支已分叉等情况时，脚本会输出提示并跳过对应仓库。

## 建议流程

```bash
bash scripts/commit_all.sh "feat: your message"
bash scripts/push_all.sh
```

Windows 下可直接执行：

```bat
scripts\commit_all.bat "feat: your message"
scripts\push_all.bat
```

如果需要先同步远端再开始开发：

```bash
bash scripts/pull_all.sh
```

如果只想安装前端依赖：

```bash
bash scripts/install-frontends.sh
```

```bat
scripts\install-frontends.bat
```

如果需要导出当前工作区的关键环境文件：

```bash
bash scripts/package-selected-files.sh
bash scripts/package-selected-files.sh ./documents/my-selected-files.zip
bash scripts/package-selected-files.sh --skip-missing
```

```bat
scripts\package-selected-files.bat
scripts\package-selected-files.bat documents\my-selected-files.zip
scripts\package-selected-files.bat documents\selected-files.zip -SkipMissing
```

默认输出文件为 `documents/selected-files.zip`。该脚本当前会打包各仓库的 `.env` 文件；如果某些文件在本机尚未创建，可使用 `--skip-missing` 或 `-SkipMissing` 跳过缺失项。

开发过程中建议先看状态：

```bash
bash scripts/status_all.sh
```

## 注意事项

- `commit_all` 会执行 `git add -A`，包括新增、修改、删除文件。
- `pull_all`、`push_all`、`status_all` 不会自动切换分支。
- 仓库名参数必须使用以下名称之一：`workspace-rw`、`core-platform`、`documents`、`rippleclio-admin-console`、`rippleclio-content`、`rippleclio-web`、`wabifair-admin-console`、`wabifair-commerce`、`wabifair-storefront-web`。
- 如果某个仓库需要特殊处理，建议单独进入仓库执行 Git 命令。