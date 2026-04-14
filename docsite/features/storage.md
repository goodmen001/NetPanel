# 网络存储

网络存储功能可以将服务器上的指定目录通过 WebDAV 或 SFTP 协议对外提供访问，方便远程管理文件。NetPanel 内置了轻量级的 WebDAV 和 SFTP 服务，无需额外安装软件即可使用。

## 技术原理

### 协议对比

| 协议 | 全称 | 传输层 | 加密 | 适用场景 |
|------|------|--------|------|----------|
| WebDAV | Web Distributed Authoring and Versioning | HTTP/HTTPS | 可选（HTTPS） | 跨平台文件访问，浏览器/系统原生支持 |
| SFTP | SSH File Transfer Protocol | SSH | 强制加密 | 安全文件传输，命令行/专业工具 |
| SMB | Server Message Block | TCP 445 | 可选 | Windows 局域网共享（NetPanel 暂不支持） |
| NFS | Network File System | TCP/UDP | 可选 | Linux 高性能网络文件系统（NetPanel 暂不支持） |

### WebDAV 工作原理

WebDAV 是 HTTP 协议的扩展，在标准 GET/POST 基础上增加了文件操作方法：

```
客户端                          WebDAV 服务器（NetPanel）
  │                                      │
  │  PROPFIND /files/  (列出目录)         │
  │─────────────────────────────────────>│
  │  207 Multi-Status (目录内容)          │
  │<─────────────────────────────────────│
  │                                      │
  │  GET /files/doc.pdf  (下载文件)       │
  │─────────────────────────────────────>│
  │  200 OK + 文件内容                    │
  │<─────────────────────────────────────│
  │                                      │
  │  PUT /files/new.txt  (上传文件)       │
  │─────────────────────────────────────>│
  │  201 Created                         │
  │<─────────────────────────────────────│
```

**WebDAV 扩展方法：**

| 方法 | 说明 |
|------|------|
| `PROPFIND` | 获取文件/目录属性（列目录） |
| `MKCOL` | 创建目录 |
| `COPY` | 复制文件/目录 |
| `MOVE` | 移动/重命名文件/目录 |
| `DELETE` | 删除文件/目录 |
| `LOCK/UNLOCK` | 文件锁定（防止并发写入冲突） |

### SFTP 工作原理

SFTP 基于 SSH 协议，所有数据均经过加密传输：

```
客户端（FileZilla/WinSCP）          SFTP 服务器（NetPanel）
         │                                   │
         │  SSH 握手 + 身份验证               │
         │──────────────────────────────────>│
         │  建立加密通道                      │
         │<──────────────────────────────────│
         │                                   │
         │  文件操作请求（加密）               │
         │──────────────────────────────────>│
         │  响应（加密）                      │
         │<──────────────────────────────────│
```

---

## 功能概述

- 通过 **WebDAV** 协议提供文件访问（支持 Windows 资源管理器、macOS Finder 直接挂载）
- 通过 **SFTP** 协议提供加密文件访问（支持 FileZilla、WinSCP、命令行等工具）
- 支持用户名/密码认证
- 支持只读或读写模式
- 支持多个存储实例，不同目录使用不同端口和权限

---

## 配置说明

进入 **网络存储** 页面，点击 **新建** 按钮：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| 名称 | 字符串 | ✅ | — | 存储实例名称 |
| 启用 | 布尔 | ✅ | `true` | 是否启用 |
| 协议 | 枚举 | ✅ | `WebDAV` | `WebDAV` 或 `SFTP` |
| 根目录 | 字符串 | ✅ | — | 对外暴露的本地目录路径 |
| 监听端口 | 整数 | ✅ | — | 服务监听端口 |
| 用户名 | 字符串 | ✅ | — | 访问用户名 |
| 密码 | 字符串 | ✅ | — | 访问密码（建议使用强密码） |
| 只读模式 | 布尔 | ❌ | `false` | 是否只允许读取，禁止写入/删除 |

