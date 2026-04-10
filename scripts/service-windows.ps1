# NetPanel Windows Service 管理脚本
# 需要以管理员身份运行
# 用法:
#   .\service-windows.ps1 install   - 安装服务
#   .\service-windows.ps1 uninstall - 卸载服务
#   .\service-windows.ps1 start     - 启动服务
#   .\service-windows.ps1 stop      - 停止服务
#   .\service-windows.ps1 restart   - 重启服务
#   .\service-windows.ps1 status    - 查看服务状态（含 PID、端口、版本）
#   .\service-windows.ps1 update    - 热更新（停止→替换二进制→启动）

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("install","uninstall","start","stop","restart","status","update")]
    [string]$Action,

    # update 子命令专用：指定新二进制路径，不指定则从 GitHub 下载最新版
    [Parameter(Mandatory=$false)]
    [string]$NewBinary = "",

    # install 子命令专用：覆盖默认端口
    [Parameter(Mandatory=$false)]
    [int]$Port = 0
)

$ServiceName = "NetPanel"
$DisplayName = "NetPanel - Network Management Panel"
$Description = "NetPanel 网络管理面板，提供端口映射、组网、DDNS 等功能。"
$BinaryName  = "netpanel.exe"
$DefaultPort = 8080
$RepoOwner   = "YOUR_ORG"   # TODO: 替换为实际 GitHub 组织/用户名
$RepoName    = "netpanel"

# ── 从注册表读取安装信息（InnoSetup 安装后写入）──────────────
function Get-InstallInfo {
    $info = @{
        InstallPath = $null
        DataPath    = $null
        Version     = $null
        Port        = $DefaultPort
    }
    try {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\$ServiceName" -ErrorAction SilentlyContinue
        if ($reg) {
            if ($reg.InstallPath) { $info.InstallPath = $reg.InstallPath }
            if ($reg.DataPath)    { $info.DataPath    = $reg.DataPath    }
            if ($reg.Version)     { $info.Version     = $reg.Version     }
            if ($reg.Port)        { $info.Port        = [int]$reg.Port   }
        }
    } catch {}

    # 回退：使用默认路径
    if (-not $info.InstallPath) {
        $info.InstallPath = Join-Path $env:ProgramFiles $ServiceName
    }
    if (-not $info.DataPath) {
        $info.DataPath = Join-Path $env:ProgramData $ServiceName
    }
    return $info
}

$InstallInfo = Get-InstallInfo
$InstallDir  = $InstallInfo.InstallPath
$DataDir     = $InstallInfo.DataPath
$BinaryPath  = Join-Path $InstallDir $BinaryName
$ListenPort  = if ($Port -gt 0) { $Port } else { $InstallInfo.Port }

# ── 颜色输出辅助 ────────────────────────────────────────────
function Write-OK    { param($msg) Write-Host "✅ $msg" -ForegroundColor Green  }
function Write-Warn  { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "❌ $msg" -ForegroundColor Red    }
function Write-Info  { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan   }

# ── 检查管理员权限 ──────────────────────────────────────────
function Assert-Admin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Err "请以管理员身份运行此脚本！"
        exit 1
    }
}

# ── 获取二进制版本号 ────────────────────────────────────────
function Get-BinaryVersion {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "未知" }
    try {
        $ver = & $Path --version 2>&1 | Select-Object -First 1
        if ($ver) { return $ver.Trim() }
    } catch {}
    # 回退：读取文件版本信息
    try {
        $fv = (Get-Item $Path).VersionInfo.FileVersion
        if ($fv) { return $fv }
    } catch {}
    return "未知"
}

# ── 获取服务进程 PID ────────────────────────────────────────
function Get-ServicePID {
    try {
        $svc = Get-WmiObject Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
        if ($svc -and $svc.ProcessId -gt 0) { return $svc.ProcessId }
    } catch {}
    return $null
}

# ── 获取端口占用进程 ────────────────────────────────────────
function Get-PortProcess {
    param([int]$PortNum)
    try {
        $conn = Get-NetTCPConnection -LocalPort $PortNum -State Listen -ErrorAction SilentlyContinue
        if ($conn) { return $conn.OwningProcess }
    } catch {}
    return $null
}

