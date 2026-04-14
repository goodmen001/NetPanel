# 网站服务 (Caddy)

网站服务功能基于 Caddy 实现，提供反向代理、静态文件服务、重定向、URL 跳转等功能，并支持自动 HTTPS。

## 技术原理

### 反向代理工作原理

反向代理是一种服务器架构模式，客户端的请求先到达代理服务器，再由代理服务器转发到后端真实服务：

```
客户端浏览器
     │
     │ HTTPS 请求 (443)
     ▼
┌─────────────┐
│  Caddy 代理  │  ← 处理 SSL/TLS、负载均衡、请求头改写
└─────────────┘
     │
     │ HTTP 请求 (内网)
     ▼
┌─────────────┐
│  后端服务    │  ← Node.js / Python / Go 等应用
└─────────────┘
```

**反向代理的优势：**
- 统一入口：所有服务通过同一域名/端口对外暴露
- SSL 卸载：由 Caddy 统一处理 HTTPS，后端服务无需关心证书
- 安全隔离：后端服务不直接暴露到公网
- 负载均衡：将流量分发到多个后端实例

### SSL/TLS 握手过程

当客户端访问 HTTPS 站点时，会经历以下握手流程：

```
客户端                          Caddy 服务器
  │                                  │
  │──── ClientHello (支持的加密套件) ──→│
  │                                  │
  │←─── ServerHello + 证书 ──────────│
  │                                  │
  │──── 验证证书 + 生成会话密钥 ──────→│
  │                                  │
  │←──────── 握手完成 ───────────────│
  │                                  │
  │══════ 加密数据传输 ══════════════│
```

### Caddy 自动 HTTPS 原理

Caddy 通过 ACME 协议（Let's Encrypt）自动申请和续期证书：

1. **HTTP-01 验证**：Caddy 在 `/.well-known/acme-challenge/` 路径放置验证文件，Let's Encrypt 通过 HTTP 访问验证域名所有权
2. **自动续期**：证书到期前 30 天自动触发续期，无需人工干预
3. **证书存储**：证书存储在数据目录中，重启后自动加载

::: tip Caddy 是什么？
Caddy 是一款用 Go 编写的现代 Web 服务器，以自动 HTTPS 和简洁配置著称。NetPanel 内置了 Caddy，无需单独安装。
:::

---

## 功能概述

- **反向代理**：将请求转发到后端服务
- **静态文件服务**：托管静态网站或文件目录
- **重定向**：HTTP 跳转到 HTTPS，或域名跳转
- **URL 跳转**：将特定路径跳转到其他 URL
- **自动 HTTPS**：自动申请和续期 SSL 证书

---

## 完整配置步骤

### 步骤一：反向代理配置流程

以将 `app.example.com` 反向代理到内网服务为例：

**1. 域名解析**

首先将域名解析到服务器公网 IP：

| 记录类型 | 主机记录 | 记录值 |
|---------|---------|--------|
| A | `app` | `1.2.3.4`（服务器公网 IP） |

**2. 开放防火墙端口**

确保服务器防火墙放行 80 和 443 端口：

```bash
# Ubuntu/Debian (ufw)
ufw allow 80/tcp
ufw allow 443/tcp

# CentOS/RHEL (firewalld)
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

**3. 在 NetPanel 中创建站点**

进入 **网站服务** 页面，点击 **新建**，选择 **反向代理** 类型：

| 字段 | 值 | 说明 |
|------|-----|------|
| 名称 | `我的应用` | 便于识别的名称 |
| 监听地址 | `app.example.com` | 已解析到本机的域名 |
| 上游地址 | `http://127.0.0.1:3000` | 后端服务地址 |
| 启用 HTTPS | ✅ | 自动申请 Let's Encrypt 证书 |
| 强制 HTTPS | ✅ | HTTP 自动跳转到 HTTPS |

**4. 验证访问**

等待约 30 秒证书申请完成后，访问 `https://app.example.com` 验证是否正常。

---

### 步骤二：静态网站部署流程

**1. 上传文件**

将静态网站文件上传到服务器目录，例如 `/var/www/mysite/`：

```bash
# 使用 scp 上传
scp -r ./dist/ user@server:/var/www/mysite/

# 或使用 rsync
rsync -avz ./dist/ user@server:/var/www/mysite/
```

**2. 创建静态文件站点**

| 字段 | 值 |
|------|-----|
| 名称 | `静态网站` |
| 监听地址 | `static.example.com` |
| 根目录 | `/var/www/mysite` |
| 索引文件 | `index.html` |
| 启用目录浏览 | ❌（生产环境建议关闭） |

---

## 站点类型