---

## 配置示例

### 示例 1：WebDAV 文件共享

将 `/home/user/files` 目录通过 WebDAV 共享：

| 字段 | 值 |
|------|-----|
| 名称 | 文件共享 |
| 协议 | `WebDAV` |
| 根目录 | `/home/user/files` |
| 监听端口 | `8081` |
| 用户名 | `admin` |
| 密码 | `your-strong-password` |
| 只读模式 | `false` |

### 示例 2：SFTP 安全传输

将 `/data/backup` 目录通过 SFTP 提供只读访问：

| 字段 | 值 |
|------|-----|
| 名称 | 备份只读访问 |
| 协议 | `SFTP` |
| 根目录 | `/data/backup` |
| 监听端口 | `2222` |
| 用户名 | `backup-reader` |
| 密码 | `your-strong-password` |
| 只读模式 | `true` |

### 示例 3：多目录分权限管理

为不同目录创建不同的存储实例，实现权限隔离：

| 实例 | 协议 | 目录 | 端口 | 只读 |
|------|------|------|------|------|
| 照片共享 | WebDAV | `/home/photos` | `8082` | ✅ |
| 文档协作 | WebDAV | `/home/docs` | `8083` | ❌ |
| 系统备份 | SFTP | `/data/backup` | `2223` | ✅ |

---

## 客户端连接方式

### WebDAV 客户端

#### Windows 资源管理器（原生支持）

**方法一：映射网络驱动器**
1. 打开"此电脑"，点击顶部"映射网络驱动器"
2. 驱动器号选择任意字母（如 `Z:`）
3. 文件夹填写：`http://服务器IP:8081`
4. 勾选"使用其他凭据连接"
5. 输入用户名和密码，点击完成

**方法二：直接在地址栏输入**
1. 打开资源管理器
2. 地址栏输入：`\\服务器IP@8081\DavWWWRoot`
3. 输入用户名和密码

::: warning Windows WebDAV HTTPS 要求
Windows 10/11 默认要求 WebDAV 使用 HTTPS。如果使用 HTTP，需要修改注册表：
```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters
BasicAuthLevel = 2（允许 HTTP 基本认证）
```
或者通过 [Caddy 反向代理](/features/caddy) 为 WebDAV 添加 HTTPS 支持。
:::

#### macOS Finder（原生支持）

1. 菜单栏 → **前往** → **连接服务器**（快捷键 `⌘K`）
2. 服务器地址输入：`http://服务器IP:8081`（HTTPS 则用 `https://`）
3. 点击"连接"，输入用户名和密码
4. 选择挂载点，即可在 Finder 中访问

#### Linux 命令行挂载

```bash
# 安装 davfs2
sudo apt install davfs2          # Debian/Ubuntu
sudo yum install davfs2          # CentOS/RHEL

# 创建挂载点
sudo mkdir -p /mnt/webdav

# 挂载（会提示输入用户名和密码）
sudo mount -t davfs http://服务器IP:8081 /mnt/webdav

# 自动挂载（写入 /etc/fstab）
# 先将凭据写入 /etc/davfs2/secrets
echo "http://服务器IP:8081 用户名 密码" | sudo tee -a /etc/davfs2/secrets
sudo chmod 600 /etc/davfs2/secrets

# 在 /etc/fstab 中添加
http://服务器IP:8081  /mnt/webdav  davfs  defaults,_netdev  0  0
```

#### 跨平台客户端推荐

