import fs from 'fs';
import path from 'path';
import type { Page } from '@playwright/test';
import config from '../midscene.config';

export function getStorageStatePath(): string {
  return (
    process.env.E2E_STORAGE_STATE_PATH ||
    path.resolve(__dirname, '../.auth/storage-state.json')
  );
}

export function hasStorageStateFile(): boolean {
  return fs.existsSync(getStorageStatePath());
}

type AiHelpers = {
  aiInput: (text: string, locate: string) => Promise<unknown>;
  aiTap: (locate: string) => Promise<unknown>;
  aiWaitFor: (assert: string, opt?: { timeoutMs?: number }) => Promise<unknown>;
  aiAssert?: (assert: string) => Promise<unknown>;
  aiAct?: (prompt: string) => Promise<unknown>;
};

/**
 * 主应用登录（完成标准：进入 /card）。
 *
 * - 已有有效登录态（storageState / 会话未过期）→ 跳过登录表单
 * - 否则自动登录（需 E2E_USERNAME / E2E_PASSWORD），成功后写入 e2e/.auth/storage-state.json
 * - E2E_FORCE_LOGIN=1 时强制重新登录
 */
export async function loginViaHost(page: Page, ai: AiHelpers) {
  const { baseURL, routes } = config;
  const cardPath = routes.card || '/card';
  const force = process.env.E2E_FORCE_LOGIN === '1';

  if (!force) {
    const ok = await tryReuseSession(page, cardPath);
    if (ok) {
      // eslint-disable-next-line no-console
      console.log('[e2e] 已登录，跳过登录步骤 →', page.url());
      return;
    }
  }

  const username = process.env.E2E_USERNAME || '';
  const password = process.env.E2E_PASSWORD || '';

  if (username && password) {
    await autoLogin(page, ai, { username, password, cardPath });
    await persistStorageState(page);
    return;
  }

  await page.goto('/login');
  await page.waitForLoadState('domcontentloaded');

  // eslint-disable-next-line no-console
  console.log(`
[e2e] 未配置 E2E_USERNAME / E2E_PASSWORD，且当前无有效登录态。
请手动：登录 → 进入 ${baseURL}${cardPath} → Inspector 点 Resume
当前: ${page.url()}
`);
  await page.pause();

  if (!isOnCard(page, cardPath)) {
    await page.goto(cardPath);
    await page.waitForLoadState('domcontentloaded');
  }
  await persistStorageState(page);
}

/** 探测是否已登录：能停在 /card 且不在 /login */
async function tryReuseSession(page: Page, cardPath: string): Promise<boolean> {
  await page.goto(cardPath);
  await page.waitForLoadState('domcontentloaded');
  // 等一下路由/鉴权跳转
  await page.waitForTimeout(800);

  if (isLoginPage(page)) return false;
  if (!isOnCard(page, cardPath)) return false;

  const flagged = await page.evaluate(() => {
    try {
      return localStorage.getItem('isLogin') === 'true' || !!localStorage.getItem('loginInfo');
    } catch {
      return false;
    }
  });

  // 有的环境不写 isLogin，但能停在 card 也视为已登录
  return flagged || isOnCard(page, cardPath);
}

async function autoLogin(
  page: Page,
  ai: AiHelpers,
  opts: { username: string; password: string; cardPath: string }
) {
  const { username, password, cardPath } = opts;

  await page.goto('/login');
  await page.waitForLoadState('domcontentloaded');

  if (isOnCard(page, cardPath) || page.url().includes('/card')) {
    return;
  }

  await ai.aiWaitFor('登录页出现「请输入账号」「请输入密码」输入框和「登 录」按钮', {
    timeoutMs: 30000,
  });

  await ai.aiInput(username, '账号输入框（placeholder 为「请输入账号」）');
  await ai.aiInput(password, '密码输入框（placeholder 为「请输入密码」）');

  if (ai.aiAct) {
    await ai.aiAct(
      '如果页面上有验证码输入框和右侧验证码图片，请识别图片中的验证码并填入验证码输入框；如果没有验证码则什么都不做'
    );
  }

  await ai.aiTap('主按钮「登 录」');

  await ai.aiWaitFor('登录成功并离开登录页（进入工作台/card，或出现应用入口）', {
    timeoutMs: 90000,
  });

  if (!isOnCard(page, cardPath)) {
    await page.goto(cardPath);
    await page.waitForLoadState('domcontentloaded');
  }

  await ai.aiWaitFor('已进入 card 工作台页面（卡片或九宫格入口可见）', {
    timeoutMs: 60000,
  });
}

async function persistStorageState(page: Page) {
  const outPath = getStorageStatePath();
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  await page.context().storageState({ path: outPath });
  // eslint-disable-next-line no-console
  console.log('[e2e] 已保存登录态', outPath);
}

/** 进入子应用某 hash 页（登录完成后调用） */
export async function gotoAppPage(page: Page, hashPath: string) {
  const pathPart = hashPath.startsWith('/') ? hashPath : `/${hashPath}`;
  const prefix = config.routes.appPrefix || config.routes.daasPrefix || '/';
  await page.goto(`${prefix}#${pathPart}`);
  await page.waitForLoadState('domcontentloaded');
}

/** @deprecated 使用 gotoAppPage */
export const gotoDaasPage = gotoAppPage;

function isOnCard(page: Page, cardPath: string): boolean {
  try {
    const u = new URL(page.url());
    return u.pathname === cardPath || u.pathname.startsWith(`${cardPath}/`);
  } catch {
    return page.url().includes(cardPath);
  }
}

function isLoginPage(page: Page): boolean {
  try {
    return new URL(page.url()).pathname.includes('/login');
  } catch {
    return page.url().includes('/login');
  }
}

export async function applyAuth(page: Page) {
  const { auth, baseURL } = config;
  if (auth.mode !== 'storage') return;

  const entries = Object.entries(auth.storage || {}).filter(([, v]) => v != null && v !== '');
  if (!entries.length) {
    console.warn('[e2e] auth.mode=storage 但未配置 storage 键值，跳过注入');
    return;
  }

  await page.goto(baseURL);
  await page.evaluate((pairs) => {
    pairs.forEach(([key, value]) => {
      localStorage.setItem(key, value);
    });
  }, entries);
}
