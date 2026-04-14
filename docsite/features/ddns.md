# 动态域名 (DDNS)

动态域名（DDNS）功能可以在你的公网 IP 发生变化时，自动更新 DNS 解析记录，确保域名始终指向最新的 IP 地址。

## 技术原理

### DNS 解析工作原理

DNS（域名系统）是互联网的"电话簿"，负责将人类可读的域名转换为机器可识别的 IP 地址。

```
用户输入域名
    ↓
本地 DNS 缓存查询
    ↓ (未命中)
递归解析器查询
    ↓
根域名服务器 → 顶级域名服务器 → 权威 DNS 服务器
    ↓
返回 IP 地址（受 TTL 控制缓存时间）
```

**TTL（Time To Live）说明：**

| TTL 值 | 缓存时间 | 适用场景 |
|--------|----------|----------|
| `60` | 1 分钟 | IP 频繁变化，需快速生效 |
| `300` | 5 分钟 | DDNS 推荐值，平衡速度与负载 |
| `600` | 10 分钟 | 默认值，适合一般场景 |
| `3600` | 1 小时 | IP 稳定，减少 DNS 查询压力 |

::: tip TTL 与 DDNS 的关系
TTL 越小，IP 变化后生效越快，但 DNS 服务器查询压力越大。DDNS 场景建议设置 TTL 为 `300`（5 分钟）。
:::

### 动态 DNS 工作原理

家庭宽带通常分配动态公网 IP，每次重拨或断线重连后 IP 可能改变。DDNS 通过以下流程解决这个问题：

```
定时检测公网 IP
    ↓
与上次记录的 IP 对比
    ↓ (IP 已变化)
调用 DNS 服务商 API
    ↓
更新域名的 A/AAAA 记录
    ↓
记录新 IP，等待下次检测
```

---

## 功能概述

- 支持多家主流 DNS 服务商
- 支持 IPv4 和 IPv6 地址更新
- 支持多种 IP 获取方式（公网接口、本地网卡、自定义 URL）
- 定时检测 IP 变化，自动更新
- 支持更新成功/失败通知

## 支持的服务商

| 服务商 | 说明 |
|--------|------|
| 阿里云 DNS | 需要 AccessKey ID 和 AccessKey Secret |
| 腾讯云 DNSPod | 需要 SecretId 和 SecretKey |
| Cloudflare | 需要 API Token 或 Global API Key |
| DNSPod（独立版） | 需要 Token ID 和 Token |
| 华为云 DNS | 需要 AccessKey ID 和 AccessKey Secret |
| GoDaddy | 需要 API Key 和 Secret |
| Namecheap | 需要用户名和 API Key |
| 自定义 WebHook | 通过 HTTP 请求更新任意 DNS 服务 |

---

## 配置说明

进入 **动态域名** 页面，点击 **新建** 按钮：

### 基础配置

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 名称 | 字符串 | ✅ | — | 规则名称 |
| 启用 | 布尔 | ✅ | `true` | 是否启用 |
| 服务商 | 枚举 | ✅ | — | DNS 服务商，见上方列表 |
| 域名账号 | 选择 | ✅ | — | 选择已配置的 [域名账号](/features/domain-account) |

### 域名配置

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 域名 | 字符串 | ✅ | — | 要更新的完整域名，如 `home.example.com` |
| 记录类型 | 枚举 | ✅ | `A` | `A`（IPv4）或 `AAAA`（IPv6） |
| TTL | 整数 | ❌ | `600` | DNS 记录 TTL（秒） |

### IP 获取方式

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| IP 来源 | 枚举 | ✅ | `公网接口` | 获取 IP 的方式 |
| 自定义 URL | 字符串 | ❌ | — | IP 来源为"自定义 URL"时填写 |
| 网卡名称 | 字符串 | ❌ | — | IP 来源为"本地网卡"时填写 |

**IP 来源选项：**
- **公网接口**：通过公共 API（如 `api.ipify.org`）获取公网 IP
- **本地网卡**：读取指定网卡的 IP 地址
- **自定义 URL**：请求指定 URL，从响应中提取 IP

### 更新频率

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 检测间隔 | 整数 | ❌ | `300` | IP 检测间隔（秒），最小 60 |