| 客户端 | 平台 | 特点 |
|--------|------|------|
| [Cyberduck](https://cyberduck.io) | Windows/macOS | 免费，支持 WebDAV/SFTP/S3 |
| [RaiDrive](https://www.raidrive.com) | Windows | 将 WebDAV 映射为本地磁盘 |
| [Mountain Duck](https://mountainduck.io) | Windows/macOS | 付费，功能强大 |
| [ES 文件浏览器](https://www.estrongs.com) | Android | 支持 WebDAV 访问 |

---

### SFTP 客户端

#### FileZilla（推荐，免费）

1. 下载安装 [FileZilla](https://filezilla-project.org)
2. 打开站点管理器（`Ctrl+S`）
3. 新建站点，填写：
   - 协议：`SFTP - SSH File Transfer Protocol`
   - 主机：`服务器IP`
   - 端口：`2222`
   - 登录类型：`正常`
   - 用户：填写用户名
   - 密码：填写密码
4. 点击"连接"

#### WinSCP（Windows 推荐）

1. 下载安装 [WinSCP](https://winscp.net)
2. 新建会话：
   - 文件协议：`SFTP`
   - 主机名：`服务器IP`
   - 端口号：`2222`
   - 用户名/密码：填写配置的凭证
3. 点击"登录"

#### 命令行 SFTP

```bash
# 连接 SFTP
sftp -P 2222 用户名@服务器IP

# 常用命令
ls          # 列出远程目录
lls         # 列出本地目录
get file    # 下载文件
put file    # 上传文件
mkdir dir   # 创建目录
exit        # 退出

# 使用 scp 传输单个文件
scp -P 2222 本地文件 用户名@服务器IP:远程路径
scp -P 2222 用户名@服务器IP:远程文件 本地路径
```

#### Linux 挂载 SFTP（sshfs）

```bash
# 安装 sshfs
sudo apt install sshfs

# 创建挂载点
mkdir -p ~/remote-files

# 挂载
sshfs -p 2222 用户名@服务器IP:/ ~/remote-files

# 卸载
fusermount -u ~/remote-files
```

---

## 安全最佳实践

::: danger 安全警告
网络存储服务直接暴露文件系统，安全配置至关重要。请务必遵循以下建议：
:::

| 安全项 | 建议 |
|--------|------|
| 密码强度 | 使用至少 12 位包含大小写字母、数字和特殊字符的密码 |
| 目录范围 | 只暴露必要的目录，**绝不要**将根目录 `/` 作为根目录 |
| 只读模式 | 对于只需读取的场景，启用只读模式 |
| 访问控制 | 配合 [访问控制](/features/access-control) 限制来源 IP |
| HTTPS 加密 | WebDAV 建议通过 [Caddy 反向代理](/features/caddy) 添加 HTTPS |
| 端口选择 | 避免使用默认端口，使用非标准端口减少扫描风险 |
| 定期审查 | 定期检查访问日志，发现异常及时处理 |

---

## 常见问题排查

### WebDAV 连接失败

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| Windows 无法连接 HTTP | Windows 默认禁止 HTTP 基本认证 | 修改注册表或改用 HTTPS |
| 401 未授权 | 用户名或密码错误 | 检查凭据是否正确 |
| 403 禁止访问 | 目录权限不足 | 检查 NetPanel 进程对目录的读写权限 |
| 连接超时 | 端口未开放 | 检查防火墙是否放行对应端口 |

### SFTP 连接失败

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| 连接被拒绝 | 端口未开放或服务未启动 | 检查服务状态和防火墙规则 |
| 认证失败 | 用户名或密码错误 | 检查凭据是否正确 |
| 权限被拒绝 | 目录权限不足 | 检查目录权限 |

---

## 注意事项

::: warning 安全建议
- 使用强密码，避免使用弱密码
- 建议只暴露必要的目录，不要暴露系统根目录
- 如果通过公网访问，建议配合 [访问控制](/features/access-control) 限制来源 IP
:::

::: tip HTTPS 加密
WebDAV 默认使用 HTTP 传输，数据未加密。如需加密传输，可以通过 [Caddy 反向代理](/features/caddy) 为 WebDAV 添加 HTTPS 支持，然后使用 `https://` 地址连接。
:::

::: info 与网络唤醒配合使用
可以先通过 [网络唤醒](/features/wol) 唤醒 NAS 设备，再通过网络存储访问其文件，实现按需访问、节能省电的家庭 NAS 方案。
:::