# ── 从 GitHub 下载最新版本 ──────────────────────────────────
function Download-LatestBinary {
    param([string]$DestPath)

    Write-Info "正在查询 GitHub 最新版本..."
    try {
        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest" `
            -Headers @{ "User-Agent" = "NetPanel-Updater" } `
            -ErrorAction Stop
        $tag = $release.tag_name
        Write-Info "最新版本: $tag"

        $asset = $release.assets | Where-Object { $_.name -like "*windows-amd64*" } | Select-Object -First 1
        if (-not $asset) {
            Write-Err "未找到 Windows amd64 发布包，请手动下载。"
            exit 1
        }

        $tmpZip = Join-Path $env:TEMP "netpanel-update.zip"
        Write-Info "下载中: $($asset.browser_download_url)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmpZip -UseBasicParsing

        # 解压并提取 netpanel.exe
        $tmpDir = Join-Path $env:TEMP "netpanel-update"
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
        Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

        $newExe = Get-ChildItem -Path $tmpDir -Filter "netpanel.exe" -Recurse | Select-Object -First 1
        if (-not $newExe) {
            Write-Err "解压后未找到 netpanel.exe，请手动更新。"
            exit 1
        }

        Copy-Item -Path $newExe.FullName -Destination $DestPath -Force
        Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-OK "下载完成: $DestPath"
        return $tag
    } catch {
        Write-Err "下载失败: $_"
        exit 1
    }
}

# ── 安装服务 ────────────────────────────────────────────────
function Install-NetPanelService {
    Assert-Admin

    if (-not (Test-Path $BinaryPath)) {
        Write-Err "未找到可执行文件: $BinaryPath"
        Write-Host "请先将 netpanel.exe 复制到 $InstallDir"
        exit 1
    }

    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Warn "服务 '$ServiceName' 已存在，请先卸载后重新安装。"
        exit 1
    }

    # 创建数据目录
    foreach ($dir in @($DataDir, "$DataDir\data", "$DataDir\logs")) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    $binPathWithArgs = "`"$BinaryPath`" --port $ListenPort --data `"$DataDir\data`""

    New-Service `
        -Name           $ServiceName `
        -BinaryPathName $binPathWithArgs `
        -DisplayName    $DisplayName `
        -Description    $Description `
        -StartupType    Automatic `
        | Out-Null

    # 设置服务失败恢复策略：前两次失败 5s/10s 后重启，第三次 30s 后重启
    sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null

    # 写入端口到注册表，供 status 命令读取
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\$ServiceName" -Name "Port" -Value $ListenPort -ErrorAction SilentlyContinue
    } catch {}

    Write-OK "服务 '$ServiceName' 安装成功。"
    Write-Info "安装目录: $InstallDir"
    Write-Info "数据目录: $DataDir\data"
    Write-Info "监听端口: $ListenPort"
    Write-Host ""
    Write-Host "使用以下命令启动服务:"
    Write-Host "   .\service-windows.ps1 start"
}

# ── 卸载服务 ────────────────────────────────────────────────
function Uninstall-NetPanelService {
    Assert-Admin

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Warn "服务 '$ServiceName' 不存在。"
        exit 0
    }

    if ($svc.Status -eq "Running") {
        Write-Info "正在停止服务..."
        Stop-Service -Name $ServiceName -Force
        Start-Sleep -Seconds 2
    }

    # 优先使用 Remove-Service（PS6+），回退到 sc.exe（PS5）
    try {
        Remove-Service -Name $ServiceName -ErrorAction Stop
    } catch {
        sc.exe delete $ServiceName | Out-Null
    }

    # 等待服务完全删除
    $retries = 0
    while ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) -and $retries -lt 10) {
        Start-Sleep -Milliseconds 500
        $retries++
    }

    Write-OK "服务 '$ServiceName' 已卸载。"
    Write-Warn "安装目录 '$InstallDir' 未被删除，如需清理请手动删除。"
    Write-Warn "数据目录 '$DataDir' 未被删除，如需清理请手动删除。"
}

# ── 启动服务 ────────────────────────────────────────────────
function Start-NetPanelService {
    Assert-Admin
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Err "服务未安装，请先执行 install。"; exit 1 }
    if ($svc.Status -eq "Running") { Write-OK "服务已在运行中。"; exit 0 }
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 2
    $svc.Refresh()
    if ($svc.Status -eq "Running") {
        Write-OK "服务已启动，访问 http://localhost:$ListenPort"
    } else {
        Write-Err "服务启动失败，请检查事件日志：eventvwr.msc"
        exit 1
    }
}

# ── 停止服务 ────────────────────────────────────────────────
function Stop-NetPanelService {
    Assert-Admin
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Err "服务未安装。"; exit 1 }
    if ($svc.Status -eq "Stopped") { Write-OK "服务已停止。"; exit 0 }
    Stop-Service -Name $ServiceName -Force
    Write-OK "服务已停止。"
}

# ── 重启服务 ────────────────────────────────────────────────
function Restart-NetPanelService {
    Assert-Admin
    Stop-NetPanelService
    Start-Sleep -Seconds 2
    Start-NetPanelService
}

