package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/netpanel/netpanel/model"
	"github.com/netpanel/netpanel/pkg/logger"
	"github.com/netpanel/netpanel/service/wireguard"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// ===== WireGuard 接口管理 =====

type WireguardHandler struct {
	db  *gorm.DB
	log *logrus.Logger
	mgr *wireguard.Manager
}

func NewWireguardHandler(db *gorm.DB, log *logrus.Logger, mgr *wireguard.Manager) *WireguardHandler {
	return &WireguardHandler{db: db, log: log, mgr: mgr}
}

func (h *WireguardHandler) List(c *gin.Context) {
	var configs []model.WireguardConfig
	h.db.Order("id desc").Find(&configs)
	for i := range configs {
		configs[i].Status = h.mgr.GetStatus(configs[i].ID)
	}
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": configs})
}

func (h *WireguardHandler) Create(c *gin.Context) {
	var cfg model.WireguardConfig
	if err := c.ShouldBindJSON(&cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}
	// 如果未提供密钥对，自动生成
	if cfg.PrivateKey == "" {
		privKey, pubKey, err := wireguard.GenerateKeyPair()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "生成密钥对失败: " + err.Error()})
			return
		}
		cfg.PrivateKey = privKey
		cfg.PublicKey = pubKey
	}
	cfg.Status = "stopped"
	h.db.Create(&cfg)
	if cfg.Enable {
		h.mgr.Start(cfg.ID)
	}
	logger.WriteLog("info", "wireguard", fmt.Sprintf("创建WireGuard接口 [%d] %s", cfg.ID, cfg.Name))
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": cfg, "message": "创建成功"})
}

func (h *WireguardHandler) Update(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	var req model.WireguardConfig
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}
	h.mgr.Stop(uint(id))
	req.ID = uint(id)
	h.db.Save(&req)
	if req.Enable {
		h.mgr.Start(uint(id))
	}
	logger.WriteLog("info", "wireguard", fmt.Sprintf("更新WireGuard接口 [%d] %s", id, req.Name))
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": req, "message": "更新成功"})
}

func (h *WireguardHandler) Delete(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	h.mgr.Stop(uint(id))
	// 删除关联的对等节点
	h.db.Where("wireguard_id = ?", id).Delete(&model.WireguardPeer{})
	h.db.Delete(&model.WireguardConfig{}, id)
	logger.WriteLog("info", "wireguard", fmt.Sprintf("删除WireGuard接口 [%d]", id))
	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
}

func (h *WireguardHandler) Start(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	if err := h.mgr.Start(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": err.Error()})
		return
	}
	h.db.Model(&model.WireguardConfig{}).Where("id = ?", id).Update("enable", true)
	logger.WriteLog("info", "wireguard", fmt.Sprintf("启动WireGuard接口 [%d]", id))
	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "已启动"})
}

func (h *WireguardHandler) Stop(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	h.mgr.Stop(uint(id))
	h.db.Model(&model.WireguardConfig{}).Where("id = ?", id).Update("enable", false)
	logger.WriteLog("info", "wireguard", fmt.Sprintf("停止WireGuard接口 [%d]", id))
	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "已停止"})
}

func (h *WireguardHandler) GetStatus(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	status := h.mgr.GetStatus(uint(id))
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": gin.H{"status": status}})
}

// GenerateKeyPair 生成密钥对
func (h *WireguardHandler) GenerateKeyPair(c *gin.Context) {
	privKey, pubKey, err := wireguard.GenerateKeyPair()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "生成密钥对失败: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": gin.H{"private_key": privKey, "public_key": pubKey}})
}

// ===== WireGuard 对等节点管理 =====

func (h *WireguardHandler) ListPeers(c *gin.Context) {
	wgID, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	var peers []model.WireguardPeer
	h.db.Where("wireguard_id = ?", wgID).Order("id desc").Find(&peers)
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": peers})
}

func (h *WireguardHandler) CreatePeer(c *gin.Context) {
	wgID, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	var peer model.WireguardPeer
	if err := c.ShouldBindJSON(&peer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}
	peer.WireguardID = uint(wgID)
	h.db.Create(&peer)
	// 如果接口正在运行，重新加载配置
	h.mgr.ReloadConfig(uint(wgID))
	logger.WriteLog("info", "wireguard", fmt.Sprintf("创建WireGuard对等节点 [%d] %s", peer.ID, peer.Name))
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": peer, "message": "创建成功"})
}

func (h *WireguardHandler) UpdatePeer(c *gin.Context) {
	wgID, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	peerID, _ := strconv.ParseUint(c.Param("pid"), 10, 64)
	var req model.WireguardPeer
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}
	req.ID = uint(peerID)
	req.WireguardID = uint(wgID)
	h.db.Save(&req)
	h.mgr.ReloadConfig(uint(wgID))
	logger.WriteLog("info", "wireguard", fmt.Sprintf("更新WireGuard对等节点 [%d] %s", peerID, req.Name))
	c.JSON(http.StatusOK, gin.H{"code": 200, "data": req, "message": "更新成功"})
}

func (h *WireguardHandler) DeletePeer(c *gin.Context) {
	wgID, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	peerID, _ := strconv.ParseUint(c.Param("pid"), 10, 64)
	h.db.Delete(&model.WireguardPeer{}, peerID)
	h.mgr.ReloadConfig(uint(wgID))
	logger.WriteLog("info", "wireguard", fmt.Sprintf("删除WireGuard对等节点 [%d]", peerID))
	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
}
