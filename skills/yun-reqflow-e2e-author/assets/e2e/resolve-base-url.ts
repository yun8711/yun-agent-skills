import fs from 'fs';
import path from 'path';

export type E2EEntry = 'host' | 'standalone';

export interface VueCustomMeta {
  name?: string;
  port?: string;
  publicPath?: string;
}

export interface ResolveBaseURLOptions {
  /** 项目根目录（含 vue.custom.js）；默认 e2e 的上一级 = 当前子应用 */
  projectRoot?: string;
  /** host | standalone；默认 host（走主应用登录） */
  entry?: E2EEntry;
  overrideURL?: string;
  host?: string;
}

/**
 * 解析 Playwright baseURL。
 * - host（默认）：E2E_HOST + E2E_HOST_PORT（默认 localhost:8001）
 * - standalone：本仓 vue.custom.js 的 port + publicPath
 * 覆盖：E2E_BASE_URL
 */
export function resolveBaseURL(options: ResolveBaseURLOptions = {}): string {
  const override = options.overrideURL || process.env.E2E_BASE_URL;
  if (override) return override.replace(/\/$/, '');

  const projectRoot = options.projectRoot || path.resolve(__dirname, '..');
  const host = options.host || process.env.E2E_HOST || 'localhost';
  const entry = (options.entry || process.env.E2E_ENTRY || 'host') as E2EEntry;

  if (entry === 'standalone') {
    const meta = readVueCustom(projectRoot);
    const port = meta?.port || '8066';
    const publicPath = normalizePublicPath(meta?.publicPath);
    return `http://${host}:${port}${publicPath}`.replace(/\/$/, '') || `http://${host}:${port}`;
  }

  const hostPort = process.env.E2E_HOST_PORT || '8001';
  return `http://${host}:${hostPort}`;
}

/**
 * 子应用 activeRule：E2E_APP_PREFIX → `/${vue.custom.js.name}`
 */
export function resolveAppPrefix(projectRoot?: string): string {
  const override = process.env.E2E_APP_PREFIX;
  if (override) {
    return override.startsWith('/') ? override : `/${override}`;
  }
  const root = projectRoot || path.resolve(__dirname, '..');
  const name = readVueCustom(root)?.name;
  if (name) return `/${name.replace(/^\//, '')}`;
  console.warn('[e2e] 无法推导 appPrefix：请配置 vue.custom.js.name 或 E2E_APP_PREFIX');
  return '/';
}

function normalizePublicPath(publicPath?: string): string {
  if (!publicPath || publicPath === '/') return '';
  return publicPath.endsWith('/') ? publicPath.slice(0, -1) : publicPath;
}

export function readVueCustom(projectRoot: string): VueCustomMeta | undefined {
  const filePath = path.join(projectRoot, 'vue.custom.js');
  if (!fs.existsSync(filePath)) {
    console.warn(`[e2e] 未找到 ${filePath}`);
    return undefined;
  }
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const mod = require(filePath) as {
      name?: string;
      port?: string | number;
      publicPath?: string;
    };
    return {
      name: mod?.name,
      port: mod?.port != null && mod.port !== '' ? String(mod.port) : undefined,
      publicPath: mod?.publicPath,
    };
  } catch (err) {
    console.warn('[e2e] 读取 vue.custom.js 失败', err);
    return undefined;
  }
}