---

## 配置示例

### 示例 1：阿里云 DDNS

将 `home.example.com` 的 A 记录自动更新为当前公网 IP：

**第一步：配置域名账号**

前往 [域名账号](/features/domain-account) 页面，添加阿里云账号：
1. 登录 [阿里云 RAM 控制台](https://ram.console.aliyun.com/users)
2. 创建子用户，授予 `AliyunDNSFullAccess` 权限
3. 创建 AccessKey，填入域名账号

**第二步：创建 DDNS 规则**

| 字段 | 值 |
|------|-----|
| 名称 | 家庭宽带 DDNS |
| 服务商 | 阿里云 DNS |
| 域名账号 | 选择已配置的阿里云账号 |
| 域名 | `home.example.com` |
| 记录类型 | `A` |
| IP 来源 | 公网接口 |
| 检测间隔 | `300`（5 分钟） |

### 示例 2：Cloudflare DDNS（IPv6）

更新 IPv6 地址到 Cloudflare：

**第一步：获取 Cloudflare API Token**
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 **Create Token** → 选择 **Edit zone DNS** 模板
3. 选择对应域名区域，创建 Token

**第二步：创建 DDNS 规则**

| 字段 | 值 |
|------|-----|
| 名称 | IPv6 DDNS |
| 服务商 | Cloudflare |
| 域名账号 | 选择已配置的 Cloudflare 账号 |
| 域名 | `ipv6.example.com` |
| 记录类型 | `AAAA` |
| IP 来源 | 本地网卡 |
| 网卡名称 | `eth0` |

### 示例 3：腾讯云 DNSPod DDNS

**第一步：获取腾讯云 API 密钥**
1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/cam/capi)
2. 创建 API 密钥，获取 SecretId 和 SecretKey

**第二步：创建 DDNS 规则**

| 字段 | 值 |
|------|-----|
| 名称 | 腾讯云 DDNS |
| 服务商 | 腾讯云 DNSPod |
| 域名 | `home.example.com` |
| 记录类型 | `A` |
| TTL | `300` |

---

## 查看更新状态

在 DDNS 规则列表中，每条规则会显示：
- **当前 IP**：最近一次更新的 IP 地址
- **最后更新时间**：上次成功更新的时间
- **状态**：运行中 / 更新失败 / 已停止

---

## 常见问题

### Q：DDNS 更新成功，但域名解析还是旧 IP？

**原因：** DNS 缓存未过期，需等待 TTL 时间后生效。

**解决方案：**
1. 等待 TTL 时间（默认 600 秒）后重试
2. 将 TTL 调小（如 `60`）以加快生效速度
3. 使用 `nslookup home.example.com 8.8.8.8` 绕过本地缓存查询

### Q：DDNS 更新失败，提示 API 错误？

**排查步骤：**
1. 检查域名账号的 API 密钥是否正确
2. 确认 API 密钥有 DNS 编辑权限
3. 检查域名是否在该账号下管理
4. 查看系统日志获取详细错误信息

### Q：如何获取真实公网 IP（运营商 NAT 场景）？

部分运营商使用 NAT，设备获取的 IP 并非真实公网 IP。

**解决方案：**
- 将 IP 来源设置为 **公网接口**，通过外部服务获取真实公网 IP
- 或使用自定义 URL：`https://api.ipify.org`

### Q：IPv6 DDNS 如何配置？

1. 确认设备已获取 IPv6 地址（`ip -6 addr show`）
2. 将记录类型设置为 `AAAA`
3. IP 来源选择 **本地网卡**，填写网卡名称（如 `eth0`）

---

## 最佳实践

::: tip 与回调系统配合实现即时更新
如果你使用 STUN 穿透，建议配合 [回调系统](/features/callback) 使用，在 IP 变化时立即触发 DDNS 更新，而不是等待定时检测。
:::

::: tip 域名账号
使用 DDNS 前，需要先在 [域名账号](/features/domain-account) 页面配置对应服务商的 API 密钥。
:::

::: warning 最小权限原则
为 DDNS 创建专用的 API Token，只授予 DNS 编辑权限，不要使用主账号密钥，降低密钥泄露风险。
:::
