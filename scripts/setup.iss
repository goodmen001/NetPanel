; NetPanel Inno Setup 安装脚本
; 用法: iscc scripts/setup.iss
; 需要先构建: make build-frontend build-windows-amd64
; 输出: dist/NetPanel-Setup-<VERSION>-windows-amd64.exe
;
; 版本号优先级：
;   1. 环境变量 VERSION（CI/CD 注入，如 beta-abc1234 或 v1.2.3）
;   2. 默认值 0.1.0

#define AppName      "NetPanel"
#define AppVersion   GetEnv("VERSION")
#if AppVersion == ""
  #define AppVersion "0.1.0"
#endif
; VersionInfoVersion 必须是 x.x.x.x 纯数字格式（Windows PE 资源要求）
; 从 AppVersion 中提取数字部分：v1.2.3 -> 1.2.3，beta-abc1234 -> 0.0.0
#define AppVersionNumeric GetEnv("VERSION_NUMERIC")
#if AppVersionNumeric == ""
  #define AppVersionNumeric "0.0.0"
#endif
#define AppPublisher "NetPanel Team"
#define AppURL       "https://github.com/YOUR_ORG/netpanel"
#define AppExeName   "netpanel.exe"
#define ServiceName  "NetPanel"
#define AppDataDir   "{commonappdata}\NetPanel"
#define AppPort      "8080"

; ─── [Setup] ──────────────────────────────────────────────────────────────────

