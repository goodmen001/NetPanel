import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { app } from 'electron';

/** 持久化配置的键值类型 */
export interface StoreData {
  /** 首选端口 */
  port: number;
  /** 数据目录 */
  dataDir: string;
  /** 是否已完成首次设置向导 */
  setupDone: boolean;
  /** 是否已显示过托盘提示 */
  trayHintShown: boolean;
  /** 是否开机自启 */
  autoLaunch: boolean;
  /** 窗口宽度 */
  windowWidth: number;
  /** 窗口高度 */
  windowHeight: number;
}

const DEFAULTS: StoreData = {
  port: 8080,
  dataDir: path.join(os.homedir(), '.netpanel'),
  setupDone: false,
  trayHintShown: false,
  autoLaunch: false,
  windowWidth: 1280,
  windowHeight: 800,
};

/**
 * 简单的 JSON 文件持久化存储
 * 避免引入额外依赖（electron-store 等）
 */
export class StoreManager {
  private filePath: string;
  private data: StoreData;

  constructor() {
    const userDataPath = app.getPath('userData');
    this.filePath = path.join(userDataPath, 'config.json');
    this.data = this.load();
  }

  private load(): StoreData {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf-8');
        return { ...DEFAULTS, ...JSON.parse(raw) };
      }
    } catch (_) {}
    return { ...DEFAULTS };
  }

  private save(): void {
    try {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2), 'utf-8');
    } catch (err) {
      console.error('[Store] 保存配置失败:', err);
    }
  }

  get<K extends keyof StoreData>(key: K): StoreData[K] {
    return this.data[key];
  }

  set<K extends keyof StoreData>(key: K, value: StoreData[K]): void {
    this.data[key] = value;
    this.save();
  }

  setMany(partial: Partial<StoreData>): void {
    Object.assign(this.data, partial);
    this.save();
  }

  getAll(): StoreData {
    return { ...this.data };
  }
}
