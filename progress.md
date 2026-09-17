# Claude Code 配置仓库进度

更新时间：2026-09-17

## 当前任务

修复状态栏偶发弹出 Windows「打开方式」对话框、要求打开 `statusline-render.py` 的问题，并集成到 `feature/dev`；本记录随本次合并提交保存。

## 根因

- miniconda 于 2026-09-14 16:13 被卸载，`statusline-lines.sh` 写死的 `/c/Users/dev002/miniconda3/python` 退路失效，状态栏改走 PATH 上的 pyenv-win shim `python3`。
- shim 的 `pyenv exec $(basename "$0") "$@"` 没有给命令替换加引号；`basename` 偶发无输出时，`python3` 这个参数整个消失，渲染脚本路径落到了命令位置。
- `pyenv.bat exec` 把第一个参数交给 cmd 执行，cmd 按 `.py` 的文件关联去打开它，于是弹出「打开方式」。
- 实证：2026-09-17 09:59:48 捕获到存活的进程链 `sh pyenv exec <renderer>` → `cmd /C call pyenv.bat exec <renderer>` → `sakura.exe <renderer>`，正常情况下 `exec` 之后应为 `python3`。当天共弹出三次：09:54:07、09:55:22、09:59:48。
- 未证实：`basename` 为何偶发无输出。旁证是同日 10:08:50 在状态栏工作目录新出现的 `bash.exe.stackdump`。

## 修复内容

- `statusline-lines.sh` 新增 `real_python`：优先使用 pyenv-win 当前全局版本的 `python.exe`（版本文件为 CRLF，需去掉 `\r`），其次 `$HOME/miniconda3/python.exe`，两者都没有时才回退到 PATH 查找；`CLAUDE_STATUS_PYTHON` 仍优先于一切。写死的 miniconda 绝对路径改为基于 `$HOME` 的路径。
- 不修改 shim 本身：`pyenv rehash` 会重新生成 shim 并覆盖改动。
- 新增 `scripts/tests/statusline-python.sh`：在临时 HOME 中用受控的假解释器运行真实的状态栏脚本，共 4 项。

## 验证记录

- 修复前：新测试前 3 项失败，日志均为 `SHIM_USED`；第 4 项（没有已知解释器时回退 PATH）通过。
- 修复提交 `2c43380`：新测试 4 项全部通过；`merge-blockers.sh` 12 项全部通过，0 失败；`git diff --cached --check` 通过。
- 本机实测：状态栏直接调用 `C:\Users\dev002\.pyenv\pyenv-win\versions\3.12.3\python.exe`，不再经过 shim。
- 当前合并结果：两套测试均为 0 失败；14 个受跟踪的 Bash 脚本语法检查通过；原四项未提交文件的 SHA-256 合并前后一致。

## 分支与工作区约束

- 集成目标仅为 `feature/dev`，基线为 `74d1e4e`；修复分支为 `feature/fix-statusline-shim-20260917` 的 `2c43380`。
- `main` 保持 `dc76f52`；未经用户明确授权，不得合入 `main`。
- 原有未提交的 `settings.json`、`.last-update-result.json`、`AGENTS.md` 与 `research/` 不包含在本次合并中。
- 行尾约定：仓库内为 LF，工作区为 CRLF（`core.autocrlf=true`，无 `.gitattributes`）；Git Bash 可正常执行 CRLF 工作副本，本次未改变该约定。
- 本次仅本地合并，未推送。

## 上一项

- 2026-09-15：密钥扫描 hook 的 JSON 输出修复，以及模板迁移保留已有 hook；修复提交 `4bc1cb5`，合并 `74d1e4e`，`merge-blockers.sh` 12 项通过。