### 反向代理

将域名/端口的请求转发到内网服务。

**配置字段：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 站点名称 |
| 启用 | 布尔 | ✅ | 是否启用 |
| 监听地址 | 字符串 | ✅ | 监听的域名或 `IP:端口`，如 `app.example.com` |
| 上游地址 | 字符串 | ✅ | 后端服务地址，如 `http://127.0.0.1:3000` |
| SSL 证书 | 选择 | ❌ | 选择已申请的证书，或留空使用自动 HTTPS |
| 启用 HTTPS | 布尔 | ❌ | 是否启用 HTTPS |
| 强制 HTTPS | 布尔 | ❌ | 是否将 HTTP 请求重定向到 HTTPS |

**配置示例：**

将 `app.example.com` 反向代理到内网 Node.js 服务：

| 字段 | 值 |
|------|-----|
| 名称 | 我的应用 |
| 监听地址 | `app.example.com` |
| 上游地址 | `http://127.0.0.1:3000` |
| 启用 HTTPS | ✅ |
| 强制 HTTPS | ✅ |

---

### 静态文件服务

托管静态网站或文件目录，支持目录浏览。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 站点名称 |
| 监听地址 | 字符串 | ✅ | 监听的域名或端口 |
| 根目录 | 字符串 | ✅ | 静态文件所在目录路径 |
| 启用目录浏览 | 布尔 | ❌ | 是否允许浏览目录文件列表 |
| 索引文件 | 字符串 | ❌ | 默认索引文件，如 `index.html` |

**配置示例：**

托管 `/var/www/html` 目录下的静态网站：

| 字段 | 值 |
|------|-----|
| 名称 | 静态网站 |
| 监听地址 | `static.example.com` |
| 根目录 | `/var/www/html` |
| 索引文件 | `index.html` |

---

### 重定向

将一个域名或 URL 重定向到另一个地址。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 规则名称 |
| 来源地址 | 字符串 | ✅ | 重定向来源，如 `http://example.com` |
| 目标地址 | 字符串 | ✅ | 重定向目标，如 `https://www.example.com` |
| 重定向码 | 枚举 | ❌ | `301`（永久）或 `302`（临时） |

**配置示例：**

将 HTTP 重定向到 HTTPS：

| 字段 | 值 |
|------|-----|
| 来源地址 | `http://example.com` |
| 目标地址 | `https://example.com{uri}` |
| 重定向码 | `301` |

---

### URL 跳转

将特定路径跳转到其他 URL，常用于短链接或路径映射。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 规则名称 |
| 监听地址 | 字符串 | ✅ | 监听的域名或端口 |
| 路径 | 字符串 | ✅ | 匹配的请求路径，如 `/github` |
| 跳转目标 | 字符串 | ✅ | 跳转目标 URL |

---

## 高级配置

### 自定义请求头

可以在反向代理时添加或修改请求头：

| 字段 | 说明 |
|------|------|
| 添加请求头 | 向上游请求添加 Header |
| 删除请求头 | 从上游请求删除 Header |
| 添加响应头 | 向客户端响应添加 Header |

**常用请求头配置示例：**

```
# 传递真实客户端 IP
X-Real-IP: {remote_host}
X-Forwarded-For: {remote_host}
X-Forwarded-Proto: {scheme}

# 安全响应头
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
```

### 负载均衡

反向代理支持配置多个上游地址，实现简单的负载均衡：

```
上游地址：
http://127.0.0.1:3000
http://127.0.0.1:3001
http://127.0.0.1:3002
```

Caddy 默认使用轮询（Round Robin）策略，将请求依次分发到各上游服务。

### WebSocket 代理

代理 WebSocket 服务时，Caddy 会自动处理协议升级，无需额外配置。只需将上游地址指向 WebSocket 服务即可：

| 字段 | 值 |
|------|-----|
| 监听地址 | `ws.example.com` |
| 上游地址 | `http://127.0.0.1:8080` |

### 大文件上传

默认情况下 Caddy 对请求体大小没有限制，但如果后端服务有限制，需要在后端服务中调整。如果使用 Nginx 等其他代理在 Caddy 前面，需要在 Nginx 中设置 `client_max_body_size`。

### 80/443 端口被占用时的替代方案

如果服务器的 80 或 443 端口已被其他程序占用，有以下两种解决方案：

**方案一：使用其他端口**

在监听地址中指定非标准端口：

| 监听地址 | 说明 |
|---------|------|
| `example.com:8080` | HTTP 使用 8080 端口 |
| `example.com:8443` | HTTPS 使用 8443 端口 |

用户访问时需要在 URL 中加上端口号，如 `https://example.com:8443`。

