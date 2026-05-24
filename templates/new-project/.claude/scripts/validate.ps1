# Claude Code Template Validator (PowerShell)
# 验证 init 后的项目模板完整性。兼容 PowerShell 5.1+。
# Exit: 0=全绿 / 1=有错误 / 2=仅警告

param([switch]$Force, [switch]$f)

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $Root

# Treat both -Force and -f as force mode
$ForceMode = $Force -or $f

# 检测：若 project.env 仍存在 → 模板未初始化，跳过扫描避免假警告
if (-not $ForceMode -and (Test-Path "project.env")) {
    Write-Host "━━━ Claude Code Template Validator ━━━`n"
    Write-Host "ℹ️  检测到 project.env 仍存在 — 模板尚未初始化。`n"
    Write-Host "请先完成初始化（任选其一）："
    Write-Host "  • Claude Code 环境：/project:init"
    Write-Host "  • 纯 shell 环境:    bash init.sh`n"
    Write-Host "初始化完成后再跑本脚本验证。"
    Write-Host "若需强制验证模板自身完整性（如模板维护者），加 --force flag。"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
}

$Errors = 0
$Warnings = 0
Write-Host "━━━ Claude Code Template Validator ━━━"
Write-Host ""

# ---- 1. 必需文件存在性 ----
$Required = @(
  'CLAUDE.md',
  'progress.md',
  '.claude\settings.json',
  '.claude\rules\engineering.md',
  '.claude\rules\behavioral-rules.md',
  '.claude\rules\git-workflow.md',
  '.githooks\pre-commit',
  '.githooks\install.sh'
)
$Missing = @($Required | Where-Object { -not (Test-Path $_) })
if ($Missing.Count -eq 0) {
  Write-Host "✅ 必需文件齐全"
} else {
  Write-Host "❌ 缺失必需文件:"
  $Missing | ForEach-Object { Write-Host "   $_" }
  $Errors++
}

$JqCommand = Get-Command jq -ErrorAction SilentlyContinue
if ($JqCommand) {
  Write-Host "✅ jq 可用"
} else {
  Write-Host "❌ jq 不可用；Claude Code Bash 安全 hook 依赖 jq"
  $Errors++
}

$BashCommand = Get-Command bash -ErrorAction SilentlyContinue
if (-not $BashCommand) {
  Write-Host "❌ bash 不可用；Windows 环境请安装 Git Bash 并加入 PATH"
  $Errors++
} elseif ($BashCommand.Source -match '\\Windows\\System32\\bash\.exe$') {
  Write-Host "❌ bash 当前解析到 WSL launcher：$($BashCommand.Source)"
  Write-Host "   请将 Git Bash 放到 PATH 中更靠前的位置，或在 Claude Code hooks 中显式改为 Git Bash 路径。"
  $Errors++
} else {
  Write-Host "✅ bash 可用: $($BashCommand.Source)"
}

# ---- 2. 残留占位符扫描 ----
$ScanTargets = @(
  'CLAUDE.md',
  'progress.md',
  '.claude\rules\git-workflow.md',
  '.claude\rules\behavioral-rules.md',
  '.claude\rules\project-context.md',
  '.claude\rules\stack-backend.md',
  '.claude\rules\stack-frontend.md',
  '.claude\rules\README.md',
  '.githooks\pre-commit'
)
$PlaceholderPattern = '\[[A-Z][A-Z0-9_]+\]|\[[a-z]+-dir\]'
$PlaceholderHits = @()
foreach ($file in $ScanTargets) {
  if (-not (Test-Path $file)) { continue }
  $matches = Select-String -Path $file -Pattern $PlaceholderPattern -AllMatches -CaseSensitive -ErrorAction SilentlyContinue
  foreach ($m in $matches) {
    foreach ($mm in $m.Matches) {
      $PlaceholderHits += "   $($m.Path):$($m.LineNumber):$($mm.Value)"
    }
  }
}
if ($PlaceholderHits.Count -eq 0) {
  Write-Host "✅ 无残留占位符"
} else {
  Write-Host "⚠️  发现 $($PlaceholderHits.Count) 处残留占位符:"
  $PlaceholderHits | ForEach-Object { Write-Host $_ }
  $Warnings++
}

# ---- 3. Git hook 已安装 ----
if (Test-Path '.git') {
  $HooksPath = (& git config core.hooksPath 2>$null)
  $NormalizedHooksPath = ($HooksPath -replace '\\', '/')
  if ($NormalizedHooksPath -eq '.githooks' -or $NormalizedHooksPath.EndsWith('/.githooks')) {
    Write-Host "✅ Git hook 已安装"
  } else {
    Write-Host "⚠️  Git hook 未安装 — 跑 ``bash .githooks/install.sh``"
    $Warnings++
  }
} else {
  Write-Host "ℹ️  非 git repo，跳过 hook 检查"
}

# ---- 4. 未清理的初始化产物 ----
$Leftovers = @('project.env', 'init.sh', 'SETUP.md') | Where-Object { Test-Path $_ }
if ($Leftovers.Count -eq 0) {
  Write-Host "✅ 初始化产物已清理"
} else {
  Write-Host "⚠️  发现遗留初始化产物（建议删除）:"
  $Leftovers | ForEach-Object { Write-Host "   $_" }
  $Warnings++
}

# ---- 5. Rules 内部链接完整性 ----
$BrokenLinks = @()
if (Test-Path '.claude\rules') {
  $LinkPattern = '\]\((\.{1,2}/[^)]+\.md[^)]*|[a-zA-Z][^):/]*\.md[^)]*)\)'
  Get-ChildItem -Path '.claude\rules' -Filter '*.md' -File | ForEach-Object {
    $file = $_.FullName
    $dir = $_.DirectoryName
    $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    $regex = [regex]$LinkPattern
    foreach ($match in $regex.Matches($content)) {
      $link = $match.Groups[1].Value -replace '#.*$', ''
      if ([string]::IsNullOrWhiteSpace($link)) { continue }
      $target = Join-Path $dir $link
      if (-not (Test-Path $target)) {
        $rel = Resolve-Path -Path $file -Relative
        $BrokenLinks += "   $rel → $link"
      }
    }
  }
}
if ($BrokenLinks.Count -eq 0) {
  Write-Host "✅ Rules 内部链接全部有效"
} else {
  Write-Host "❌ 发现 $($BrokenLinks.Count) 处死链:"
  $BrokenLinks | ForEach-Object { Write-Host $_ }
  $Errors++
}

# ---- 总结 ----
Write-Host ""
Write-Host "━━━ 验证结果: $Warnings 警告 / $Errors 错误 ━━━"
if ($Errors -gt 0) {
  Write-Host "退出码: 1 (有错误)"
  exit 1
} elseif ($Warnings -gt 0) {
  Write-Host "退出码: 2 (仅警告)"
  exit 2
} else {
  Write-Host "退出码: 0 (全绿)"
  exit 0
}
