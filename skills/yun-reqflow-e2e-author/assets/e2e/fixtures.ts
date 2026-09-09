import { test as base } from '@playwright/test';
import type { PlayWrightAiFixtureType } from '@midscene/web/playwright';
import { PlaywrightAiFixture } from '@midscene/web/playwright';
import config from './midscene.config';
import { attachApiRecorder } from './helpers/api-recorder';

type ApiRecorderFixture = {
  /** 接口录制器（auto：每条用例自动启停） */
  apiRecorder: ReturnType<typeof attachApiRecorder>;
};

const midsceneTest = base.extend<PlayWrightAiFixtureType>(
  PlaywrightAiFixture({
    waitForNetworkIdleTimeout: config.midscene.waitForNetworkIdleTimeout,
  })
);

/**
 * Midscene + 接口录制。
 * 换项目时一般不用改；录制范围改 midscene.config.ts → apiRecorder。
 */
export const test = midsceneTest.extend<ApiRecorderFixture>({
  apiRecorder: [
    async ({ page }, use, testInfo) => {
      const recorder = attachApiRecorder(page, config.apiRecorder);
      try {
        await use(recorder);
      } finally {
        // 用例通过/失败/超时都会执行，保证接口记录落盘
        await recorder.flush(testInfo);
      }
    },
    { auto: true },
  ],
});

export { expect } from '@playwright/test';
