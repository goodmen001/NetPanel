import { ChildProcess, spawn } from 'child_process';
import { EventEmitter } from 'events';
import * as fs from 'fs';
import * as http from 'http';
import * as net from 'net';
import * as path from 'path';
import * as os from 'os';

/** 后端进程状态 */
export type BackendStatus = 'stopped' | 'starting' | 'running' | 'error';

/** 后端管理器事件 */
export interface BackendEvents {
  /** 状态变更 */
  status: (status: BackendStatus) => void;
  /** 后端已就绪（HTTP 可访问） */
  ready: (port: number) => void;
  /** 后端异常退出 */
  crashed: (code: number | null) => void;
  /** 日志输出 */
  log: (line: string) => void;
}

/** 后端管理器配置 */
export interface BackendConfig {
  /** 首选端口，被占用时自动寻找可用端口 */
  preferredPort: number;
  /** 数据目录 */
  dataDir: string;
  /** 最大自动重启次数（0 = 不限制） */
  maxRestarts: number;
  /** 重启冷却时间（毫秒） */
  restartCooldown: number;
}

const DEFAULT_CONFIG: BackendConfig = {
  preferredPort: 8080,
  dataDir: path.join(os.homedir(), '.netpanel'),
  maxRestarts: 5,
  restartCooldown: 3000,
};

/**
 * NetPanel 后端进程管理器
 *
 * 负责：
 * - 定位内嵌的 netpanel 二进制文件
 * - 检测端口占用，自动选择可用端口
 * - 检测系统是否已有 NetPanel 服务在运行
 * - 启动/停止后端进程
 * - 异常退出时自动重启（带重试次数限制）
 */
export class BackendManager extends EventEmitter {
  private process: ChildProcess | null = null;
  private status: BackendStatus = 'stopped';
  private port: number = 0;
  private config: BackendConfig;
  private restartCount: number = 0;
  private restartTimer: NodeJS.Timeout | null = null;
  /** 是否连接到外部已有服务（不由本进程管理） */
  private isExternalService: boolean = false;

