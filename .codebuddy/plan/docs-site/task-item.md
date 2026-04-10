# 实施计划：NetPanel 文档网站

- [ ] 1. 初始化 VitePress 文档站项目结构
   - 在项目根目录创建 `docs-site/` 目录
   - 初始化 `package.json`，安装 VitePress 依赖
   - 创建 `docs-site/.vitepress/config.ts`，配置站点标题、描述、导航栏、侧边栏、内置搜索和 `base` 路径（适配 GitHub Pages）
   - 创建 `docs-site/public/` 目录，放置 Logo 等静态资源
   - _需求：1.1、1.4、1.5、10.6_

- [ ] 2. 编写首页（项目介绍）
   - 创建 `docs-site/index.md`，使用 VitePress Hero 布局
   - 包含项目名称、核心价值描述、"快速开始"和"查看文档"CTA 按钮
   - 添加功能分类特性卡片（网络穿透、域名管理、网站服务、辅助工具）
   - 展示支持平台（Linux/Windows/macOS，x64/ARM64）和技术栈（Go、React、SQLite）
   - _需求：2.1、2.2、2.3、2.4、2.5_

- [ ] 3. 编写安装指南文档
   - 创建 `docs-site/guide/installation.md`
   - 分节说明：直接下载运行（各平台链接格式）、Linux 一键脚本（`curl | bash`）、Windows 安装（解压/PowerShell）、源码构建（Go 1.21+ / Node.js 20+）、Docker 部署
   - 说明常用启动参数（`-port`、`-data`）和默认访问地址 `http://localhost:8080`
   - _需求：3.1、3.2、3.3、3.4、3.5、3.6、3.7_

- [ ] 4. 编写网络穿透与组网功能文档
   - 创建以下文档文件：
     - `docs-site/features/port-forward.md`（端口转发：监听/转发 IP 端口、协议选择）
     - `docs-site/features/stun.md`（STUN 打洞：工作原理、UPnP/NATMAP/回调触发配置）
     - `docs-site/features/frp-client.md`（FRP 客户端：TCP/UDP/HTTP/HTTPS/STCP/XTCP 代理类型）
     - `docs-site/features/frp-server.md`（FRP 服务端：监听端口、Token 配置）
     - `docs-site/features/easytier-client.md`（EasyTier 客户端：服务器地址、网络名称、密码、虚拟 IP）
     - `docs-site/features/easytier-server.md`（EasyTier 服务端：standalone 模式运行）
     - `docs-site/features/nps.md`（NPS 客户端与服务端基本配置）
   - 每个文档包含配置字段说明表格和完整配置示例
   - _需求：4.1–4.7、11.1、11.2、11.3_

- [ ] 5. 编写域名与证书功能文档
   - 创建以下文档文件：
     - `docs-site/features/ddns.md`（DDNS：支持服务商列表、配置方法）
     - `docs-site/features/domain-account.md`（域名账号：添加/管理各服务商 API 密钥）
     - `docs-site/features/dns-records.md`（域名解析：DNS 记录增删改查）
     - `docs-site/features/ssl-cert.md`（域名证书：ACME 申请流程、Let's Encrypt/ZeroSSL、DNS 验证）
   - 每个文档包含配置字段说明表格和完整配置示例
   - _需求：5.1、5.2、5.3、5.4、11.1、11.2_

- [ ] 6. 编写网站与安全功能文档
   - 创建以下文档文件：
     - `docs-site/features/caddy.md`（Caddy：反向代理、静态文件、重定向、URL 跳转、自动 HTTPS）
     - `docs-site/features/waf.md`（WAF：Coraza 规则配置、HTTP 流量过滤）
     - `docs-site/features/access-control.md`（访问控制：IP 黑白名单配置）
     - `docs-site/features/firewall.md`（防火墙：规则管理）
   - 每个文档包含配置字段说明表格和完整配置示例
   - _需求：6.1、6.2、6.3、6.4、11.1、11.2_

- [ ] 7. 编写辅助功能与回调系统文档
   - 创建以下文档文件：
     - `docs-site/features/wol.md`（WOL：Magic Packet 远程唤醒）
     - `docs-site/features/dnsmasq.md`（DNSMasq：自定义 DNS 规则、上游 DNS）
     - `docs-site/features/cron.md`（计划任务：Cron 表达式、Shell 命令/HTTP 请求类型）
     - `docs-site/features/storage.md`（网络存储：WebDAV、SFTP 配置）
     - `docs-site/features/ip-database.md`（IP 地址库：归属地查询、批量管理）
     - `docs-site/features/callback.md`（回调系统：触发条件、回调账号类型 CF/阿里云/腾讯云/WebHook、完整配置示例）
   - _需求：7.1–7.5、8.1、8.2、8.3、11.1、11.2_

- [ ] 8. 编写系统管理文档并完善导航配置
   - 创建 `docs-site/guide/system.md`（系统设置：端口、数据目录等配置项）
   - 创建 `docs-site/guide/users.md`（用户管理：账号与权限）
   - 创建 `docs-site/guide/logs.md`（日志：查看系统运行日志）
   - 更新 `docs-site/.vitepress/config.ts` 中的侧边栏，将所有文档页面纳入导航结构，确保面包屑和 TOC 正常工作
   - _需求：9.1、9.2、9.3、11.4_

- [ ] 9. 配置 GitHub Actions 自动部署到 GitHub Pages
   - 创建 `.github/workflows/docs.yml` 工作流文件
   - 配置触发条件：`push` 到 `main` 分支 + `workflow_dispatch` 手动触发
   - 工作流步骤：checkout → setup Node.js → install deps → vitepress build → deploy to GitHub Pages（使用 `actions/deploy-pages`）
   - 配置 `permissions: pages: write` 和 `id-token: write`
   - _需求：10.1、10.2、10.3、10.4、10.5、10.6_
