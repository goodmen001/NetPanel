package access

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/netpanel/netpanel/model"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// resolvedRule 预解析后的访问控制规则（包含从 IPDB 解析出的 IP 列表）
type resolvedRule struct {
	model.AccessRule
	// 合并后的 IP 列表（手动输入 + IPDB 条目）
	AllIPs []string
	// 绑定的站点域名/端口列表（用于匹配请求）
	BindSites []siteMatch
}

// siteMatch 站点匹配信息
type siteMatch struct {
	Domain string
	Port   int
}

// Manager 访问控制管理器
type Manager struct {
	db           *gorm.DB
	log          *logrus.Logger
	rules        []resolvedRule
	mu           sync.RWMutex
	// excludePaths 不受访问控制影响的路径前缀（可通过 SetExcludePaths 配置）
	excludePaths []string
}

func NewManager(db *gorm.DB, log *logrus.Logger) *Manager {
	m := &Manager{
		db:  db,
		log: log,
		// 默认不豁免任何路径，所有请求均受访问控制
		excludePaths: []string{},
	}
	m.loadRules()
	return m
}

// SetExcludePaths 设置不受访问控制影响的路径前缀列表
// 例如：["/api/v1/system/login"] 使登录接口不受访问控制影响
func (m *Manager) SetExcludePaths(paths []string) {
	m.mu.Lock()
	m.excludePaths = paths
	m.mu.Unlock()
}

func (m *Manager) loadRules() {
	var rules []model.AccessRule
	m.db.Where("enable = ?", true).Find(&rules)

	resolved := make([]resolvedRule, 0, len(rules))
	for _, rule := range rules {
		r := resolvedRule{AccessRule: rule}

		// 1. 解析手动输入的 IP 列表
		var manualIPs []string
		if rule.IPList != "" {
			json.Unmarshal([]byte(rule.IPList), &manualIPs)
		}

		// 2. 从 IPDB 条目获取 IP/CIDR
		var ipdbIPs []string
		if rule.BindIPDBIDs != "" {
			var ipdbIDs []uint
			if err := json.Unmarshal([]byte(rule.BindIPDBIDs), &ipdbIDs); err == nil && len(ipdbIDs) > 0 {
				var entries []model.IPDBEntry
				m.db.Where("id IN ?", ipdbIDs).Find(&entries)
				for _, e := range entries {
					if e.CIDR != "" {
						ipdbIPs = append(ipdbIPs, e.CIDR)
					}
				}
			}
		}

		// 3. 合并所有 IP
		r.AllIPs = append(manualIPs, ipdbIPs...)

		// 4. 解析绑定的站点
		if rule.BindSiteIDs != "" {
			var siteIDs []uint
			if err := json.Unmarshal([]byte(rule.BindSiteIDs), &siteIDs); err == nil && len(siteIDs) > 0 {
				var sites []model.CaddySite
				m.db.Where("id IN ?", siteIDs).Find(&sites)
				for _, s := range sites {
					r.BindSites = append(r.BindSites, siteMatch{
						Domain: s.Domain,
						Port:   s.Port,
					})
				}
			}
		}

		resolved = append(resolved, r)
	}

	m.mu.Lock()
	m.rules = resolved
	m.mu.Unlock()
}

func (m *Manager) Reload() {
	m.loadRules()
}

func (m *Manager) SetGinEngine(r *gin.Engine) {
	r.Use(m.GinMiddleware())
}

// GinMiddleware 访问控制 Gin 中间件
func (m *Manager) GinMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查是否在豁免路径列表中
		m.mu.RLock()
		excludePaths := m.excludePaths
		m.mu.RUnlock()

		path := c.Request.URL.Path
		for _, ep := range excludePaths {
			if strings.HasPrefix(path, ep) {
				c.Next()
				return
			}
		}

		clientIP := getClientIP(c.Request)
		requestHost := c.Request.Host // 包含域名和端口

		m.mu.RLock()
		rules := m.rules
		m.mu.RUnlock()

		for _, rule := range rules {
			if !rule.Enable {
				continue
			}

			// 如果绑定了站点，检查当前请求是否匹配绑定的站点
			if len(rule.BindSites) > 0 {
				if !matchRequestSite(requestHost, rule.BindSites) {
					// 当前请求不属于绑定的站点，跳过此规则
					continue
				}
			}

			matched := matchIP(clientIP, rule.AllIPs)

			switch rule.Mode {
			case "blacklist":
				if matched {
					m.log.Warnf("[访问控制] IP %s 在黑名单中，拒绝访问", clientIP)
					c.JSON(http.StatusForbidden, gin.H{"code": 403, "message": "访问被拒绝"})
					c.Abort()
					return
				}
			case "whitelist":
				if !matched {
					m.log.Warnf("[访问控制] IP %s 不在白名单中，拒绝访问", clientIP)
					c.JSON(http.StatusForbidden, gin.H{"code": 403, "message": "访问被拒绝"})
					c.Abort()
					return
				}
			}
		}

		c.Next()
	}
}

// matchRequestSite 检查请求的 Host 是否匹配绑定的站点列表
func matchRequestSite(requestHost string, sites []siteMatch) bool {
	// 解析请求的域名和端口
	host, port, err := net.SplitHostPort(requestHost)
	if err != nil {
		// 没有端口的情况
		host = requestHost
		port = ""
	}

	for _, site := range sites {
		// 域名匹配（忽略大小写）
		if site.Domain != "" && !strings.EqualFold(host, site.Domain) {
			continue
		}
		// 端口匹配
		if site.Port > 0 && port != "" && port != fmt.Sprintf("%d", site.Port) {
			continue
		}
		return true
	}
	return false
}

// getClientIP 获取客户端真实 IP
func getClientIP(r *http.Request) string {
	// 检查 X-Forwarded-For
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		if len(parts) > 0 {
			return strings.TrimSpace(parts[0])
		}
	}
	// 检查 X-Real-IP
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	// 使用 RemoteAddr
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// matchIP 检查 IP 是否匹配列表（支持 CIDR）
func matchIP(ip string, ipList []string) bool {
	clientIP := net.ParseIP(ip)
	if clientIP == nil {
		return false
	}

	for _, item := range ipList {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}

		// CIDR 匹配
		if strings.Contains(item, "/") {
			_, ipNet, err := net.ParseCIDR(item)
			if err == nil && ipNet.Contains(clientIP) {
				return true
			}
			continue
		}

		// 精确匹配
		if item == ip {
			return true
		}
	}
	return false
}
