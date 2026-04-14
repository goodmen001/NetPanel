# 域名账号

域名账号用于统一管理各 DNS 服务商的 API 密钥，配置一次后可在 DDNS、域名证书、域名解析、回调等功能中复用，无需重复填写。

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

1. 登录 [阿里云控制台](https://ram.console.aliyun.com/users)
2. 创建 RAM 子用户，授予 `AliyunDNSFullAccess` 权限
3. 创建 AccessKey，获取 AccessKey ID 和 Secret

| 字段 | 说明 |
|------|------|
| AccessKey ID | 阿里云 RAM 用户的 AccessKey ID |
| AccessKey Secret | 阿里云 RAM 用户的 AccessKey Secret |

### 腾讯云

1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/cam/capi)
2. 创建 API 密钥，获取 SecretId 和 SecretKey
3. 确保账号有 DNSPod 相关权限

| 字段 | 说明 |
|------|------|
| SecretId | 腾讯云 API 密钥 SecretId |
| SecretKey | 腾讯云 API 密钥 SecretKey |

### Cloudflare

推荐使用 **API Token**（权限更精细）：

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 **Create Token**
3. 选择 **Edit zone DNS** 模板，选择对应的域名区域
4. 创建并复制 Token

| 字段 | 说明 |
|------|------|
| API Token | Cloudflare API Token（推荐） |
| Zone ID | 域名的 Zone ID（在域名概览页右侧可找到） |

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

## 注意事项

::: warning 密钥安全
API 密钥具有较高权限，请勿泄露。建议：
- 使用子账号/受限权限的 API Token，而非主账号密钥
- 定期轮换 API 密钥
- 不要将密钥提交到代码仓库
:::

::: tip 最小权限原则
为每个服务商创建专用的 API Token，只授予必要的权限（如仅 DNS 编辑权限），降低密钥泄露的风险。
:::