[Setup]
; 基本信息
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} v{#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases

; 安装目录
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes

; 输出
OutputDir=..\dist
OutputBaseFilename=NetPanel-Setup-{#AppVersion}-windows-amd64
SetupIconFile=..\backend\assets\frps\static\favicon.ico

; 压缩
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; 权限：必须以管理员身份运行（注册服务需要）
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=

; 架构
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; 界面
WizardStyle=modern
WizardSizePercent=120
DisableWelcomePage=no
LicenseFile=..\LICENSE

; 卸载
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} v{#AppVersion}
CreateUninstallRegKey=yes

; 版本信息（供 Windows 属性面板显示）
; VersionInfoVersion 必须是 x.x.x.x 纯数字格式，使用单独的 VERSION_NUMERIC 环境变量
VersionInfoVersion={#AppVersionNumeric}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} Network Manager
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersionNumeric}

; ─── [Languages] ──────────────────────────────────────────────────────────────

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"
Name: "english";           MessagesFile: "compiler:Default.isl"

; ─── [CustomMessages] ─────────────────────────────────────────────────────────

[CustomMessages]
; 中文
chinesesimplified.InstallService=安装为 Windows 系统服务（推荐，开机自启）
chinesesimplified.StartAfterInstall=安装完成后立即启动服务
chinesesimplified.OpenWebUI=安装完成后打开管理界面
chinesesimplified.CreateDesktopIcon=在桌面创建快捷方式
chinesesimplified.ServiceGroupDesc=服务选项:
chinesesimplified.OtherGroupDesc=其他选项:
chinesesimplified.ConfirmUninstall=确定要卸载 {#AppName} 吗？%n%n注意：用户数据目录 %%ProgramData%%\NetPanel 将被保留，如需彻底清除请手动删除。
chinesesimplified.UninstallKeepData=卸载程序（保留用户数据）
; 英文
english.InstallService=Install as Windows Service (recommended, auto-start on boot)
english.StartAfterInstall=Start service immediately after installation
english.OpenWebUI=Open management UI after installation
english.CreateDesktopIcon=Create desktop shortcut
english.ServiceGroupDesc=Service options:
english.OtherGroupDesc=Other options:
english.ConfirmUninstall=Are you sure you want to uninstall {#AppName}?%n%nNote: User data directory %%ProgramData%%\NetPanel will be kept. Delete it manually if needed.
english.UninstallKeepData=Uninstall (keep user data)

; ─── [Tasks] ──────────────────────────────────────────────────────────────────

[Tasks]
; 服务选项
Name: "installservice";  Description: "{cm:InstallService}";     GroupDescription: "{cm:ServiceGroupDesc}"; Flags: checked
Name: "startservice";    Description: "{cm:StartAfterInstall}";  GroupDescription: "{cm:ServiceGroupDesc}"; Flags: checked
; 其他选项
Name: "desktopicon";     Description: "{cm:CreateDesktopIcon}";  GroupDescription: "{cm:OtherGroupDesc}";   Flags: unchecked
Name: "openwebui";       Description: "{cm:OpenWebUI}";          GroupDescription: "{cm:OtherGroupDesc}";   Flags: checked

; ─── [Dirs] ───────────────────────────────────────────────────────────────────

[Dirs]
Name: "{#AppDataDir}";        Permissions: everyone-full
Name: "{#AppDataDir}\data";   Permissions: everyone-full
Name: "{#AppDataDir}\logs";   Permissions: everyone-full
Name: "{#AppDataDir}\bin";    Permissions: everyone-full

; ─── [Files] ──────────────────────────────────────────────────────────────────

[Files]
; 主程序
Source: "..\dist\netpanel-windows-amd64.exe"; DestDir: "{app}"; DestName: "{#AppExeName}"; Flags: ignoreversion

; 服务管理脚本
Source: "..\scripts\service-windows.ps1"; DestDir: "{app}"; Flags: ignoreversion

; 配置文件（首次安装时复制，升级时不覆盖用户配置）
Source: "..\scripts\config.example.yaml"; DestDir: "{#AppDataDir}"; DestName: "config.yaml"; \
  Flags: onlyifdoesntexist uninsneveruninstall; \
  Check: FileExists(ExpandConstant('{src}\..\scripts\config.example.yaml'))

; 可选：EasyTier 二进制（如果存在则一并打包）
Source: "..\dist\bin\easytier-core.exe"; DestDir: "{#AppDataDir}\bin"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\dist\bin\easytier-cli.exe";  DestDir: "{#AppDataDir}\bin"; Flags: ignoreversion skipifsourcedoesntexist

; ─── [Icons] ──────────────────────────────────────────────────────────────────

[Icons]
; 开始菜单 - 管理界面
Name: "{group}\{#AppName} 管理界面"; \
  Filename: "{app}\{#AppExeName}"; \
  Parameters: "--open-browser"; \
  WorkingDir: "{app}"; \
  Comment: "打开 NetPanel 网络管理界面"

; 开始菜单 - 服务状态
Name: "{group}\{#AppName} 服务状态"; \
  Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoExit -File ""{app}\service-windows.ps1"" status"; \
  WorkingDir: "{app}"; \
  Comment: "查看 NetPanel 服务运行状态"

; 开始菜单 - 服务管理（管理员）
Name: "{group}\{#AppName} 服务管理（管理员）"; \
  Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoExit -File ""{app}\service-windows.ps1"" status"; \
  WorkingDir: "{app}"; \
  Comment: "以管理员身份管理 NetPanel 服务"

; 开始菜单 - 卸载
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"

; 桌面快捷方式（可选任务）
Name: "{autodesktop}\{#AppName}"; \
  Filename: "{app}\{#AppExeName}"; \
  Parameters: "--open-browser"; \
  WorkingDir: "{app}"; \
  Tasks: desktopicon

; ─── [Registry] ───────────────────────────────────────────────────────────────

[Registry]
; 写入安装信息，供 service-windows.ps1 和其他工具查询
Root: HKLM; Subkey: "SOFTWARE\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}";          Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\{#AppName}"; ValueType: string; ValueName: "DataPath";    ValueData: "{#AppDataDir}";  Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\{#AppName}"; ValueType: string; ValueName: "Version";     ValueData: "{#AppVersion}";  Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\{#AppName}"; ValueType: dword;  ValueName: "Port";        ValueData: "{#AppPort}";     Flags: uninsdeletekey

; 防火墙规则（允许 NetPanel 入站）
Root: HKLM; \
  Subkey: "SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"; \
  ValueType: string; \
  ValueName: "NetPanel-In-TCP-{#AppPort}"; \
  ValueData: "v2.30|Action=Allow|Active=TRUE|Dir=In|Protocol=6|LPort={#AppPort}|Name=NetPanel|Desc=NetPanel Network Manager|App={app}\{#AppExeName}|"; \
  Flags: uninsdeletevalue

; ─── [Run] ────────────────────────────────────────────────────────────────────

[Run]
; 1. 注册 Windows 服务（选择了 installservice 任务时）
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -File ""{app}\service-windows.ps1"" install"; \
  WorkingDir: "{app}"; \
  StatusMsg: "正在注册系统服务..."; \
  Flags: runhidden waituntilterminated; \
  Tasks: installservice

; 2. 启动服务（选择了 startservice 任务时）
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -File ""{app}\service-windows.ps1"" start"; \
  WorkingDir: "{app}"; \
  StatusMsg: "正在启动服务..."; \
  Flags: runhidden waituntilterminated; \
  Tasks: installservice and startservice

; 3. 非服务模式：直接前台启动（未选择 installservice 时）
Filename: "{app}\{#AppExeName}"; \
  WorkingDir: "{app}"; \
  StatusMsg: "正在启动 NetPanel..."; \
  Flags: nowait postinstall skipifsilent; \
  Tasks: not installservice

; 4. 打开管理界面（选择了 openwebui 任务时）
Filename: "cmd.exe"; \
  Parameters: "/c timeout /t 3 /nobreak >nul && start http://localhost:{#AppPort}"; \
  StatusMsg: "正在打开管理界面..."; \
  Flags: runhidden nowait postinstall skipifsilent; \
  Tasks: openwebui

; ─── [UninstallRun] ───────────────────────────────────────────────────────────

[UninstallRun]
; 卸载前：停止并删除 Windows 服务（保留数据目录）
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -Command ""Stop-Service -Name '{#ServiceName}' -Force -ErrorAction SilentlyContinue; Start-Sleep 2; & '{app}\service-windows.ps1' uninstall"""; \
  WorkingDir: "{app}"; \
  Flags: runhidden waituntilterminated; \
  RunOnceId: "StopAndRemoveService"

; ─── [UninstallDelete] ────────────────────────────────────────────────────────

[UninstallDelete]
; 卸载时清理日志目录（保留用户数据 data/ 目录）
Type: filesandordirs; Name: "{#AppDataDir}\logs"

; ─── [Code] ───────────────────────────────────────────────────────────────────

[Code]

// ─── 全局变量 ─────────────────────────────────────────────────────────────────
var
  OldVersionFound: Boolean;
  OldVersion: String;

// ─── 安装前检查：检测已安装旧版本 ────────────────────────────────────────────
function InitializeSetup(): Boolean;
var
  Uninstaller: String;
  ResultCode: Integer;
  MsgResult: Integer;
begin
  Result := True;
  OldVersionFound := False;

  // 从注册表读取已安装版本
  if RegQueryStringValue(HKLM, 'SOFTWARE\{#AppName}', 'Version', OldVersion) then
  begin
    OldVersionFound := True;

    // 提示用户：检测到旧版本，询问处理方式
    MsgResult := MsgBox(
      '检测到已安装 {#AppName} v' + OldVersion + '。' + #13#10 + #13#10 +
      '点击【是】：先卸载旧版本，再安装新版本（推荐）' + #13#10 +
      '点击【否】：直接覆盖安装（保留现有配置）' + #13#10 +
      '点击【取消】：退出安装程序',
      mbConfirmation,
      MB_YESNOCANCEL
    );

    case MsgResult of
      IDCANCEL:
      begin
        Result := False;
        Exit;
      end;
      IDYES:
      begin
        // 先停止服务
        Exec(
          'powershell.exe',
          '-ExecutionPolicy Bypass -Command "Stop-Service -Name ''{#ServiceName}'' -Force -ErrorAction SilentlyContinue"',
          '', SW_HIDE, ewWaitUntilTerminated, ResultCode
        );

        // 运行旧版卸载程序（静默模式）
        if RegQueryStringValue(
          HKLM,
          'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}_is1',
          'UninstallString',
          Uninstaller
        ) then
        begin
          Exec(RemoveQuotes(Uninstaller), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
        end;
      end;
      // IDNO：直接覆盖，不做额外处理
    end;
  end;
end;

// ─── 安装完成后：更新注册表版本号 ────────────────────────────────────────────
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 更新注册表中的版本号（覆盖安装时旧值可能残留）
    RegWriteStringValue(HKLM, 'SOFTWARE\{#AppName}', 'Version', '{#AppVersion}');
    RegWriteStringValue(HKLM, 'SOFTWARE\{#AppName}', 'InstallPath', ExpandConstant('{app}'));
    RegWriteStringValue(HKLM, 'SOFTWARE\{#AppName}', 'DataPath', ExpandConstant('{commonappdata}\NetPanel'));
  end;
end;

// ─── 卸载前确认 ───────────────────────────────────────────────────────────────
function InitializeUninstall(): Boolean;
begin
  Result := MsgBox(
    ExpandConstant('{cm:ConfirmUninstall}'),
    mbConfirmation,
    MB_YESNO
  ) = IDYES;
end;

// ─── 卸载完成后：提示数据目录位置 ────────────────────────────────────────────
procedure DeinitializeUninstall();
begin
  MsgBox(
    '{#AppName} 已卸载完成。' + #13#10 + #13#10 +
    '用户数据目录已保留：' + #13#10 +
    '  %ProgramData%\NetPanel' + #13#10 + #13#10 +
    '如需彻底清除，请手动删除该目录。',
    mbInformation,
    MB_OK
  );
end;