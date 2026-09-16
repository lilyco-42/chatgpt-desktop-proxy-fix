# fix-chatgpt-proxy.ps1
# ChatGPT 桌面版 "Reconnecting... waiting for network" 一键修复
# 用法：右键 -> 使用 PowerShell 运行。端口按你的代理客户端改。

$port = "7897"   # Clash Verge 默认 7897；Clash for Windows / mihomo 默认 7890；V2rayN 默认 10809

Write-Host "[1/4] 设置用户级代理环境变量..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("HTTP_PROXY",  "http://127.0.0.1:$port", "User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://127.0.0.1:$port", "User")
[Environment]::SetEnvironmentVariable("ALL_PROXY",   "http://127.0.0.1:$port", "User")

Write-Host "[2/4] 广播环境变量变更（不重启资源管理器）..." -ForegroundColor Cyan
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class E {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
$result = [UIntPtr]::Zero
[E]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null

Write-Host "[3/4] 杀掉 ChatGPT / codex 残留进程..." -ForegroundColor Cyan
Stop-Process -Name ChatGPT, codex, codex-computer-use-swift -Force -ErrorAction SilentlyContinue

Write-Host "[4/4] 验证代理口 $port ..." -ForegroundColor Cyan
$check = curl.exe -x "http://127.0.0.1:$port" https://www.google.com -I -s --max-time 10
if ($check -match "200") {
    Write-Host "代理口 $port 正常。现在从开始菜单重新打开 ChatGPT 即可。" -ForegroundColor Green
} else {
    Write-Host "警告：代理口 $port 没通。先确认 Clash/代理软件已启动且端口正确。" -ForegroundColor Yellow
}
