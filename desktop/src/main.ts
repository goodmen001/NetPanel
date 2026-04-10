import {
  app,
  BrowserWindow,
  Menu,
  MenuItem,
  MenuItemConstructorOptions,
  nativeImage,
  Notification,
  shell,
  Tray,
  ipcMain,
  dialog,
} from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';
import { autoUpdater } from 'electron-updater';
import { BackendManager, BackendStatus } from './backend';
import { StoreManager } from './store';

// ─── 单实例锁 ──────────────────────────────────────────────────────────────────
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
  process.exit(0);
}

// ─── 全局变量 ──────────────────────────────────────────────────────────────────
let mainWindow: BrowserWindow | null = null;
let tray: Tray | null = null;
let backendMgr: BackendManager;
let store: StoreManager;
let isQuitting = false;
let currentPort = 8080;

// ─── 获取图标路径 ──────────────────────────────────────────────────────────────
function getIconPath(name: string = 'icon'): string {
  const ext = process.platform === 'win32' ? 'ico'
    : process.platform === 'darwin' ? 'icns'
    : 'png';
  const candidates = [
    path.join(process.resourcesPath ?? '', `${name}.${ext}`),
    path.join(__dirname, '..', 'assets', `${name}.${ext}`),
    path.join(__dirname, '..', 'assets', `${name}.png`),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return candidates[candidates.length - 1];
}

// ─── 获取托盘图标（带状态指示）────────────────────────────────────────────────
function getTrayIcon(status: BackendStatus): Electron.NativeImage {
  const iconName = status === 'running' ? 'tray-active'
    : status === 'error'   ? 'tray-error'
    : status === 'starting' ? 'tray-starting'
    : 'tray-inactive';

  const iconPath = getIconPath(iconName);
  if (fs.existsSync(iconPath)) {
    return nativeImage.createFromPath(iconPath);
  }
  // 回退到主图标
  return nativeImage.createFromPath(getIconPath('icon'));
}

// ─── 创建主窗口 ────────────────────────────────────────────────────────────────
function createMainWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    title: 'NetPanel',
    icon: getIconPath('icon'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false, // 等待后端就绪后再显示
    backgroundColor: '#1a1a2e',
  });

  // 关闭窗口时最小化到托盘，而非退出
  win.on('close', (e) => {
    if (!isQuitting) {
      e.preventDefault();
      win.hide();
      // 首次最小化时提示用户
      if (!store.get('trayHintShown')) {
        showNotification('NetPanel 已最小化到托盘', '点击托盘图标可重新打开管理界面');
        store.set('trayHintShown', true);
      }
    }
  });

  win.on('ready-to-show', () => {
    win.show();
    win.focus();
  });

  // 拦截外部链接，用系统浏览器打开
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  return win;
}

// ─── 加载后端 Web 界面 ─────────────────────────────────────────────────────────
function loadBackendUI(win: BrowserWindow, port: number): void {
  const url = `http://127.0.0.1:${port}`;
  win.loadURL(url).catch(() => {
    // 加载失败时显示错误页
    win.loadURL(`data:text/html,<h2>无法连接到 NetPanel 服务 (${url})</h2><p>请检查服务是否正常运行。</p>`);
  });
}

// ─── 创建系统托盘 ──────────────────────────────────────────────────────────────
function createTray(): Tray {
  const t = new Tray(getTrayIcon('stopped'));
  t.setToolTip('NetPanel');
  updateTrayMenu(t, 'stopped');

  t.on('click', () => {
    if (mainWindow) {
      if (mainWindow.isVisible()) {
        mainWindow.focus();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    }
  });

  return t;
}

// ─── 更新托盘菜单（含状态指示）────────────────────────────────────────────────
function updateTrayMenu(t: Tray, status: BackendStatus, activeConns?: number): void {
  const statusLabel = status === 'running'  ? `✅ 运行中 (端口 ${currentPort})`
    : status === 'starting' ? '⏳ 启动中...'
    : status === 'error'    ? '❌ 服务异常'
    : '⏹ 已停止';

  const connLabel = activeConns !== undefined ? `活跃连接: ${activeConns}` : '';

  const template: (MenuItemConstructorOptions | MenuItem)[] = [
    { label: 'NetPanel', enabled: false },
    { label: statusLabel, enabled: false },
    ...(connLabel ? [{ label: connLabel, enabled: false } as MenuItemConstructorOptions] : []),
    { type: 'separator' },
    {
      label: '打开管理界面',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      },
    },
    {
      label: '在浏览器中打开',
      enabled: status === 'running',
      click: () => shell.openExternal(`http://127.0.0.1:${currentPort}`),
    },
    { type: 'separator' },
    {
      label: '重启服务',
      enabled: status !== 'starting',
      click: async () => {
        try {
          currentPort = await backendMgr.restart();
          loadBackendUI(mainWindow!, currentPort);
        } catch (err) {
          showNotification('重启失败', String(err), 'error');
        }
      },
    },
    { type: 'separator' },
    {
      label: '退出 NetPanel',
      click: () => quitApp(),
    },
  ];

  t.setContextMenu(Menu.buildFromTemplate(template));
  t.setImage(getTrayIcon(status));
  t.setToolTip(
    status === 'running'
      ? `NetPanel - 运行中 (端口 ${currentPort})`
      : `NetPanel - ${statusLabel}`
  );
}

