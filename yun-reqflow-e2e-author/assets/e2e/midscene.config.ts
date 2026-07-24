import dotenv from 'dotenv';
import path from 'path';
import { loadModelEnvFromCodex } from './load-model-env';
import { resolveAppPrefix, resolveBaseURL } from './resolve-base-url';

dotenv.config({ path: path.resolve(__dirname, '../.env.e2e') });
loadModelEnvFromCodex();

/**
 * 项目级配置（换项目主要改本文件 + .env.e2e）
 * 登录：/ → /login → /card → {appPrefix}#/...
 * appPrefix：vue.custom.js.name → /{name}，或 E2E_APP_PREFIX；宿主端口：E2E_HOST_PORT 默认 8001
 */
export type E2EAuthMode = 'ui' | 'none' | 'storage' | 'manual';

export interface E2EProjectConfig {
  baseURL: string;
  viewport: { width: number; height: number };
  auth: {
    mode: E2EAuthMode;
    storage?: Record<string, string>;
  };
  routes: {
    card: string;
    /** 子应用 activeRule */
    appPrefix: string;
    /** @deprecated 同 appPrefix */
    daasPrefix: string;
    home: string;
    /** 按业务在 author 阶段追加，如 certificate: '/application/certificate' */
    [key: string]: string;
  };
  midscene: {
    waitForNetworkIdleTimeout: number;
  };
  apiRecorder: {
    enabled: boolean;
    include: string[];
    captureBody: boolean;
  };
}

const appPrefix = resolveAppPrefix();

const config: E2EProjectConfig = {
  baseURL: resolveBaseURL({ entry: (process.env.E2E_ENTRY as 'host' | 'standalone') || 'host' }),
  viewport: { width: 1440, height: 900 },
  auth: {
    mode: (process.env.E2E_AUTH_MODE as E2EAuthMode) || 'ui',
    storage: {
      tenantId: process.env.E2E_TENANT_ID || '',
      token: process.env.E2E_TOKEN || '',
    },
  },
  routes: {
    home: '/',
    card: '/card',
    appPrefix,
    daasPrefix: appPrefix,
  },
  midscene: {
    waitForNetworkIdleTimeout: 2000,
  },
  apiRecorder: {
    enabled: process.env.E2E_API_RECORD !== '0',
    include: [appPrefix, '/gaea', '/api/', '/login'],
    captureBody: process.env.E2E_API_RECORD_BODY === '1',
  },
};

export default config;