# ── 查看状态（含 PID、端口占用、版本）──────────────────────
function Get-NetPanelStatus {
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  NetPanel 服务状态" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

    if (-not $svc) {
        Write-Host "  服务状态  : " -NoNewline; Write-Host "未安装" -ForegroundColor Red
    } else {
        $statusColor = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  服务名称  : $($svc.Name)"
        Write-Host "  显示名称  : $($svc.DisplayName)"
        Write-Host "  运行状态  : " -NoNewline
        Write-Host "$($svc.Status)" -ForegroundColor $statusColor
        Write-Host "  启动类型  : $($svc.StartType)"

        # PID
        $pid = Get-ServicePID
        if ($pid) {
            Write-Host "  进程 PID  : $pid"
            try {
                $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($proc) {
                    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 1)
                    Write-Host "  内存占用  : ${mem} MB"
                    Write-Host "  运行时长  : $([math]::Round((Get-Date - $proc.StartTime).TotalMinutes, 1)) 分钟"
                }
            } catch {}
        }
    }

    # 版本信息
    $binVer = Get-BinaryVersion -Path $BinaryPath
    $regVer = $InstallInfo.Version
    Write-Host "  二进制版本: $binVer"
    if ($regVer) { Write-Host "  安装版本  : $regVer" }

    # 端口占用
    $portPid = Get-PortProcess -PortNum $ListenPort
    Write-Host "  监听端口  : $ListenPort" -NoNewline
    if ($portPid) {
        Write-Host " (PID: $portPid 占用)" -ForegroundColor Green
    } else {
        Write-Host " (未监听)" -ForegroundColor Yellow
    }

    # 路径信息
    Write-Host "  安装目录  : $InstallDir"
    Write-Host "  数据目录  : $DataDir"
    Write-Host "  访问地址  : http://localhost:$ListenPort"
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ── 热更新（停止→替换二进制→启动）──────────────────────────
function Update-NetPanelService {
    Assert-Admin

    Write-Info "开始热更新 NetPanel..."

    # 确定新二进制来源
    $tmpBinary = ""
    if ($NewBinary -ne "" -and (Test-Path $NewBinary)) {
        # 使用用户指定的本地文件
        $tmpBinary = $NewBinary
        Write-Info "使用本地文件: $tmpBinary"
    } else {
        # 从 GitHub 下载最新版本到临时目录
        $tmpBinary = Join-Path $env:TEMP "netpanel-new.exe"
        $newTag = Download-LatestBinary -DestPath $tmpBinary
    }

    # 备份当前版本
    if (Test-Path $BinaryPath) {
        $backupPath = "$BinaryPath.bak"
        Copy-Item -Path $BinaryPath -Destination $backupPath -Force
        Write-Info "已备份旧版本: $backupPath"
    }

    # 停止服务
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    $wasRunning = $false
    if ($svc -and $svc.Status -eq "Running") {
        Write-Info "正在停止服务..."
        Stop-Service -Name $ServiceName -Force
        Start-Sleep -Seconds 3
        $wasRunning = $true
    }

    # 替换二进制
    try {
        Copy-Item -Path $tmpBinary -Destination $BinaryPath -Force
        Write-OK "二进制文件已更新: $BinaryPath"
    } catch {
        Write-Err "替换二进制失败: $_"
        # 尝试回滚
        if (Test-Path "$BinaryPath.bak") {
            Copy-Item -Path "$BinaryPath.bak" -Destination $BinaryPath -Force
            Write-Warn "已回滚到旧版本。"
        }
        exit 1
    }

    # 清理临时文件（仅当是下载的临时文件时）
    if ($NewBinary -eq "" -and (Test-Path $tmpBinary)) {
        Remove-Item $tmpBinary -Force -ErrorAction SilentlyContinue
    }

    # 重新启动服务
    if ($wasRunning -or ($svc -ne $null)) {
        Write-Info "正在启动服务..."
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 2
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            $newVer = Get-BinaryVersion -Path $BinaryPath
            Write-OK "热更新完成！当前版本: $newVer"
            Write-Info "访问地址: http://localhost:$ListenPort"
        } else {
            Write-Err "服务启动失败，请检查事件日志：eventvwr.msc"
            exit 1
        }
    } else {
        $newVer = Get-BinaryVersion -Path $BinaryPath
        Write-OK "二进制已更新（服务未运行）。当前版本: $newVer"
        Write-Info "使用 '.\service-windows.ps1 start' 启动服务。"
    }
}

# ── 入口 ────────────────────────────────────────────────────
switch ($Action) {
    "install"   { Install-NetPanelService   }
    "uninstall" { Uninstall-NetPanelService }
    "start"     { Start-NetPanelService     }
    "stop"      { Stop-NetPanelService      }
    "restart"   { Restart-NetPanelService   }
    "status"    { Get-NetPanelStatus        }
    "update"    { Update-NetPanelService    }
}