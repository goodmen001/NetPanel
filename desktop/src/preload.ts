import { contextBridge, ipcRenderer } from 'electron';

/**
 * 预加载脚本：通过 contextBridge 向渲染进程暴露安全的 API
 * 渲染进程通过 window.netpanel.xxx 调用
 */
contextBridge.exposeInMainWorld('netpanel', {
  /** 查询后端状态 */
  getBackendStatus: () => ipcRenderer.invoke('backend:status'),

  /** 重启后端服务 */
  restartBackend: () => ipcRenderer.invoke('backend:restart'),

  /** 退出应用 */
  quit: () => ipcRenderer.invoke('app:quit'),

  /** 用系统浏览器打开外部链接 */
  openExternal: (url: string) => ipcRenderer.invoke('app:openExternal', url),

  /** 保存首次设置向导结果 */
  saveSetup: (config: {
    port: number;
    dataDir: string;
    autoLaunch: boolean;
  }) => ipcRenderer.invoke('setup:save', config),

  /** 监听后端状态变更推送 */
  onBackendStatus: (callback: (status: string) => void) => {
    ipcRenderer.on('backend:statusUpdate', (_e, status) => callback(status));
    return () => ipcRenderer.removeAllListeners('backend:statusUpdate');
  },
});