  constructor(config: Partial<BackendConfig> = {}) {
    super();
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /** 获取当前端口 */
  getPort(): number {
    return this.port;
  }

  /** 获取当前状态 */
  getStatus(): BackendStatus {
    return this.status;
  }

  /** 是否为外部已有服务 */
  isExternal(): boolean {
    return this.isExternalService;
  }

  /**
   * 定位内嵌的 netpanel 二进制文件路径
   * 打包后位于 resources/ 目录，开发时位于 ../dist/
   */
  private getBinaryPath(): string {
    const binaryName = process.platform === 'win32' ? 'netpanel.exe' : 'netpanel';

    // 打包后：Electron 的 resourcesPath
    const packedPath = path.join(process.resourcesPath ?? '', binaryName);
    if (fs.existsSync(packedPath)) {
      return packedPath;
    }

    // 开发时：项目根目录的 dist/
    const devPath = path.join(__dirname, '..', '..', 'dist', binaryName);
    if (fs.existsSync(devPath)) {
      return devPath;
    }

    // 回退：当前目录
    return path.join(process.cwd(), binaryName);
  }

  /**
   * 检测指定端口是否可用
   */
  private isPortAvailable(port: number): Promise<boolean> {
    return new Promise((resolve) => {
      const server = net.createServer();
      server.once('error', () => resolve(false));
      server.once('listening', () => {
        server.close(() => resolve(true));
      });
      server.listen(port, '127.0.0.1');
    });
  }

  /**
   * 在 preferredPort ~ preferredPort+100 范围内寻找可用端口
   */
  private async findAvailablePort(preferred: number): Promise<number> {
    for (let p = preferred; p <= preferred + 100; p++) {
      if (await this.isPortAvailable(p)) {
        return p;
      }
    }
    throw new Error(`无法在 ${preferred}~${preferred + 100} 范围内找到可用端口`);
  }

  /**
   * 检测指定端口是否有 NetPanel HTTP 服务在运行
   */
  private checkNetPanelRunning(port: number): Promise<boolean> {
    return new Promise((resolve) => {
      const req = http.get(
        { hostname: '127.0.0.1', port, path: '/api/ping', timeout: 2000 },
        (res) => {
          resolve(res.statusCode !== undefined);
          res.resume();
        }
      );
      req.on('error', () => resolve(false));
      req.on('timeout', () => {
        req.destroy();
        resolve(false);
      });
    });
  }

  /**
   * 检测系统是否已有 NetPanel 服务在运行。
   * 若已有服务，直接连接而不重复启动。
   * @returns 已有服务的端口，或 null
   */
  async detectExistingService(): Promise<number | null> {
    // 检测常用端口范围
    const portsToCheck = [
      this.config.preferredPort,
      8080, 8081, 8082, 8090, 9090,
    ];
    for (const port of [...new Set(portsToCheck)]) {
      if (await this.checkNetPanelRunning(port)) {
        return port;
      }
    }
    return null;
  }

  /**
   * 启动后端服务。
   * 若系统已有 NetPanel 服务在运行，直接连接而不重复启动。
   */
  async start(): Promise<number> {
    if (this.status === 'running' || this.status === 'starting') {
      return this.port;
    }

    this.setStatus('starting');

    // 1. 检测是否已有外部服务
    const existingPort = await this.detectExistingService();
    if (existingPort !== null) {
      this.port = existingPort;
      this.isExternalService = true;
      this.setStatus('running');
      this.emit('ready', this.port);
      this.emit('log', `[后端] 检测到已有 NetPanel 服务运行于端口 ${existingPort}，直接连接`);
      return this.port;
    }

    // 2. 寻找可用端口
    this.port = await this.findAvailablePort(this.config.preferredPort);
    this.isExternalService = false;

    // 3. 确保数据目录存在
    fs.mkdirSync(this.config.dataDir, { recursive: true });

    // 4. 启动进程
    await this.spawnProcess();
    return this.port;
  }

  /**
   * 启动 netpanel 子进程
   */
  private spawnProcess(): Promise<void> {
    return new Promise((resolve, reject) => {
      const binaryPath = this.getBinaryPath();

      if (!fs.existsSync(binaryPath)) {
        const err = new Error(`未找到 netpanel 二进制文件: ${binaryPath}`);
        this.setStatus('error');
        reject(err);
        return;
      }

      const args = [
        '--port', String(this.port),
        '--data', this.config.dataDir,
      ];

      this.emit('log', `[后端] 启动: ${binaryPath} ${args.join(' ')}`);

      this.process = spawn(binaryPath, args, {
        stdio: ['ignore', 'pipe', 'pipe'],
        detached: false,
      });

      // 收集日志
      this.process.stdout?.on('data', (data: Buffer) => {
        const lines = data.toString().split('\n').filter(Boolean);
        lines.forEach((line) => this.emit('log', `[后端] ${line}`));
      });
      this.process.stderr?.on('data', (data: Buffer) => {
        const lines = data.toString().split('\n').filter(Boolean);
        lines.forEach((line) => this.emit('log', `[后端][ERR] ${line}`));
      });

      // 等待服务就绪（轮询 HTTP）
      const startTime = Date.now();
      const pollReady = setInterval(async () => {
        if (await this.checkNetPanelRunning(this.port)) {
          clearInterval(pollReady);
          this.setStatus('running');
          this.emit('ready', this.port);
          resolve();
        } else if (Date.now() - startTime > 15000) {
          clearInterval(pollReady);
          reject(new Error('后端服务启动超时（15s）'));
        }
      }, 500);

      // 进程退出处理
      this.process.on('exit', (code) => {
        clearInterval(pollReady);
        this.process = null;
        this.emit('log', `[后端] 进程退出，退出码: ${code}`);

        if (this.status === 'running') {
          // 异常退出，触发自动重启
          this.setStatus('error');
          this.emit('crashed', code);
          this.scheduleRestart();
        } else {
          this.setStatus('stopped');
        }
      });

      this.process.on('error', (err) => {
        clearInterval(pollReady);
        this.setStatus('error');
        this.emit('log', `[后端] 进程错误: ${err.message}`);
        reject(err);
      });
    });
  }

  /**
   * 安排自动重启（带重试次数限制和冷却时间）
   */
  private scheduleRestart(): void {
    if (this.config.maxRestarts > 0 && this.restartCount >= this.config.maxRestarts) {
      this.emit('log', `[后端] 已达最大重启次数 (${this.config.maxRestarts})，停止自动重启`);
      return;
    }

    this.restartCount++;
    this.emit('log', `[后端] ${this.config.restartCooldown / 1000}s 后自动重启（第 ${this.restartCount} 次）...`);

    this.restartTimer = setTimeout(async () => {
      try {
        await this.spawnProcess();
      } catch (err) {
        this.emit('log', `[后端] 重启失败: ${err}`);
        this.scheduleRestart();
      }
    }, this.config.restartCooldown);
  }

  /**
   * 停止后端服务
   */
  async stop(): Promise<void> {
    if (this.restartTimer) {
      clearTimeout(this.restartTimer);
      this.restartTimer = null;
    }

    if (this.isExternalService) {
      // 外部服务不由本进程管理，直接标记停止
      this.isExternalService = false;
      this.setStatus('stopped');
      return;
    }

    if (!this.process) {
      this.setStatus('stopped');
      return;
    }

    return new Promise((resolve) => {
      const proc = this.process!;
      const timeout = setTimeout(() => {
        proc.kill('SIGKILL');
        resolve();
      }, 5000);

      proc.once('exit', () => {
        clearTimeout(timeout);
        this.setStatus('stopped');
        resolve();
      });

      // 优雅停止
      proc.kill('SIGTERM');
    });
  }

  /**
   * 重启后端服务
   */
  async restart(): Promise<number> {
    await this.stop();
    this.restartCount = 0;
    return this.start();
  }

  private setStatus(s: BackendStatus): void {
    this.status = s;
    this.emit('status', s);
  }
}
