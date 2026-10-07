# ChatGPT 桌面�?"Reconnecting... waiting for network" 修复指南

> 适用：Windows 上的 ChatGPT 桌面应用（OpenAI Codex / ChatGPT Desktop，AppID `OpenAI.Codex_...!App`�?
> 症状：消息能发出去，但一直转�?/ "Reconnecting... waiting for network" / "Connection failed"，网页版却正常�?

## 根因

桌面版底层是原生后端进程 `codex` / `codex-computer-use-swift`�?*不读 Windows 系统代理**（IE/系统设置里的代理对它无效）�?
它直�?OpenAI，在国内被墙 �?请求能发出去但流式响应收不回 �?一�?"waiting for network"�?

网页�?Chrome 走系统代理所以正常，别被它误导�?

## 前置条件

- 本地有代理在跑（Clash / V2rayN / Mihomo 等），确认混合端口�?
- 本指南以 Clash Verge 为例，混合端口是 `7897`�?*其他客户端把端口换成你自己的**（Clash 默认 7890，V2rayN 默认 10809）�?

先验证代理口可用�?

```powershell
curl.exe -x http://127.0.0.1:7897 https://www.google.com -I
# 返回 HTTP/2 200 就说明代理口没问�?
```

## 一、永久设置用户级代理环境变量（关键）

PowerShell 里执行（�?`7897` 换成你的端口）：

```powershell
[Environment]::SetEnvironmentVariable("HTTP_PROXY","http://127.0.0.1:7897","User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY","http://127.0.0.1:7897","User")
[Environment]::SetEnvironmentVariable("ALL_PROXY","http://127.0.0.1:7897","User")
```

- 写在 `User` 级，重启电脑不丢�?
- 三个都设：`HTTP_PROXY` 管普�?http，`HTTPS_PROXY` �?https（OpenAI 全是 https，这个最关键），`ALL_PROXY` 兜底�?

## 二、不重启电脑让它立刻生效

新环境变�?explorer 不会自动加载，广播一�?`WM_SETTINGCHANGE`�?

```powershell
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class E {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
$HWND_BROADCAST = [IntPtr]0xffff
$result = [UIntPtr]::Zero
[E]::SendMessageTimeout($HWND_BROADCAST, 0x1A, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
```

## 三、彻底重启桌面版

杀掉所有残留进程再开�?

```powershell
Stop-Process -Name ChatGPT,codex,codex-computer-use-swift -Force -ErrorAction SilentlyContinue
```

然后从开始菜�?/ 桌面图标正常启动 ChatGPT。发一�?"只回�?已连�?两个�? 测试，看�?正在思�?而不�?"Reconnecting" 就成了�?

## 验证清单

- [ ] 代理软件托盘在跑、系统代理已开
- [ ] `curl.exe -x http://127.0.0.1:7897 https://www.google.com -I` 返回 200
- [ ] 环境变量已写入（`[Environment]::GetEnvironmentVariable("HTTPS_PROXY","User")`�?
- [ ] 桌面版发消息后显�?正在思�?，不�?"Reconnecting... waiting for network"
- [ ] 能正常出回复 / 出图

## 为什么网页版没事、桌面版有事

| 客户�?| 走系统代理？ | 走环境变量？ | 国内结果 |
|---|---|---|---|
| Chrome / Edge | �?自动 | �?| 正常 |
| ChatGPT 桌面版（Codex 后端�?| �?不读 | �?�?HTTP(S)_PROXY | 默认直连被墙，设了才�?|

## 常见�?

1. **端口不对**：Clash Verge 新版默认 `7897`，旧�?原版 Clash �?`7890`。在 Clash �?设置 �?端口设置"里看混合端口�?
2. **设了但没杀进程重启**：正在跑的进程读不到新变量，必须 `Stop-Process` 后重开�?
3. **代理软件没开**：环境变量指向的 `127.0.0.1:7897` 没人监听，反而更�?超时。先开 Clash 再开 ChatGPT�?
4. **企业杀�?防火墙拦原生后端**：极少数情况 `codex` 进程被拦，看一下防火墙日志�?
5. **想取�?*：`[Environment]::SetEnvironmentVariable("HTTPS_PROXY",$null,"User")` 三个都清掉即可�?

## 一键脚�?

保存�?`fix-chatgpt-proxy.ps1`，右�?使用 PowerShell 运行"（端口按自己情况改）�?

```powershell
$port = "7897"
[Environment]::SetEnvironmentVariable("HTTP_PROXY","http://127.0.0.1:$port","User")
[Environment]::SetEnvironmentVariable("HTTPS_PROXY","http://127.0.0.1:$port","User")
[Environment]::SetEnvironmentVariable("ALL_PROXY","http://127.0.0.1:$port","User")
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
Stop-Process -Name ChatGPT,codex,codex-computer-use-swift -Force -ErrorAction SilentlyContinue
Write-Host "Done. 现在从开始菜单重新打开 ChatGPT�? -ForegroundColor Green
```

---
实测环境：Windows 11 + Clash Verge（mihomo，混合口 7897�? ChatGPT 桌面版（OpenAI.Codex 26.908.9136.0）�?
