# 系统日志

系统日志页面用于查看 NetPanel 的运行日志，帮助排查问题和监控系统状态。

## 功能概述

- 实时查看系统运行日志
- 支持按日志级别过滤（INFO、WARN、ERROR）
- 支持关键词搜索
- 支持按时间范围筛选

---

## 日志级别说明

| 级别 | 颜色标识 | 说明 | 是否需要关注 |
|------|----------|------|-------------|
| `INFO` | 蓝色 | 正常运行信息，如服务启动、规则变更、连接建立等 | 一般不需要 |
| `WARN` | 黄色 | 警告信息，如连接重试、配置异常、资源不足等 | 建议关注 |
| `ERROR` | 红色 | 错误信息，如服务启动失败、API 调用失败、认证错误等 | 必须处理 |

**日志格式示例：**
```
2024-01-15 10:23:45 [INFO]  [frp] 客户端连接成功: frp.example.com:7000
2024-01-15 10:24:01 [WARN]  [ddns] DNS 记录更新重试中 (1/3): rate limit exceeded
2024-01-15 10:25:30 [ERROR] [caddy] 证书申请失败: ACME challenge failed for domain example.com
```

---

## 查看日志

进入 **系统日志** 页面：

1. **实时日志**：页面会自动刷新，显示最新的日志条目
2. **过滤日志**：使用顶部的过滤器按级别、时间范围或关键词筛选
3. **搜索日志**：在搜索框中输入关键词，快速定位相关日志

### 常用过滤技巧

| 场景 | 过滤方式 |
|------|----------|
| 只看错误 | 级别选择 `ERROR` |
| 查看 FRP 相关日志 | 关键词输入 `frp` |
| 查看今日日志 | 时间范围选择今天 |
| 排查证书问题 | 关键词输入 `cert` 或 `acme` |
| 查看 DDNS 更新记录 | 关键词输入 `ddns` |

---

## 命令行查看日志

如果通过 systemd 服务运行，可以使用 `journalctl` 查看日志：

```bash
# 查看最新日志
journalctl -u netpanel -n 100

# 实时跟踪日志
journalctl -u netpanel -f

# 查看指定时间段的日志
journalctl -u netpanel --since "2024-01-01 00:00:00" --until "2024-01-02 00:00:00"

# 只查看错误日志
journalctl -u netpanel -p err
```

如果直接运行二进制文件，日志会输出到标准输出，可以重定向到文件：

```bash
./netpanel > netpanel.log 2>&1 &

# 查看日志
tail -f netpanel.log

# 只查看错误日志
grep "ERROR" netpanel.log
```

---

## 常见错误日志排查

### 服务启动失败

查找 `ERROR` 级别日志，常见原因及解决方案：

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `bind: address already in use` | 端口被占用 | 修改监听端口或停止占用端口的程序 |
| `permission denied` | 数据目录权限不足 | `chmod -R 755 /var/lib/netpanel` |
| `database disk image is malformed` | 数据库损坏 | 从备份恢复数据库 |
| `no such file or directory` | 数据目录不存在 | `mkdir -p /var/lib/netpanel/data` |

### FRP 连接问题

```
[frp] ERROR: connect to server failed: dial tcp x.x.x.x:7000: connection refused
```

**排查步骤：**
1. 确认 FRP 服务端是否正在运行
2. 检查服务端防火墙是否放行了 7000 端口
3. 验证服务端地址和端口配置是否正确
4. 检查 Token 是否与服务端一致

### EasyTier 组网问题

```
[easytier] WARN: peer x.x.x.x connection timeout, retrying...
```

**排查步骤：**
1. 确认网络名称和密码是否与其他节点一致
2. 检查中转服务器地址是否可达
3. 确认防火墙是否放行了 EasyTier 监听端口（默认 11010）
4. 查看节点列表，确认对端节点是否在线

### DDNS 更新失败

```
[ddns] ERROR: update DNS record failed: InvalidAccessKeyId
```

**排查步骤：**
1. 检查 DNS 服务商的 API Key 和 Secret 是否正确
2. 确认 API Key 是否有域名解析的写入权限
3. 检查是否触发了 API 频率限制（等待几分钟后重试）
4. 确认域名是否在该账号下

### SSL 证书申请失败

```
[caddy] ERROR: ACME challenge failed: DNS record not found
```

**排查步骤：**
1. 确认域名已正确解析到服务器 IP
2. DNS 解析生效需要时间（通常 1-10 分钟），等待后重试
3. 检查 80/443 端口是否可从外网访问（HTTP-01 验证需要）
4. 确认 DNS API 配置正确（DNS-01 验证需要）
5. Let's Encrypt 有频率限制：同一域名每周最多申请 5 次

### Caddy 网站服务异常

```
[caddy] ERROR: failed to start: listen tcp :443: bind: permission denied
```

**排查步骤：**
1. 监听 443/80 等特权端口需要 root 权限或设置 `CAP_NET_BIND_SERVICE`
2. 检查是否有其他程序占用了该端口：`ss -tlnp | grep :443`

---

## 日志管理最佳实践

### 日志轮转配置

使用 `logrotate` 自动管理日志文件大小：

```bash
# 创建 logrotate 配置文件
cat > /etc/logrotate.d/netpanel << 'EOF'
/var/lib/netpanel/data/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload netpanel 2>/dev/null || true
    endscript
}
EOF
```

### 使用计划任务清理日志

在 NetPanel 的 [计划任务](/features/cron) 中添加定期清理任务：

```bash
# 清理 30 天前的日志文件
find /var/lib/netpanel/data/logs/ -name "*.log" -mtime +30 -delete
```

### 日志监控告警

结合 [回调系统](/features/callback) 实现错误日志告警：

1. 创建一个计划任务，定期检查错误日志数量
2. 当错误数量超过阈值时，通过回调发送告警通知（钉钉、企业微信等）

---

## 注意事项

::: tip 日志文件大小
长时间运行后，日志文件可能会占用较多磁盘空间。可以使用 [计划任务](/features/cron) 定期清理旧日志，或配置 logrotate 自动轮转。
:::

::: info 日志保留策略
NetPanel 默认保留最近 7 天的日志。可以在系统设置中调整日志保留天数。
:::

::: warning 敏感信息
日志中可能包含 IP 地址、域名等信息，请注意日志文件的访问权限控制，避免泄露敏感信息。
:::
