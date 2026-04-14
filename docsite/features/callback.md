# 回调系统

回调系统用于在 STUN 穿透的外网 IP 或端口发生变化时，自动触发预设的操作，如更新 CDN 回源配置、更新 DNS 解析、发送通知等。

## 技术原理

### Webhook 回调工作原理

Webhook 是一种**事件驱动**的通信机制：当系统内部发生特定事件时，主动向预配置的 URL 发送 HTTP 请求，将事件数据推送给外部系统。

```
内部事件触发（IP/端口变化）
         │
         ▼
   事件检测模块
   (定期探测 STUN 映射)
         │
    发生变化？
    ┌────┴────┐
   是         否
    │          │
    ▼          ▼
查找关联     继续等待
回调任务
    │
    ▼
并行执行所有回调
┌───────────────────────────────┐
│  Cloudflare API 更新回源端口   │
│  阿里云 ESA 更新回源配置       │
│  腾讯云 EO 更新回源配置        │
│  WebHook 发送 HTTP 通知        │
│  DDNS 更新域名解析             │
└───────────────────────────────┘
         │
         ▼
   记录执行结果
```

### 触发条件说明

| 触发条件 | 说明 | 典型用途 |
|----------|------|----------|
| STUN IP 变化 | 公网 IP 地址发生变更 | 更新 DNS A 记录、通知管理员 |
| STUN 端口变化 | NAT 映射端口发生变更 | 更新 CDN 回源端口规则 |
| IP 或端口任一变化 | IP 或端口任意一个变更即触发 | 全量更新配置 |

---

## 功能概述

- 监听 STUN 穿透的 IP/端口变化事件
- 自动触发配置的回调操作
- 支持多种回调目标（Cloudflare、阿里云 ESA、腾讯云 EO、WebHook）
- 支持多个回调任务并行触发
- 记录每次回调的执行结果和响应内容

---

## 回调账号

回调账号用于存储各平台的 API 凭证，供回调任务使用。

### 支持的回调账号类型

| 类型 | 说明 | 用途 |
|------|------|------|
| Cloudflare 回源规则 | Cloudflare API Token | 更新 Cloudflare 的回源端口规则 |
| 阿里云 ESA | AccessKey ID + Secret | 更新阿里云 ESA（边缘安全加速）的回源配置 |
| 腾讯云 EO | SecretId + SecretKey | 更新腾讯云 EO（边缘安全加速）的回源配置 |
| WebHook | 自定义 URL | 发送 HTTP 请求到任意 URL |
| 域名账号 | 引用已配置的域名账号 | 更新 DDNS 解析记录 |

### 添加回调账号

进入 **回调账号** 页面，点击 **新建** 按钮：

**Cloudflare 回源规则：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 账号名称 |
| API Token | 字符串 | ✅ | Cloudflare API Token（需要 Zone 编辑权限） |
| Zone ID | 字符串 | ✅ | 域名的 Zone ID |
| 规则 ID | 字符串 | ✅ | 要更新的回源规则 ID |

**阿里云 ESA：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 账号名称 |
| AccessKey ID | 字符串 | ✅ | 阿里云 AccessKey ID |
| AccessKey Secret | 字符串 | ✅ | 阿里云 AccessKey Secret |
| 站点 ID | 字符串 | ✅ | ESA 站点 ID |
| 规则 ID | 字符串 | ✅ | 要更新的规则 ID |

**腾讯云 EO：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 账号名称 |
| SecretId | 字符串 | ✅ | 腾讯云 SecretId |
| SecretKey | 字符串 | ✅ | 腾讯云 SecretKey |
| 站点 ID | 字符串 | ✅ | EO 站点 ID |
| 规则 ID | 字符串 | ✅ | 要更新的规则 ID |

**WebHook：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 账号名称 |
| URL | 字符串 | ✅ | WebHook 请求地址 |
| 方法 | 枚举 | ❌ | `GET` 或 `POST` |
| 请求头 | 文本 | ❌ | 自定义请求头 |
| 请求体模板 | 文本 | ❌ | 请求体，支持变量替换 |

**WebHook 请求体变量：**

| 变量 | 说明 |
|------|------|
| `{{ip}}` | 当前公网 IP |
| `{{port}}` | 当前映射端口 |
| `{{name}}` | STUN 规则名称 |

---

## 回调任务

回调任务定义了触发条件和要执行的操作。

### 添加回调任务

进入 **回调任务** 页面，点击 **新建** 按钮：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 任务名称 |
| 启用 | 布尔 | ✅ | 是否启用 |
| 触发条件 | 枚举 | ✅ | 目前支持：STUN IP 变化、STUN 端口变化 |
| 关联 STUN | 选择 | ✅ | 监听哪个 STUN 规则的变化 |
| 回调账号 | 选择 | ✅ | 触发时使用哪个回调账号 |

---

## 主流通知平台配置

### 钉钉机器人

1. 在钉钉群中添加「自定义机器人」，获取 Webhook URL
2. 配置安全设置（推荐使用「加签」方式）
3. 在回调账号中配置 WebHook：

