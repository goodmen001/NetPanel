# 系统日志

系统日志页面用于查看 NetPanel 的运行日志，帮助排查问题和监控系统状态。

## 功能概述

- 实时查看系统运行日志
- 支持按日志级别过滤（INFO、WARN、ERROR）
- 支持关键词搜索
- 支持按时间范围筛选

---

## 日志级别说明

| 级别 | 说明 |
|------|------|
| `INFO` | 正常运行信息，如服务启动、规则变更等 |
| `WARN` | 警告信息，如连接重试、配置异常等 |
| `ERROR` | 错误信息，如服务启动失败、API 调用失败等 |

---

## 查看日志

进入 **系统日志** 页面：

1. **实时日志**：页面会自动刷新，显示最新的日志条目
2. **过滤日志**：使用顶部的过滤器按级别、时间范围或关键词筛选
3. **搜索日志**：在搜索框中输入关键词，快速定位相关日志

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
```

---

## 常见日志排查

### 服务启动失败

查找 `ERROR` 级别日志，常见原因：
- 端口被占用：`bind: address already in use`
- 数据目录权限不足：`permission denied`
- 数据库损坏：`database disk image is malformed`

### 功能异常

查找对应功能的日志，如 FRP 连接失败：
```
[frp] ERROR: connect to server failed: dial tcp ...
```

### API 调用失败

DDNS 或证书申请失败时，日志会包含 API 错误信息：
```
[ddns] ERROR: update DNS record failed: ...
```

---

## 注意事项

::: tip 日志文件大小
长时间运行后，日志文件可能会占用较多磁盘空间。可以使用 [计划任务](/features/cron) 定期清理旧日志，或配置 logrotate 自动轮转。
:::

::: info 日志保留策略
NetPanel 默认保留最近 7 天的日志。可以在系统设置中调整日志保留天数。
:::
