import fs from 'fs';
import { defineConfig, devices } from '@playwright/test';
import dotenv from 'dotenv';
import path from 'path';
import { loadModelEnvFromCodex } from './e2e/load-model-env';

dotenv.config({ path: path.resolve(__dirname, '.env.e2e') });
loadModelEnvFromCodex();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const config = require('./e2e/midscene.config').default as {
  baseURL: string;
  auth: { mode: string };
};

const storageStatePath = path.resolve(__dirname, 'e2e/.auth/storage-state.json');
// ui/manual：有快照则注入，loginViaHost 内会再探测是否仍有效，失效则重新登录
const useStorageState =
  process.env.E2E_FORCE_LOGIN !== '1' &&
  ['ui', 'manual'].includes(config.auth.mode) &&
  fs.existsSync(storageStatePath)
    ? storageStatePath
    : undefined;

const headed =
  process.env.CI !== 'true' &&
  process.env.E2E_HEADLESS !== '1' &&
  process.env.E2E_HEADED !== '0';
const slowMo = Number(process.env.E2E_SLOW_MO || (headed ? 300 : 0)) || 0;

/**
 * Playwright 入口配置。
 * 本地默认有界面（headed）；CI 或 E2E_HEADLESS=1 时后台无头跑。
 */
export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.spec.ts',
  timeout: 10 * 60 * 1000,
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    [process.env.CI ? 'line' : 'list'],
    ['@midscene/web/playwright-reporter', { type: 'merged' }],
  ],
  use: {
    baseURL: config.baseURL,
    storageState: useStorageState,
    headless: !headed,
    launchOptions: {
      slowMo,
    },
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'off',
    ...devices['Desktop Chrome'],
    channel: 'chrome',
  },
  projects: [
    {
      name: 'chrome',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
      },
    },
  ],
});