| 字段 | 值 |
|------|-----|
| 类型 | WebHook |
| 名称 | 钉钉通知 |
| URL | `https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN` |
| 方法 | `POST` |
| 请求头 | `Content-Type: application/json` |
| 请求体模板 | `{"msgtype":"text","text":{"content":"⚠️ 公网IP已变更\n新IP：{{ip}}\n新端口：{{port}}"}}` |

### 企业微信机器人

1. 在企业微信群中添加「群机器人」，获取 Webhook URL
2. 在回调账号中配置 WebHook：

| 字段 | 值 |
|------|-----|
| 类型 | WebHook |
| 名称 | 企业微信通知 |
| URL | `https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY` |
| 方法 | `POST` |
| 请求头 | `Content-Type: application/json` |
| 请求体模板 | `{"msgtype":"text","text":{"content":"公网IP变更通知\nIP: {{ip}}\n端口: {{port}}"}}` |

### Telegram Bot

1. 通过 [@BotFather](https://t.me/BotFather) 创建 Bot，获取 Token
2. 获取目标 Chat ID（可通过 `https://api.telegram.org/bot<TOKEN>/getUpdates` 查看）
3. 在回调账号中配置 WebHook：

| 字段 | 值 |
|------|-----|
| 类型 | WebHook |
| 名称 | Telegram 通知 |
| URL | `https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage` |
| 方法 | `POST` |
| 请求头 | `Content-Type: application/json` |
| 请求体模板 | `{"chat_id":"YOUR_CHAT_ID","text":"🌐 公网IP变更\nIP: {{ip}}\n端口: {{port}}"}` |

### 自定义 HTTP 接口

适用于对接自建系统或其他平台：

| 字段 | 值 |
|------|-----|
| 类型 | WebHook |
| 名称 | 自定义接口 |
| URL | `https://your-server.com/api/ip-change` |
| 方法 | `POST` |
| 请求头 | `Content-Type: application/json` `Authorization: Bearer YOUR_TOKEN` |
| 请求体模板 | `{"ip":"{{ip}}","port":{{port}},"rule":"{{name}}","timestamp":"$(date +%s)"}` |

---

## 完整配置示例

### 场景：STUN 端口变化时更新 Cloudflare 回源端口

**背景：** 使用 Cloudflare 代理域名，后端通过 STUN 穿透暴露服务。当 STUN 映射端口变化时，需要自动更新 Cloudflare 的回源端口规则。

**第一步：配置回调账号**

| 字段 | 值 |
|------|-----|
| 类型 | Cloudflare 回源规则 |
| 名称 | CF 回源配置 |
| API Token | `your-cloudflare-api-token` |
| Zone ID | `your-zone-id` |
| 规则 ID | `your-rule-id` |

**第二步：配置回调任务**

| 字段 | 值 |
|------|-----|
| 名称 | STUN 端口变化更新 CF |
| 触发条件 | STUN 端口变化 |
| 关联 STUN | 选择已配置的 STUN 规则 |
| 回调账号 | 选择上一步配置的 CF 账号 |

配置完成后，每当 STUN 映射端口发生变化，系统会自动调用 Cloudflare API 更新回源端口，无需手动操作。

### 场景：IP 变化时同时通知多个平台

可以为同一个 STUN 规则配置多个回调任务，实现同时通知：

| 任务名称 | 触发条件 | 回调账号 |
|----------|----------|----------|
| 更新 CF 回源 | STUN 端口变化 | Cloudflare 账号 |
| 钉钉通知 | STUN IP 变化 | 钉钉机器人 |
| 更新 DDNS | STUN IP 变化 | 域名账号 |

---

## 常见问题排查

### 回调未触发

1. 确认回调任务已启用
2. 确认关联的 STUN 规则正常运行且有 IP/端口变化
3. 查看系统日志，确认事件是否被检测到

### WebHook 请求失败

1. **检查 URL 是否正确**：在浏览器或 `curl` 中手动测试
2. **检查请求体格式**：确保 JSON 格式正确，变量替换后语法有效
3. **检查网络连通性**：服务器是否能访问目标 URL（注意防火墙和代理）
4. **查看响应内容**：在回调历史中查看 HTTP 状态码和响应体

```bash
# 手动测试 WebHook
curl -X POST "https://oapi.dingtalk.com/robot/send?access_token=xxx" \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"测试消息"}}'
```

### API 认证失败

- **Cloudflare**：确认 API Token 有 `Zone:Edit` 权限，Zone ID 正确
- **阿里云**：确认 AccessKey 有 ESA 相关权限，且未过期
- **腾讯云**：确认 SecretId/SecretKey 正确，账号有 EO 操作权限

---

## 注意事项

::: tip 与 STUN 配合
回调系统需要配合 [STUN 内网穿透](/features/stun) 使用。在 STUN 规则中选择「触发回调」，并关联对应的回调任务。
:::

::: info 并行执行
当多个回调任务同时触发时，系统会并行执行所有任务，不保证执行顺序。各任务互相独立，一个任务失败不影响其他任务执行。
:::

::: warning API 凭证安全
回调账号中存储的 API Token、AccessKey 等凭证属于敏感信息，请遵循最小权限原则：
- Cloudflare Token 仅授予特定 Zone 的编辑权限
- 阿里云/腾讯云 AccessKey 仅授予 ESA/EO 相关权限
- 定期轮换 API 凭证
:::
