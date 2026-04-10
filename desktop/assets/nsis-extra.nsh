; NetPanel NSIS 额外脚本
; 在安装前停止旧服务，在卸载时停止并删除服务

; ─── 安装前：停止已有 NetPanel 服务 ──────────────────────────
!macro customInstall
  ; 尝试停止已有服务（忽略错误）
  nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -Command "Stop-Service -Name NetPanel -Force -ErrorAction SilentlyContinue"'
  Sleep 2000
!macroend

; ─── 卸载前：停止并删除 NetPanel 服务 ────────────────────────
!macro customUnInstall
  ; 停止服务
  nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -Command "Stop-Service -Name NetPanel -Force -ErrorAction SilentlyContinue"'
  Sleep 2000
  ; 删除服务
  nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -Command "& \"$INSTDIR\resources\netpanel.exe\" --uninstall-service"'
  Sleep 1000
!macroend
