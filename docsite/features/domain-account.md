# 域名账号

域名账号用于统一管理各 DNS 服务商的 API 密钥，配置一次后可在 DDNS、域名证书、域名解析、回调等功能中复用，无需重复填写。

## 技术原理

### DNS 服务商 API 工作机制

各大 DNS 服务商提供 RESTful API，允许通过程序自动化管理 DNS 记录。NetPanel 通过这些 API 实现：

```
NetPanel
   │
   ├──→ 阿里云 DNS API  → 增/删/改 DNS 记录
   ├──→ 腾讯云 API      → 增/删/改 DNS 记录
   ├──→ Cloudflare API  → 增/删/改 DNS 记录
   └──→ 其他服务商 API  → 增/删/改 DNS 记录
```

**API 密钥类型说明：**

| 类型 | 说明 | 安全性 |
|------|------|--------|
| 主账号密钥 | 拥有账号全部权限 | ⚠️ 风险高，不推荐 |
| 子账号密钥 | 仅授予特定权限 | ✅ 推荐 |
| API Token | 细粒度权限控制，可设置过期时间 | ✅ 最推荐 |

### 最小权限原则

为 DNS 操作创建专用密钥时，只需授予以下权限：
- **读取** DNS 记录（查询现有记录）
- **写入** DNS 记录（添加/修改/删除记录）

不需要授予：域名注册、账单管理、其他云服务等权限。

---

## 功能概述

- 集中管理各服务商的 API 凭证
- 支持多个账号（同一服务商可配置多个）
- 凭证加密存储，安全可靠
- 供 DDNS、证书申请、域名解析、回调等功能引用

## 支持的服务商

| 服务商 | 所需凭证 |
|--------|----------|
| 阿里云 | AccessKey ID + AccessKey Secret |
| 腾讯云 | SecretId + SecretKey |
| Cloudflare | API Token（推荐）或 Global API Key + 邮箱 |
| DNSPod | Token ID + Token |
| 华为云 | AccessKey ID + AccessKey Secret |
| GoDaddy | API Key + Secret |
| Namecheap | 用户名 + API Key |

---

## 配置说明

进入 **域名账号** 页面，点击 **新建** 按钮：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 名称 | 字符串 | ✅ | 账号名称，便于识别，如"阿里云主账号" |
| 服务商 | 枚举 | ✅ | DNS 服务商类型 |
| 凭证字段 | 字符串 | ✅ | 根据服务商不同，填写对应的 API 密钥 |

---

## 各服务商配置说明

### 阿里云

**推荐方式：创建 RAM 子用户**

1. 登录 [阿里云 RAM 控制台](https://ram.console.aliyun.com/users)
2. 点击 **创建用户** → 勾选 **OpenAPI 调用访问**
3. 在权限管理中，授予 `AliyunDNSFullAccess` 权限策略
4. 创建 AccessKey，保存 AccessKey ID 和 Secret

| 字段 | 说明 |
|------|------|
| AccessKey ID | 阿里云 RAM 用户的 AccessKey ID |
| AccessKey Secret | 阿里云 RAM 用户的 AccessKey Secret |

::: tip 精细化权限
如需更精细的权限控制，可创建自定义权限策略，只允许 `alidns:*` 操作，限制到特定域名。
:::

### 腾讯云

1. 登录 [腾讯云 API 密钥控制台](https://console.cloud.tencent.com/cam/capi)
2. 点击 **新建密钥**，获取 SecretId 和 SecretKey
3. 或创建子用户，授予 `QcloudDNSPodFullAccess` 权限

| 字段 | 说明 |
|------|------|
| SecretId | 腾讯云 API 密钥 SecretId |
| SecretKey | 腾讯云 API 密钥 SecretKey |

### Cloudflare

**推荐方式：使用 API Token（权限更精细）**

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 **Create Token**
3. 选择 **Edit zone DNS** 模板
4. 在 **Zone Resources** 中选择 **Specific zone** → 选择你的域名
5. 点击 **Continue to summary** → **Create Token**
6. 复制生成的 Token（只显示一次，请妥善保存）

| 字段 | 说明 |
|------|------|
| API Token | Cloudflare API Token（推荐） |
| Zone ID | 域名的 Zone ID（在域名概览页右侧可找到） |

::: warning Global API Key 风险
Cloudflare Global API Key 拥有账号全部权限，不推荐使用。请优先使用权限受限的 API Token。
:::

### DNSPod（独立版）

1. 登录 [DNSPod 控制台](https://console.dnspod.cn/account/token/token)
2. 点击 **创建 Token**，填写名称
3. 保存 Token ID 和 Token 值

| 字段 | 说明 |
|------|------|
| Token ID | DNSPod Token ID |
| Token | DNSPod Token 值 |

### 华为云

1. 登录 [华为云 IAM 控制台](https://console.huaweicloud.com/iam/)
2. 创建 IAM 用户，授予 DNS 相关权限
3. 创建访问密钥（AK/SK）

| 字段 | 说明 |
|------|------|
| AccessKey ID | 华为云 AK |
| AccessKey Secret | 华为云 SK |

---

## 配置示例

### 添加阿里云账号

| 字段 | 值 |
|------|-----|
| 名称 | 阿里云主账号 |
| 服务商 | 阿里云 |
| AccessKey ID | `LTAI5tXXXXXXXXXX` |
| AccessKey Secret | `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` |

配置完成后，在 DDNS、域名证书等功能中选择此账号即可使用。

---

## 常见问题

### Q：API 密钥配置正确，但操作 DNS 时提示权限不足？

**排查步骤：**
1. 确认子账号/Token 已授予 DNS 编辑权限
2. 检查权限是否限制了特定域名（需包含要操作的域名）
3. 阿里云用户检查是否开启了 MFA 验证（会影响 API 调用）
4. Cloudflare 用户确认 Zone ID 填写正确

### Q：同一服务商可以配置多个账号吗？

可以。例如你有多个阿里云账号管理不同域名，可以分别添加，在使用时选择对应账号。

### Q：API 密钥泄露了怎么办？

**立即执行：**
1. 登录对应服务商控制台，**立即禁用或删除**泄露的密钥
2. 在 NetPanel 中删除对应的域名账号
3. 创建新的 API 密钥，重新配置域名账号
4. 检查是否有异常 DNS 操作记录

---

## 注意事项

::: warning 密钥安全
API 密钥具有较高权限，请勿泄露。建议：
- 使用子账号/受限权限的 API Token，而非主账号密钥
- 定期轮换 API 密钥（建议每 90 天更换一次）
- 不要将密钥提交到代码仓库或截图分享
:::

::: tip 最小权限原则
为每个服务商创建专用的 API Token，只授予必要的权限（如仅 DNS 编辑权限），降低密钥泄露的风险。
:::

::: info 凭证加密存储
NetPanel 对所有 API 密钥进行加密存储，不会以明文形式保存在数据库中。
:::
