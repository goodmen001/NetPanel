# 需求文档：NetPanel 文档网站

## 引言

NetPanel 是一个面向家庭和小型网络环境的内网穿透与网络管理面板，集成了端口转发、内网穿透、异地组网、动态域名、反向代理、WAF 防护等十余项网络管理功能。

本需求文档描述为 NetPanel 项目构建一个完整的**文档网站**，并通过 GitHub Actions 自动部署到 GitHub Pages，使用户可以通过公开链接访问项目文档。

文档网站需要覆盖项目介绍、安装指南、以及每个功能模块的详细使用说明，帮助用户快速上手并深入使用 NetPanel 的各项功能。

---

## 需求

### 需求 1：文档框架选型与基础结构搭建

**用户故事：** 作为一名开发者，我希望使用现代化的文档框架搭建文档站，以便获得良好的阅读体验、搜索功能和响应式设计。

#### 验收标准

1. WHEN 用户访问文档站 THEN 系统 SHALL 使用 VitePress 框架渲染文档，提供清晰的导航结构和响应式布局
2. WHEN 用户在移动端访问 THEN 系统 SHALL 自动适配移动端布局，保证可读性
3. WHEN 用户使用搜索功能 THEN 系统 SHALL 提供全文搜索能力（VitePress 内置搜索）
4. IF 文档站构建成功 THEN 系统 SHALL 生成纯静态文件，可直接托管于 GitHub Pages
5. WHEN 用户访问文档站 THEN 系统 SHALL 展示 NetPanel 的 Logo 和品牌色，与项目主题一致

---

### 需求 2：首页（项目介绍）

**用户故事：** 作为一名新用户，我希望在首页快速了解 NetPanel 是什么、能做什么，以便判断是否适合我的使用场景。

#### 验收标准

1. WHEN 用户访问文档站首页 THEN 系统 SHALL 展示项目名称、简短描述和核心价值主张
2. WHEN 用户浏览首页 THEN 系统 SHALL 展示项目的主要功能分类（网络穿透、域名管理、网站服务、辅助工具等）
3. WHEN 用户浏览首页 THEN 系统 SHALL 提供"快速开始"和"查看文档"两个主要 CTA 按钮
4. WHEN 用户浏览首页 THEN 系统 SHALL 展示支持的平台列表（Linux、Windows、macOS，x64/ARM64）
5. WHEN 用户浏览首页 THEN 系统 SHALL 展示技术栈信息（Go、React、SQLite 等）

---

### 需求 3：安装指南页面

**用户故事：** 作为一名用户，我希望获得清晰的安装步骤说明，以便在不同平台上快速部署 NetPanel。

#### 验收标准

1. WHEN 用户访问安装页面 THEN 系统 SHALL 提供"直接下载运行"的安装方式说明，包含各平台下载链接格式
2. WHEN 用户访问安装页面 THEN 系统 SHALL 提供 Linux 一键安装脚本的使用说明（`curl | bash` 方式）
3. WHEN 用户访问安装页面 THEN 系统 SHALL 提供 Windows 安装说明（解压运行 / PowerShell 脚本）
4. WHEN 用户访问安装页面 THEN 系统 SHALL 提供从源码构建的完整步骤（需要 Go 1.21+ 和 Node.js 20+）
5. WHEN 用户访问安装页面 THEN 系统 SHALL 提供 Docker 部署方式说明
6. WHEN 用户访问安装页面 THEN 系统 SHALL 说明常用启动参数（`-port`、`-data` 等）
7. IF 用户完成安装 THEN 系统 SHALL 说明默认访问地址为 `http://localhost:8080`

---

### 需求 4：功能模块文档 - 网络穿透与组网

**用户故事：** 作为一名需要内网穿透的用户，我希望了解端口转发、STUN、FRP、EasyTier 等功能的配置方法，以便实现远程访问和异地组网。

#### 验收标准

1. WHEN 用户访问端口转发文档 THEN 系统 SHALL 说明如何创建端口转发规则（监听 IP/端口、转发 IP/端口、协议选择）
2. WHEN 用户访问 STUN 穿透文档 THEN 系统 SHALL 说明 STUN 打洞的工作原理、配置项（UPnP、NATMAP、回调触发）
3. WHEN 用户访问 FRP 客户端文档 THEN 系统 SHALL 说明 FRP 代理类型（TCP/UDP/HTTP/HTTPS/STCP/XTCP）的配置方法
4. WHEN 用户访问 FRP 服务端文档 THEN 系统 SHALL 说明如何配置和运行 frps（监听端口、Token 等）
5. WHEN 用户访问 EasyTier 客户端文档 THEN 系统 SHALL 说明如何配置异地组网（服务器地址、网络名称、密码、虚拟 IP）
6. WHEN 用户访问 EasyTier 服务端文档 THEN 系统 SHALL 说明如何运行 EasyTier standalone 服务端
7. WHEN 用户访问 NPS 相关文档 THEN 系统 SHALL 说明 NPS 客户端和服务端的基本配置

---

### 需求 5：功能模块文档 - 域名与证书

**用户故事：** 作为一名需要管理域名和 SSL 证书的用户，我希望了解 DDNS、域名账号、域名解析、证书申请等功能的使用方法。

#### 验收标准

