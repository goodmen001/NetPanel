package cron

import (
	"context"
	"fmt"
	"net/http"
	"os/exec"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/netpanel/netpanel/model"
	"github.com/netpanel/netpanel/service/cert"
	"github.com/netpanel/netpanel/service/ddns"
	"github.com/netpanel/netpanel/service/wol"
	"github.com/robfig/cron/v3"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// SyncDNSRecordFunc 同步 DNS 解析记录的回调函数类型
type SyncDNSRecordFunc func(ctx context.Context, domainInfoID uint) (int, error)

// Manager 计划任务管理器
type Manager struct {
	db       *gorm.DB
	log      *logrus.Logger
	cron     *cron.Cron
	entryIDs sync.Map // map[uint]cron.EntryID
	mu       sync.Mutex
	certMgr  *cert.Manager
	ddnsMgr  *ddns.Manager
	wolMgr   *wol.Manager
	syncDNSRecordFunc SyncDNSRecordFunc // 由外部注入的 DNS 解析记录同步函数
}

func NewManager(db *gorm.DB, log *logrus.Logger, certMgr *cert.Manager, ddnsMgr *ddns.Manager, wolMgr *wol.Manager) *Manager {
	c := cron.New(cron.WithSeconds())
	c.Start()
	return &Manager{db: db, log: log, cron: c, certMgr: certMgr, ddnsMgr: ddnsMgr, wolMgr: wolMgr}
}

func (m *Manager) StartAll() {
	var tasks []model.CronTask
	m.db.Where("enable = ?", true).Find(&tasks)
	for i := range tasks {
		if err := m.AddTask(&tasks[i]); err != nil {
			m.log.Errorf("计划任务 [%s] 添加失败: %v", tasks[i].Name, err)
		}
	}
}

func (m *Manager) StopAll() {
	m.cron.Stop()
}

func (m *Manager) AddTask(task *model.CronTask) error {
	m.RemoveTask(task.ID)

	entryID, err := m.cron.AddFunc(task.CronExpr, func() {
		m.executeTask(task.ID)
	})
	if err != nil {
		return fmt.Errorf("添加计划任务失败: %w", err)
	}

	m.entryIDs.Store(task.ID, entryID)
	m.db.Model(&model.CronTask{}).Where("id = ?", task.ID).Update("status", "running")
	m.log.Infof("[Cron][%d] 任务 %s 已添加，表达式: %s", task.ID, task.Name, task.CronExpr)
	return nil
}

func (m *Manager) RemoveTask(id uint) {
	if val, ok := m.entryIDs.Load(id); ok {
		m.cron.Remove(val.(cron.EntryID))
		m.entryIDs.Delete(id)
	}
	m.db.Model(&model.CronTask{}).Where("id = ?", id).Update("status", "stopped")
}

func (m *Manager) RunNow(id uint) error {
	var task model.CronTask
	if err := m.db.First(&task, id).Error; err != nil {
		return fmt.Errorf("任务不存在: %w", err)
	}
	go m.executeTask(id)
	return nil
}

func (m *Manager) executeTask(id uint) {
	var task model.CronTask
	if err := m.db.First(&task, id).Error; err != nil {
		return
	}

	m.log.Infof("[Cron][%d] 开始执行任务: %s", id, task.Name)
	now := time.Now()
	var result string
	var execErr error

	switch task.TaskType {
	case "shell":
		result, execErr = m.runShell(task.Command)
	case "http":
		result, execErr = m.runHTTP(task.HTTPURL, task.HTTPMethod, task.HTTPBody)
	case "renew_cert":
		result, execErr = m.runRenewCert(task.TargetID)
	case "update_ddns":
		result, execErr = m.runUpdateDDNS(task.TargetID)
	case "wol":
		result, execErr = m.runWOL(task.TargetID)
	case "sync_dns_record":
		result, execErr = m.runSyncDNSRecord(task.TargetID)
	default:
		result = "未知任务类型"
	}

	if execErr != nil {
		m.log.Errorf("[Cron][%d] 任务执行失败: %v", id, execErr)
		result = "错误: " + execErr.Error()
	} else {
		m.log.Infof("[Cron][%d] 任务执行成功", id)
	}

	m.db.Model(&model.CronTask{}).Where("id = ?", id).Updates(map[string]interface{}{
		"last_run_time":   now,
		"last_run_result": result,
	})
}

func (m *Manager) runShell(command string) (string, error) {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/C", command)
	} else {
		cmd = exec.Command("sh", "-c", command)
	}
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func (m *Manager) runHTTP(url, method, body string) (string, error) {
	if method == "" {
		method = "GET"
	}
	client := &http.Client{Timeout: 30 * time.Second}
	var req *http.Request
	var err error
	if body != "" {
		req, err = http.NewRequest(method, url, strings.NewReader(body))
	} else {
		req, err = http.NewRequest(method, url, nil)
	}
	if err != nil {
		return "", err
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	return fmt.Sprintf("HTTP %d", resp.StatusCode), nil
}

// runRenewCert 续签 SSL 证书
func (m *Manager) runRenewCert(targetID uint) (string, error) {
	if m.certMgr == nil {
		return "", fmt.Errorf("证书管理器未初始化")
	}
	if targetID == 0 {
		return "", fmt.Errorf("未指定证书 ID")
	}
	var certRecord model.DomainCert
	if err := m.db.First(&certRecord, targetID).Error; err != nil {
		return "", fmt.Errorf("证书不存在(ID=%d): %w", targetID, err)
	}
	if err := m.certMgr.Apply(targetID); err != nil {
		return "", fmt.Errorf("证书续签失败: %w", err)
	}
	return fmt.Sprintf("证书 [%s] 续签成功", certRecord.Name), nil
}

// runUpdateDDNS 更新 DDNS 记录
func (m *Manager) runUpdateDDNS(targetID uint) (string, error) {
	if m.ddnsMgr == nil {
		return "", fmt.Errorf("DDNS 管理器未初始化")
	}
	if targetID == 0 {
		return "", fmt.Errorf("未指定 DDNS 任务 ID")
	}
	var ddnsTask model.DDNSTask
	if err := m.db.First(&ddnsTask, targetID).Error; err != nil {
		return "", fmt.Errorf("DDNS 任务不存在(ID=%d): %w", targetID, err)
	}
	if err := m.ddnsMgr.RunNow(targetID); err != nil {
		return "", fmt.Errorf("DDNS 更新失败: %w", err)
	}
	return fmt.Sprintf("DDNS 任务 [%s] 已触发更新", ddnsTask.Name), nil
}

// runWOL 执行网络唤醒
func (m *Manager) runWOL(targetID uint) (string, error) {
	if m.wolMgr == nil {
		return "", fmt.Errorf("WOL 管理器未初始化")
	}
	if targetID == 0 {
		return "", fmt.Errorf("未指定 WOL 设备 ID")
	}
	var device model.WolDevice
	if err := m.db.First(&device, targetID).Error; err != nil {
		return "", fmt.Errorf("WOL 设备不存在(ID=%d): %w", targetID, err)
	}
	if err := m.wolMgr.Wake(targetID); err != nil {
		return "", fmt.Errorf("网络唤醒失败: %w", err)
	}
	return fmt.Sprintf("WOL 设备 [%s] (MAC: %s) 唤醒包已发送", device.Name, device.MACAddress), nil
}

// SetSyncDNSRecordFunc 设置 DNS 解析记录同步回调函数
func (m *Manager) SetSyncDNSRecordFunc(fn SyncDNSRecordFunc) {
	m.syncDNSRecordFunc = fn
}

// runSyncDNSRecord 同步 DNS 解析记录
func (m *Manager) runSyncDNSRecord(targetID uint) (string, error) {
	if m.syncDNSRecordFunc == nil {
		return "", fmt.Errorf("DNS 解析记录同步函数未初始化")
	}
	if targetID == 0 {
		return "", fmt.Errorf("未指定域名 ID")
	}
	var domainInfo model.DomainInfo
	if err := m.db.First(&domainInfo, targetID).Error; err != nil {
		return "", fmt.Errorf("域名不存在(ID=%d): %w", targetID, err)
	}
	count, err := m.syncDNSRecordFunc(context.Background(), targetID)
	if err != nil {
		return "", fmt.Errorf("DNS 解析记录同步失败: %w", err)
	}
	return fmt.Sprintf("域名 [%s] 解析记录同步成功，共 %d 条记录", domainInfo.Name, count), nil
}