// ─── 发送系统通知 ──────────────────────────────────────────────────────────────
function showNotification(title: string, body: string, urgency: 'normal' | 'error' = 'normal'): void {
  if (!Notification.isSupported()) return;
  new Notification({
    title,
    body,
    icon: getIconPath(urgency === 'error' ? 'tray-error' : 'icon'),
    urgency: urgency === 'error' ? 'critical' : 'normal',
  }).show();
}

// ─── 优雅退出 ──────────────────────────────────────────────────────────────────
async function quitApp(): Promise<void> {
  isQuitting = true;
  if (tray) {
    tray.setToolTip('NetPanel - 正在退出...');
  }
  try {
    await backendMgr.stop();
  } catch (_) {}
  app.quit();
}

// ─── 自动更新 ──────────────────────────────────────────────────────────────────
function setupAutoUpdater(): void {
  autoUpdater.autoDownload = false;
  autoUpdater.autoInstallOnAppQuit = true;

  autoUpdater.on('update-available', (info) => {
    dialog.showMessageBox(mainWindow!, {
      type: 'info',
      title: '发现新版本',
      message: `NetPanel ${info.version} 已发布`,
      detail: '是否立即下载更新？下载完成后将在下次退出时自动安装。',
      buttons: ['立即下载', '稍后提醒'],
      defaultId: 0,
    }).then(({ response }) => {
      if (response === 0) {
        autoUpdater.downloadUpdate();
        showNotification('正在下载更新', `NetPanel ${info.version} 下载中...`);
      }
    });
  });

  autoUpdater.on('update-downloaded', (info) => {
    dialog.showMessageBox(mainWindow!, {
      type: 'info',
      title: '更新已就绪',
      message: `NetPanel ${info.version} 已下载完成`,
      detail: '点击"立即重启"以完成更新安装。',
      buttons: ['立即重启', '稍后安装'],
      defaultId: 0,
    }).then(({ response }) => {
      if (response === 0) {
        isQuitting = true;
        autoUpdater.quitAndInstall();
      }
    });
  });

  autoUpdater.on('error', (err) => {
    console.error('[更新] 检查更新失败:', err.message);
  });

  // 启动后 10s 检查更新，避免影响启动速度
  setTimeout(() => {
    autoUpdater.checkForUpdates().catch(() => {});
  }, 10000);
}

// ─── IPC 处理 ──────────────────────────────────────────────────────────────────
function setupIPC(): void {
  // 渲染进程查询后端状态
  ipcMain.handle('backend:status', () => ({
    status: backendMgr.getStatus(),
    port: backendMgr.getPort(),
    isExternal: backendMgr.isExternal(),
  }));

  // 渲染进程请求重启后端
  ipcMain.handle('backend:restart', async () => {
    try {
      currentPort = await backendMgr.restart();
      return { success: true, port: currentPort };
    } catch (err) {
      return { success: false, error: String(err) };
    }
  });

  // 渲染进程请求退出
  ipcMain.handle('app:quit', () => quitApp());

  // 渲染进程请求打开外部链接
  ipcMain.handle('app:openExternal', (_e, url: string) => shell.openExternal(url));

  // 首次设置向导保存配置
  ipcMain.handle('setup:save', async (_e, config: {
    port: number;
    dataDir: string;
    autoLaunch: boolean;
  }) => {
    store.setMany({
      port: config.port || 8080,
      dataDir: config.dataDir || require('path').join(require('os').homedir(), '.netpanel'),
      autoLaunch: config.autoLaunch,
      setupDone: true,
    });

    // 设置开机自启
    app.setLoginItemSettings({ openAtLogin: config.autoLaunch });

    // 重新初始化后端管理器（使用新配置）
    await backendMgr.stop();
    backendMgr = new BackendManager({
      preferredPort: config.port || 8080,
      dataDir: config.dataDir || require('path').join(require('os').homedir(), '.netpanel'),
      maxRestarts: 5,
      restartCooldown: 3000,
    });
    backendMgr.on('status', (status: BackendStatus) => {
      if (tray) updateTrayMenu(tray, status);
      mainWindow?.webContents.send('backend:statusUpdate', status);
    });
    backendMgr.on('ready', (port: number) => {
      currentPort = port;
      if (mainWindow) loadBackendUI(mainWindow, port);
      if (tray) updateTrayMenu(tray, 'running');
    });
    backendMgr.on('crashed', (code) => {
      showNotification('NetPanel 服务异常', `后端服务意外退出（退出码: ${code}），正在自动重启...`, 'error');
      if (tray) updateTrayMenu(tray, 'error');
    });

    await startBackend();
    return { success: true };
  });
}

