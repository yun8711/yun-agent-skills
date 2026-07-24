import fs from 'fs';
import path from 'path';
import { test } from '@playwright/test';
import config from '../midscene.config';
import { getStorageStatePath } from '../helpers/auth';

/**
 * 对齐日常开发登录：
 * 线上登录 → 复制 localStorage/sessionStorage → 贴到本窗口本地页 → Inspector 点 Resume 保存。
 *
 * 运行：pnpm test:e2e:save-auth
 * （不要用普通 test:e2e 跑本文件）
 */
test.use({
  // 保存前不要带上旧快照
  storageState: { cookies: [], origins: [] },
});

test('手动粘贴 Storage 并保存登录态', async ({ page, context }) => {
  const outPath = getStorageStatePath();
  fs.mkdirSync(path.dirname(outPath), { recursive: true });

  await page.goto(config.baseURL);
  await page.waitForLoadState('domcontentloaded');

  // eslint-disable-next-line no-console
  console.log(`
[e2e:save-auth] 已打开 ${config.baseURL}
请按日常方式：
  1. 在线上已登录页复制 localStorage / sessionStorage
  2. 粘贴到当前 Playwright 打开的本地页
  3. 刷新确认能访问业务数据
  4. 在 Playwright Inspector 点击 Resume（继续）
`);

  await page.pause();
  await context.storageState({ path: outPath });
  // eslint-disable-next-line no-console
  console.log('[e2e:save-auth] 已保存', outPath);
});
