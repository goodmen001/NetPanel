/**
 * electron-builder 多平台打包配置
 *
 * 构建前需将对应平台的 netpanel 二进制放入 resources/ 目录：
 *   resources/netpanel.exe        (Windows)
 *   resources/netpanel            (macOS / Linux)
 *
 * 用法：
 *   npm run dist:win    - 构建 Windows NSIS 安装包
 *   npm run dist:mac    - 构建 macOS DMG
 *   npm run dist:linux  - 构建 Linux AppImage
 *   npm run dist:all    - 构建全平台
 */

const { version } = require('./package.json');

/** @type {import('electron-builder').Configuration} */
module.exports = {
  // ─── 基本信息 ────────────────────────────────────────────────────────────────
  appId: 'com.netpanel.desktop',
  productName: 'NetPanel',
  copyright: `Copyright © ${new Date().getFullYear()} NetPanel Team`,

  // ─── 构建输出 ────────────────────────────────────────────────────────────────
  directories: {
    output: '../dist/electron',
    buildResources: 'assets',
  },

  // ─── 打包文件 ────────────────────────────────────────────────────────────────
  files: [
    'dist/**/*',        // 编译后的 JS
    'assets/**/*',      // 图标、HTML 等静态资源
    'package.json',
  ],

  // ─── 额外资源（netpanel 二进制，打包后位于 resources/ 目录）────────────────
  extraResources: [
    {
      // Windows：netpanel.exe
      from: 'resources/netpanel.exe',
      to: 'netpanel.exe',
      filter: ['**/*'],
    },
    {
      // macOS / Linux：netpanel
      from: 'resources/netpanel',
      to: 'netpanel',
      filter: ['**/*'],
    },
  ],

  // ─── 自动更新配置 ────────────────────────────────────────────────────────────
  publish: [
    {
      provider: 'github',
      owner: 'YOUR_ORG',    // TODO: 替换为实际 GitHub 组织/用户名
      repo: 'netpanel',
      releaseType: 'prerelease',
    },
  ],

  // ─── Windows 平台：NSIS 安装包 ───────────────────────────────────────────────
  win: {
    target: [
      { target: 'nsis', arch: ['x64'] },
      { target: 'zip',  arch: ['x64'] },   // 便携版
    ],
    icon: 'assets/icon.ico',
    // 请求管理员权限（注册服务需要）
    requestedExecutionLevel: 'requireAdministrator',
    // 版本号从环境变量注入（CI/CD 使用）
    artifactName: 'NetPanel-Desktop-${version}-windows-${arch}.${ext}',
  },
  nsis: {
    oneClick: false,                  // 显示安装向导
    allowToChangeInstallationDirectory: true,
    createDesktopShortcut: true,
    createStartMenuShortcut: true,
    shortcutName: 'NetPanel',
    installerIcon: 'assets/icon.ico',
    uninstallerIcon: 'assets/icon.ico',
    installerHeaderIcon: 'assets/icon.ico',
    // 安装完成后启动应用
    runAfterFinish: true,
    // 中英文双语安装包
    language: '2052',                 // 简体中文
    // 安装/卸载时执行的脚本（停止服务）
    include: 'assets/nsis-extra.nsh',
  },

  // ─── macOS 平台：DMG 安装包 ──────────────────────────────────────────────────
  mac: {
    target: [
      { target: 'dmg', arch: ['x64', 'arm64'] },
      { target: 'zip', arch: ['x64', 'arm64'] },  // 便携版
    ],
    icon: 'assets/icon.icns',
    category: 'public.app-category.utilities',
    // 代码签名（CI 中通过环境变量注入证书）
    identity: process.env.APPLE_IDENTITY || null,
    hardenedRuntime: true,
    gatekeeperAssess: false,
    entitlements: 'assets/entitlements.mac.plist',
    entitlementsInherit: 'assets/entitlements.mac.plist',
    artifactName: 'NetPanel-Desktop-${version}-macos-${arch}.${ext}',
  },
  dmg: {
    title: 'NetPanel ${version}',
    icon: 'assets/icon.icns',
    contents: [
      { x: 130, y: 220, type: 'file' },
      { x: 410, y: 220, type: 'link', path: '/Applications' },
    ],
    window: { width: 540, height: 380 },
  },

  // ─── Linux 平台：AppImage ────────────────────────────────────────────────────
  linux: {
    target: [
      { target: 'AppImage', arch: ['x64', 'arm64'] },
      { target: 'tar.gz',   arch: ['x64', 'arm64'] },  // 便携版
    ],
    icon: 'assets/icon.png',
    category: 'Network',
    description: 'NetPanel 网络管理面板桌面版',
    // AppImage 无需安装，直接运行
    maintainer: 'NetPanel Team',
    artifactName: 'NetPanel-Desktop-${version}-linux-${arch}.${ext}',
  },
  appImage: {
    // AppImage 运行时自动解压，无需安装依赖
    systemIntegration: 'ask',
  },
};