// ─── 应用启动流程 ──────────────────────────────────────────────────────────────
app.whenReady().then(async () => {
  // 初始化持久化存储
  store = new StoreManager();

  // 初始化后端管理器
  backendMgr = new BackendManager({
    preferredPort: store.get('port') ?? 8080,
    dataDir: store.get('dataDir') ?? path.join(os.homedir(), '.netpanel'),
    maxRestarts: 5,
    restartCooldown: 3000,
  });

  // 监听后端状态变更，更新托盘
  backendMgr.on('status', (status: BackendStatus) => {
    if (tray) updateTrayMenu(tray, status);
  });

  // 后端就绪后加载 Web 界面
  backendMgr.on('ready', (port: number) => {
    currentPort = port;
    if (mainWindow) {
      loadBackendUI(mainWindow, port);
    }
    if (tray) updateTrayMenu(tray, 'running');
  });

  // 后端崩溃通知
  backendMgr.on('crashed', (code) => {
    showNotification(
      'NetPanel 服务异常',
      `后端服务意外退出（退出码: ${code}），正在自动重启...`,
      'error'
    );
    if (tray) updateTrayMenu(tray, 'error');
  });

  // 创建托盘（先于窗口，确保托盘始终可见）
  tray = createTray();

  // 创建主窗口
  mainWindow = createMainWindow();

  // 注册 IPC
  setupIPC();

  // 检查是否首次启动，显示引导向导
  if (!store.get('setupDone')) {
    // 首次启动：先显示窗口，再启动后端（引导向导在渲染进程中处理）
    mainWindow.loadFile(path.join(__dirname, '..', 'assets', 'setup.html')).catch(() => {
      // 若引导页不存在，直接启动后端
      startBackend();
    });
  } else {
    startBackend();
  }

  // 自动更新（仅打包后启用）
  if (app.isPackaged) {
    setupAutoUpdater();
  }

  // macOS：点击 Dock 图标时重新显示窗口
  app.on('activate', () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
});

// ─── 启动后端 ──────────────────────────────────────────────────────────────────
async function startBackend(): Promise<void> {
  try {
    currentPort = await backendMgr.start();
  } catch (err) {
    showNotification('启动失败', `NetPanel 后端服务启动失败: ${err}`, 'error');
    if (mainWindow) {
      mainWindow.loadURL(
        `data:text/html,<h2 style="font-family:sans-serif;color:#e74c3c">启动失败</h2>` +
        `<p style="font-family:sans-serif">${err}</p>` +
        `<button onclick="window.location.reload()">重试</button>`
      );
      mainWindow.show();
    }
  }
}

// ─── 第二个实例启动时，聚焦已有窗口 ──────────────────────────────────────────
app.on('second-instance', () => {
  if (mainWindow) {
    if (!mainWindow.isVisible()) mainWindow.show();
    mainWindow.focus();
  }
});

// ─── 所有窗口关闭时不退出（托盘模式）─────────────────────────────────────────
app.on('window-all-closed', (e: Event) => {
  // 阻止默认退出行为，保持托盘运行
  e.preventDefault();
});

// ─── 应用退出前清理 ────────────────────────────────────────────────────────────
app.on('before-quit', async (e) => {
  if (!isQuitting) {
    e.preventDefault();
    await quitApp();
  }
});