**方案二：配合 FRP 使用**

在有公网 IP 的服务器上运行 FRP 服务端，将 80/443 端口通过 FRP 转发到本机 Caddy：

```
公网服务器 (FRP 服务端)
  80/443 端口 → 转发到内网机器的 Caddy
                    ↓
              内网机器 (Caddy + FRP 客户端)
```

详见 [FRP 客户端](/features/frp-client) 文档。

---

## 证书管理

### 自动证书 vs 手动证书

| 对比项 | 自动证书（Let's Encrypt） | 手动证书 |
|--------|--------------------------|---------|
| 申请方式 | Caddy 自动申请 | 通过[域名证书](/features/ssl-cert)手动申请 |
| 适用场景 | 域名可从公网访问 | 内网域名、泛域名、离线环境 |
| 续期方式 | 自动续期 | 需手动或通过计划任务续期 |
| 端口要求 | 需要 80 端口可访问 | 无要求 |
| 证书类型 | 单域名 DV 证书 | 支持泛域名、OV、EV 证书 |

### 使用手动证书

如果已通过 [域名证书](/features/ssl-cert) 功能申请了证书，在站点配置中选择对应证书即可：

1. 进入 **域名证书** 页面申请证书
2. 在站点配置的 **SSL 证书** 字段中选择已申请的证书
3. 启用 HTTPS 并保存

---

## 注意事项

::: tip 自动 HTTPS
如果监听地址是域名（而非 IP:端口），Caddy 会自动尝试申请 Let's Encrypt 证书。需要确保：
1. 域名已正确解析到服务器 IP
2. 服务器 80 和 443 端口可以从外网访问
:::

::: warning 端口冲突
如果已有其他程序占用 80 或 443 端口，Caddy 将无法启动。可以在监听地址中指定其他端口，如 `example.com:8443`。
:::

::: info 与域名证书配合
如果使用 [域名证书](/features/ssl-cert) 功能手动申请了证书，可以在站点配置中选择该证书，而不使用 Caddy 的自动 HTTPS。
:::

---

## 常见问题

### Q：证书申请失败，提示 "no A/AAAA records found"

**原因：** 域名未解析到服务器 IP，或 DNS 解析尚未生效。

**解决：**
1. 检查域名 DNS 解析是否正确：`nslookup app.example.com`
2. DNS 解析生效通常需要 5 分钟到 24 小时，请耐心等待
3. 确认解析的 IP 是当前服务器的公网 IP

### Q：证书申请失败，提示 "connection refused" 或 "timeout"

**原因：** Let's Encrypt 无法通过 HTTP（80 端口）访问服务器进行验证。

**解决：**
1. 检查服务器防火墙是否放行 80 端口
2. 检查云服务器安全组是否放行 80 端口
3. 确认没有其他程序占用 80 端口：`netstat -tlnp | grep :80`

### Q：反向代理后，后端获取到的 IP 是 127.0.0.1

**原因：** 后端服务读取的是直接连接 IP，而非客户端真实 IP。

**解决：** 在站点配置中添加请求头，将真实 IP 传递给后端：

```
X-Real-IP: {remote_host}
X-Forwarded-For: {remote_host}
```

后端服务读取 `X-Real-IP` 或 `X-Forwarded-For` 请求头获取真实 IP。

### Q：WebSocket 连接断开

**原因：** 代理服务器默认超时时间较短，长连接会被断开。

**解决：** Caddy 对 WebSocket 有良好支持，通常无需额外配置。如果仍有问题，检查后端服务是否正确处理了 WebSocket 升级请求。

### Q：访问提示 "502 Bad Gateway"

**原因：** Caddy 无法连接到上游服务。

**解决：**
1. 确认后端服务正在运行：`curl http://127.0.0.1:3000`
2. 检查上游地址配置是否正确（IP、端口）
3. 查看 NetPanel 系统日志中的错误信息

---

## 官方资源

| 资源 | 链接 |
|------|------|
| 📖 Caddy 官方文档 | [https://caddyserver.com/docs](https://caddyserver.com/docs) |
| 💾 Caddy GitHub 下载 | [https://github.com/caddyserver/caddy/releases](https://github.com/caddyserver/caddy/releases) |
| 🌐 Caddy 官网 | [https://caddyserver.com](https://caddyserver.com) |
| 💬 Caddy 社区论坛 | [https://caddy.community](https://caddy.community) |

::: info NetPanel 内置 Caddy
NetPanel 发布包中已内置对应平台的 Caddy 二进制文件，无需单独下载安装。上方链接供需要了解 Caddy 高级功能的用户参考。
:::