1. WHEN 用户访问 DDNS 文档 THEN 系统 SHALL 说明支持的服务商（阿里云、腾讯云、Cloudflare、DNSPod 等）及配置方法
2. WHEN 用户访问域名账号文档 THEN 系统 SHALL 说明如何添加和管理各服务商的 API 密钥
3. WHEN 用户访问域名解析文档 THEN 系统 SHALL 说明如何在面板中直接管理 DNS 解析记录（增删改查）
4. WHEN 用户访问域名证书文档 THEN 系统 SHALL 说明 ACME 证书申请流程（Let's Encrypt / ZeroSSL，DNS 验证方式）

---

### 需求 6：功能模块文档 - 网站与安全

**用户故事：** 作为一名需要搭建网站服务的用户，我希望了解 Caddy 反向代理、WAF 防护、访问控制等功能的配置方法。

#### 验收标准

1. WHEN 用户访问 Caddy 文档 THEN 系统 SHALL 说明如何配置反向代理、静态文件服务、重定向、URL 跳转和自动 HTTPS
2. WHEN 用户访问 WAF 文档 THEN 系统 SHALL 说明 Coraza WAF 的规则配置和 HTTP 流量过滤方法
3. WHEN 用户访问访问控制文档 THEN 系统 SHALL 说明 IP 黑白名单的配置方法
4. WHEN 用户访问防火墙文档 THEN 系统 SHALL 说明防火墙规则的管理方式

---

### 需求 7：功能模块文档 - 辅助功能

**用户故事：** 作为一名用户，我希望了解 WOL 唤醒、DNS 服务、计划任务、网络存储、IP 地址库等辅助功能的使用方法。

#### 验收标准

1. WHEN 用户访问 WOL 文档 THEN 系统 SHALL 说明如何发送 Magic Packet 远程唤醒局域网设备
2. WHEN 用户访问 DNSMasq 文档 THEN 系统 SHALL 说明如何配置自定义 DNS 解析规则和上游 DNS
3. WHEN 用户访问计划任务文档 THEN 系统 SHALL 说明 Cron 表达式的使用和任务类型（Shell 命令 / HTTP 请求）
4. WHEN 用户访问网络存储文档 THEN 系统 SHALL 说明 WebDAV、SFTP 访问的配置方法
5. WHEN 用户访问 IP 地址库文档 THEN 系统 SHALL 说明 IP 归属地查询和批量管理功能

---

### 需求 8：功能模块文档 - 回调系统

**用户故事：** 作为一名需要在 IP/端口变化时自动更新配置的用户，我希望了解回调任务和回调账号的配置方法。

#### 验收标准

1. WHEN 用户访问回调任务文档 THEN 系统 SHALL 说明回调触发条件（STUN IP/端口变化）和可执行的操作
2. WHEN 用户访问回调账号文档 THEN 系统 SHALL 说明支持的回调目标（Cloudflare 回源端口、阿里云 ESA、腾讯云 EO、WebHook）
3. WHEN 用户访问回调文档 THEN 系统 SHALL 提供完整的配置示例

---

### 需求 9：系统管理文档

**用户故事：** 作为一名管理员，我希望了解系统设置、用户管理、日志查看等管理功能的使用方法。

#### 验收标准

1. WHEN 用户访问系统设置文档 THEN 系统 SHALL 说明端口、数据目录等基础配置项
2. WHEN 用户访问用户管理文档 THEN 系统 SHALL 说明如何管理登录账号和权限
3. WHEN 用户访问日志文档 THEN 系统 SHALL 说明如何查看系统运行日志

---

### 需求 10：GitHub Pages 自动部署

**用户故事：** 作为一名开发者，我希望文档站能在代码推送后自动构建并部署到 GitHub Pages，以便文档始终保持最新状态。

#### 验收标准

1. WHEN 代码推送到 `main` 分支 THEN 系统 SHALL 自动触发 GitHub Actions 工作流构建文档站
2. WHEN 文档构建成功 THEN 系统 SHALL 自动将静态文件部署到 GitHub Pages
3. WHEN 部署完成 THEN 系统 SHALL 可通过 `https://{username}.github.io/{repo}/` 公开访问
4. IF 构建失败 THEN 系统 SHALL 在 GitHub Actions 中显示错误信息，不影响已部署的旧版本
5. WHEN 开发者手动触发工作流 THEN 系统 SHALL 支持 `workflow_dispatch` 手动触发部署
6. WHEN 文档站部署 THEN 系统 SHALL 正确配置 VitePress 的 `base` 路径以适配 GitHub Pages 子路径

---

### 需求 11：文档内容质量

**用户故事：** 作为一名文档读者，我希望文档内容准确、完整、易于理解，以便快速解决问题。

#### 验收标准

1. WHEN 用户阅读功能文档 THEN 系统 SHALL 为每个功能提供配置字段说明表格（字段名、类型、默认值、说明）
2. WHEN 用户阅读功能文档 THEN 系统 SHALL 提供至少一个完整的配置示例或截图说明
3. WHEN 用户阅读文档 THEN 系统 SHALL 在代码块中使用正确的语法高亮
4. WHEN 用户浏览文档 THEN 系统 SHALL 提供清晰的面包屑导航和章节目录（TOC）
5. IF 某功能尚在开发中 THEN 系统 SHALL 在文档中标注"开发中"状态提示
