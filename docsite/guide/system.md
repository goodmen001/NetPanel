# 系统设置

系统设置页面用于配置 NetPanel 的基础运行参数。

## 系统架构说明

NetPanel 采用前后端分离架构，各组件关系如下：

```
┌─────────────────────────────────────────────────┐
│                   NetPanel                       │
│                                                  │
│  ┌──────────┐    ┌──────────┐    ┌───────────┐  │
│  │  Web UI  │───▶│  后端API  │───▶│  SQLite   │  │
│  │ (React)  │    │  (Go)    │    │  数据库    │  │
│  └──────────┘    └────┬─────┘    └───────────┘  │
│                       │                          │
│         ┌─────────────┼─────────────┐            │
│         ▼             ▼             ▼            │
│    ┌─────────┐  ┌──────────┐  ┌──────────┐      │
│    │  frpc/  │  │ EasyTier │  │  Caddy   │      │
│    │  frps   │  │  节点    │  │  网站    │      │
│    └─────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────┘
```

**数据流向：**
1. 用户通过浏览器访问 Web UI（默认端口 `8080`）
2. Web UI 调用后端 REST API 进行配置读写
3. 后端将配置持久化到 SQLite 数据库（`data/netpanel.db`）
4. 后端负责启动/停止/监控各子服务进程（frpc、frps、easytier、caddy 等）
5. 子服务的二进制文件存放在 `data/bin/` 目录下

---

## 配置项说明

进入 **系统设置** 页面，可以修改以下配置：

### 服务配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 监听端口 | 整数 | `8080` | NetPanel Web 界面的监听端口 |
| 监听地址 | 字符串 | `0.0.0.0` | 监听的 IP 地址，`0.0.0.0` 表示所有网卡 |
| 数据目录 | 字符串 | `./data` | 数据库和配置文件的存储目录 |

### 界面配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 界面语言 | 枚举 | `zh-CN` | 界面显示语言：中文（`zh-CN`）或英文（`en-US`） |
| 主题 | 枚举 | `light` | 界面主题：浅色（`light`）或深色（`dark`） |

### 安全配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| Session 超时 | 整数 | `86400` | 登录会话超时时间（秒），默认 24 小时 |
| 允许注册 | 布尔 | `false` | 是否允许新用户自行注册 |

---

## 默认账户

NetPanel 首次安装后会自动创建一个默认管理员账户：

| 字段 | 默认值 |
|------|--------|
| 用户名 | `admin` |
| 密码 | `admin` |

::: danger 请立即修改默认密码
首次登录后，请立即前往 **用户管理** 页面修改默认密码，避免安全风险。使用默认密码可能导致未授权访问。
:::

---

## 命令行参数

NetPanel 也支持通过命令行参数覆盖配置：

```bash
./netpanel [选项]
```

| 参数 | 说明 |
|------|------|
| `-port <端口>` | 覆盖监听端口 |
| `-data <路径>` | 覆盖数据目录 |

命令行参数的优先级高于配置文件。

---

## 数据备份与恢复

### 备份

NetPanel 的所有数据均存储在数据目录（默认 `./data`）中，备份该目录即可完整备份所有配置：

```bash
# 手动备份（停止服务后备份，确保数据一致性）
systemctl stop netpanel
tar -czf netpanel-backup-$(date +%Y%m%d).tar.gz /var/lib/netpanel/data/
systemctl start netpanel

# 在线备份（SQLite 支持热备份）
sqlite3 /var/lib/netpanel/data/netpanel.db ".backup /tmp/netpanel-backup.db"
```

数据目录结构说明：

| 路径 | 说明 |
|------|------|
| `data/netpanel.db` | SQLite 主数据库，存储所有配置 |
| `data/bin/` | 各子服务二进制文件（frpc、frps、easytier 等） |
| `data/certs/` | SSL 证书文件 |
| `data/logs/` | 日志文件 |

::: tip 自动备份
推荐使用 [计划任务](/features/cron) 配置每日自动备份，并将备份文件同步到远程存储（如网络存储、云盘）。
:::

### 恢复

```bash
# 停止服务
systemctl stop netpanel

# 恢复备份
tar -xzf netpanel-backup-20240101.tar.gz -C /

# 重启服务
systemctl start netpanel
```

---

## 版本升级

### 升级步骤

1. **备份数据**（参考上方备份步骤）

2. **下载新版本**

```bash
# 从 GitHub Releases 下载最新版本
wget https://github.com/PIKACHUIM/NetPanel/releases/latest/download/netpanel-linux-amd64.tar.gz
tar -xzf netpanel-linux-amd64.tar.gz
```

3. **替换二进制文件**

```bash
# 停止服务
systemctl stop netpanel

# 替换主程序（数据目录不变）
cp netpanel /usr/local/bin/netpanel
chmod +x /usr/local/bin/netpanel

# 重启服务
systemctl start netpanel
```

4. **验证升级**：访问 Web UI，检查版本号和功能是否正常。

::: warning 升级注意事项
- 升级前务必备份数据目录
- 跨大版本升级（如 v1.x → v2.x）请先阅读版本更新日志，了解破坏性变更
- 子服务二进制文件（frpc、easytier 等）存放在 `data/bin/` 目录，升级 NetPanel 主程序不会影响这些文件
:::

---

## 管理员密码重置

如果忘记了管理员密码，可通过以下方式重置：

### 方法一：命令行重置（推荐）

```bash
# 停止 NetPanel
systemctl stop netpanel

# 删除所有用户，重新进入初始化向导
sqlite3 /var/lib/netpanel/data/netpanel.db "DELETE FROM users;"

# 重启 NetPanel
systemctl start netpanel
```

重启后访问 Web UI，会重新进入初始化向导，可以设置新的管理员账号。

### 方法二：直接修改数据库

```bash
# 生成新密码的 bcrypt 哈希（需要安装 htpasswd 或使用在线工具）
# 以下示例将密码重置为 "newpassword123"
NEW_HASH=$(htpasswd -bnBC 10 "" newpassword123 | tr -d ':\n' | sed 's/$2y/$2a/')

# 更新数据库中的密码
sqlite3 /var/lib/netpanel/data/netpanel.db \
  "UPDATE users SET password='$NEW_HASH' WHERE username='admin';"
```

::: tip 重置后立即修改密码
密码重置后，请立即登录并在 **用户管理** 页面设置一个强密码。
:::

---

## 注意事项

::: warning 修改端口后重新访问
修改监听端口后，需要使用新端口重新访问 NetPanel。如果通过防火墙限制了访问，记得同时更新防火墙规则。
:::

::: tip 数据目录备份
建议定期备份数据目录，其中包含 SQLite 数据库（`netpanel.db`）和所有配置文件。可以使用 [计划任务](/features/cron) 自动化备份。
:::

---

## 官方资源

| 资源 | 链接 |
|------|------|
| 官方文档 | [netpanel.opkg.cn](https://netpanel.opkg.cn) |
| GitHub 仓库 | [github.com/PIKACHUIM/NetPanel](https://github.com/PIKACHUIM/NetPanel) |
| 二进制下载 | [GitHub Releases](https://github.com/PIKACHUIM/NetPanel/releases) |
| 版本更新日志 | [Releases 页面](https://github.com/PIKACHUIM/NetPanel/releases) |
| 问题反馈 | [GitHub Issues](https://github.com/PIKACHUIM/NetPanel/issues) |
