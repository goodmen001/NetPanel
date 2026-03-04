//go:build windows

package main

// 使用 rsrc 工具将 Windows manifest 编译为 .syso 资源文件。
// .syso 文件会被 Go 编译器自动链接进最终的 .exe，
// 使 Windows 在启动程序时自动弹出 UAC 提权对话框（requireAdministrator）。
//
// 文件命名规则：netpanel_windows_<GOARCH>.syso
// Go 编译器会根据 GOARCH 自动选择对应架构的 .syso 文件，
// 避免交叉编译时出现 "unknown ARM64 relocation type" 错误。
//
// 首次使用前需安装 rsrc 工具：
//
//	go install github.com/akavel/rsrc@latest
//
// 然后在 backend/ 目录下执行：
//
//	go generate ./...
//
//go:generate rsrc -manifest netpanel.manifest -o netpanel_windows_amd64.syso -arch amd64
//go:generate rsrc -manifest netpanel.manifest -o netpanel_windows_arm64.syso -arch arm64
//go:generate rsrc -manifest netpanel.manifest -o netpanel_windows_386.syso -arch 386
