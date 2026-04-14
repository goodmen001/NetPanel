# FRP 服务端

NetPanel 支持运行 FRP 服务端（frps），让你可以自建穿透服务，供 FRP 客户端连接使用。

## 功能概述

- 运行 frps 服务端进程
- 支持 Token 认证
- 可配置监听端口和 Dashboard
- 支持多客户端同时连接

---

## 配置说明

进入 **FRP 服务端** 页面，点击 **新建** 按钮：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 名称 | 字符串 | ✅ | — | 服务端实例名称 |
| 启用 | 布尔 | ✅ | `true` | 是否启用 |
| 监听地址 | 字符串 | ❌ | `0.0.0.0` | 服务端监听 IP |
| 监听端口 | 整数 | ✅ | `7000` | 客户端连接端口 |
| Token | 字符串 | ❌ | — | 认证 Token，客户端需填写相同 Token |
| HTTP 端口 | 整数 | ❌ | `80` | HTTP 类型代理的监听端口 |
| HTTPS 端口 | 整数 | ❌ | `443` | HTTPS 类型代理的监听端口 |
| Dashboard 端口 | 整数 | ❌ | — | FRP 管理面板端口（留空则不启用） |
| Dashboard 用户名 | 字符串 | ❌ | `admin` | Dashboard 登录用户名 |
| Dashboard 密码 | 字符串 | ❌ | — | Dashboard 登录密码 |
| 最大连接数 | 整数 | ❌ | `0` | 每个客户端最大代理数，0 表示不限制 |

---

## 配置示例

### 基础配置

| 字段 | 值 |
|------|-----|
| 名称 | 主服务端 |
| 监听端口 | `7000` |
| Token | `my-secret-token-2024` |
| HTTP 端口 | `80` |
| HTTPS 端口 | `443` |

### 启用 Dashboard

| 字段 | 值 |
|------|-----|
| Dashboard 端口 | `7500` |
| Dashboard 用户名 | `admin` |
| Dashboard 密码 | `your-dashboard-password` |

启用后，访问 `http://服务器IP:7500` 可查看所有客户端连接状态和流量统计。

---

## 防火墙配置

运行 FRP 服务端后，需要在服务器防火墙中放行以下端口：

```bash
# 放行客户端连接端口
ufw allow 7000/tcp

# 放行 HTTP/HTTPS 代理端口
ufw allow 80/tcp
ufw allow 443/tcp

# 放行 Dashboard 端口（如果启用）
ufw allow 7500/tcp

# 放行客户端映射的远程端口（按需）
ufw allow 6022/tcp
```

---

## 注意事项

::: warning 安全建议
- 务必设置强 Token，防止未授权客户端连接
- Dashboard 密码不要使用弱密码
- 建议通过防火墙限制 Dashboard 端口的访问来源
:::

::: tip 与客户端配合
FRP 服务端配置完成后，在 [FRP 客户端](/features/frp-client) 中填写服务端地址和 Token 即可连接。
:::
