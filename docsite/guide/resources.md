# 官方资源与下载

本页汇总了 NetPanel 及其集成的所有第三方工具的官方文档链接、二进制下载地址和版本兼容性信息。

---

## NetPanel

NetPanel 是本面板的核心程序，面向家庭和小型网络环境的内网穿透与网络管理面板。

| 资源 | 链接 |
|------|------|
| 官方文档 | [netpanel.opkg.cn](https://netpanel.opkg.cn) |
| GitHub 仓库 | [github.com/PIKACHUIM/NetPanel](https://github.com/PIKACHUIM/NetPanel) |
| 二进制下载 | [Releases 页面](https://github.com/PIKACHUIM/NetPanel/releases) |
| 版本更新日志 | [Changelog](https://github.com/PIKACHUIM/NetPanel/releases) |

### 支持平台

| 平台 | 架构 | 说明 |
|------|------|------|
| Linux | amd64 / arm64 / arm / mips | 主流发行版均支持 |
| Windows | amd64 | Windows 10/11 及 Server |
| macOS | amd64 / arm64 (Apple Silicon) | macOS 11+ |
| OpenWrt | mips / mipsle / arm | 路由器固件 |

::: tip 推荐安装方式
建议使用 Docker 部署以获得最佳的隔离性和可移植性，详见 [安装部署](/guide/installation)。
:::

---

## FRP（Fast Reverse Proxy）

FRP 是一款高性能的反向代理工具，支持 TCP、UDP、HTTP、HTTPS 等多种协议的内网穿透。

| 资源 | 链接 |
|------|------|
| 官方文档（中文） | [gofrp.org/zh-cn/docs](https://gofrp.org/zh-cn/docs) |
| 官方文档（英文） | [gofrp.org/docs](https://gofrp.org/docs) |
| GitHub 仓库 | [github.com/fatedier/frp](https://github.com/fatedier/frp) |
| 二进制下载 | [Releases 页面](https://github.com/fatedier/frp/releases) |

### 版本兼容性

| NetPanel 版本 | 兼容 FRP 版本 | 说明 |
|--------------|--------------|------|
| 最新版 | v0.51.0 及以上 | 推荐使用最新稳定版 |

### 支持平台

| 平台 | 文件名示例 |
|------|-----------|
| Linux amd64 | `frp_x.x.x_linux_amd64.tar.gz` |
| Linux arm64 | `frp_x.x.x_linux_arm64.tar.gz` |
| Windows amd64 | `frp_x.x.x_windows_amd64.zip` |
| macOS amd64 | `frp_x.x.x_darwin_amd64.tar.gz` |

::: info NetPanel 内置 FRP
NetPanel 发布包中已内置对应平台的 FRP 二进制文件，通常无需单独下载。仅在需要使用特定版本时才需手动替换。
:::

---

## EasyTier

EasyTier 是一款基于 Rust 编写的去中心化虚拟局域网工具，支持多种传输协议和 P2P 直连。

| 资源 | 链接 |
|------|------|
| 官方文档 | [easytier.cn/guide/introduction.html](https://easytier.cn/guide/introduction.html) |
| 官方网站 | [easytier.cn](https://easytier.cn) |
| GitHub 仓库 | [github.com/EasyTier/EasyTier](https://github.com/EasyTier/EasyTier) |
| 二进制下载 | [Releases 页面](https://github.com/EasyTier/EasyTier/releases) |

### 版本兼容性

| NetPanel 版本 | 兼容 EasyTier 版本 | 说明 |
|--------------|-------------------|------|
| 最新版 | v1.x.x 及以上 | 推荐使用最新稳定版 |

### 支持平台

| 平台 | 文件名示例 |
|------|-----------|
| Linux amd64 | `easytier-linux-x86_64.zip` |
| Linux arm64 | `easytier-linux-aarch64.zip` |
| Windows amd64 | `easytier-windows-x86_64.zip` |
| macOS amd64 | `easytier-macos-x86_64.zip` |
| Android | `easytier-android.apk` |

::: info NetPanel 内置 EasyTier
NetPanel 发布包中已内置对应平台的 EasyTier 二进制文件，无需单独下载。
:::

---

## NPS（NAT Proxy Server）

NPS 是一款轻量级、高性能、功能强大的内网穿透代理服务器，支持 Web 管理界面。

| 资源 | 链接 |
|------|------|
| GitHub 仓库 | [github.com/ehang-io/nps](https://github.com/ehang-io/nps) |
| 二进制下载 | [Releases 页面](https://github.com/ehang-io/nps/releases) |
| 使用文档 | [GitHub Wiki](https://github.com/ehang-io/nps/blob/master/README.md) |

### 版本兼容性

| NetPanel 版本 | 兼容 NPS 版本 | 说明 |
|--------------|--------------|------|
| 最新版 | v0.26.x 及以上 | 推荐使用最新稳定版 |

### 支持平台

| 平台 | 文件名示例 |
|------|-----------|
| Linux amd64 | `linux_amd64_client.tar.gz` |
| Linux arm | `linux_arm_client.tar.gz` |
| Windows amd64 | `windows_amd64_client.tar.gz` |

::: info NetPanel 内置 NPS 客户端
NetPanel 发布包中已内置对应平台的 NPS 客户端（npc）二进制文件，无需单独下载。
:::

---

## Caddy

Caddy 是一款现代化的 Web 服务器，支持自动 HTTPS、反向代理、静态文件服务等功能。

| 资源 | 链接 |
|------|------|
| 官方文档 | [caddyserver.com/docs](https://caddyserver.com/docs) |
| 官方网站 | [caddyserver.com](https://caddyserver.com) |
| GitHub 仓库 | [github.com/caddyserver/caddy](https://github.com/caddyserver/caddy) |
| 二进制下载 | [Releases 页面](https://github.com/caddyserver/caddy/releases) |
| 下载页面 | [caddyserver.com/download](https://caddyserver.com/download) |

### 版本兼容性

| NetPanel 版本 | 兼容 Caddy 版本 | 说明 |
|--------------|----------------|------|
| 最新版 | v2.x.x 及以上 | 推荐使用 Caddy v2 最新稳定版 |

### 支持平台

| 平台 | 文件名示例 |
|------|-----------|
| Linux amd64 | `caddy_x.x.x_linux_amd64.tar.gz` |
| Linux arm64 | `caddy_x.x.x_linux_arm64.tar.gz` |
| Windows amd64 | `caddy_x.x.x_windows_amd64.zip` |
| macOS amd64 | `caddy_x.x.x_mac_amd64.tar.gz` |

::: info NetPanel 内置 Caddy
NetPanel 发布包中已内置对应平台的 Caddy 二进制文件，无需单独下载。
:::

---

## 相关工具与依赖

### IP 地理位置数据库（GeoIP）

NetPanel 的 IP 地址库功能依赖 MaxMind GeoLite2 数据库：

| 资源 | 链接 |
|------|------|
| MaxMind 官网 | [maxmind.com](https://www.maxmind.com) |
| GeoLite2 免费下载 | [dev.maxmind.com/geoip/geolite2-free-geolocation-data](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data) |
| 国内镜像（GitHub） | [github.com/P3TERX/GeoLite.mmdb](https://github.com/P3TERX/GeoLite.mmdb) |

### DNSMasq

| 资源 | 链接 |
|------|------|
| 官方网站 | [thekelleys.org.uk/dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) |
| 文档手册 | [man page](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html) |

---

## 版本更新说明

::: warning 版本兼容性注意事项
- 各第三方工具的大版本升级可能存在不兼容的配置格式变更
- 建议在升级前备份现有配置，并参阅对应工具的 Changelog
- NetPanel 会在发布说明中注明所集成工具的版本信息
:::

::: tip 获取最新版本
建议关注 [NetPanel GitHub Releases](https://github.com/PIKACHUIM/NetPanel/releases) 页面，及时获取最新版本和更新说明。
:::
