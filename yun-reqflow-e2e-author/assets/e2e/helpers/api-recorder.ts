import fs from 'fs';
import path from 'path';
import type { Page, Request, Response, TestInfo } from '@playwright/test';

export interface ApiRecordItem {
  time: string;
  method: string;
  url: string;
  status: number | null;
  ok: boolean;
  durationMs: number | null;
  resourceType: string;
  /** 截断后的响应摘要 */
  responsePreview?: string;
  error?: string;
}

export interface ApiRecorderOptions {
  enabled?: boolean;
  include?: string[];
  exclude?: string[];
  captureBody?: boolean;
  /** 失败响应（非 2xx / requestfailed）是否总是带 body 摘要，默认 true */
  captureBodyOnError?: boolean;
  bodyMaxChars?: number;
}

const DEFAULT_INCLUDE = ['/gaea', '/api/', '/login', '/oauth'];

const DEFAULT_EXCLUDE = [
  '.js',
  '.css',
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.svg',
  '.woff',
  '.woff2',
  '.map',
  'hot-update',
  'sockjs-node',
  '__webpack',
];

type Pending = {
  startedAt: number;
  method: string;
  url: string;
  resourceType: string;
};

/**
 * 录制测试过程中的必要接口（含 4xx/5xx、网络失败）。
 * 用例无论通过/失败，结束时都会落盘（fixture teardown）。
 */
export function attachApiRecorder(page: Page, options: ApiRecorderOptions = {}) {
  const enabled = options.enabled !== false && process.env.E2E_API_RECORD !== '0';
  const include = options.include?.length ? options.include : DEFAULT_INCLUDE;
  const exclude = [...DEFAULT_EXCLUDE, ...(options.exclude || [])];
  const captureBody =
    options.captureBody === true || process.env.E2E_API_RECORD_BODY === '1';
  const captureBodyOnError = options.captureBodyOnError !== false;
  const bodyMaxChars = options.bodyMaxChars ?? 2000;

  const records: ApiRecordItem[] = [];
  const pending = new Map<Request, Pending>();
  const inflight = new Set<Promise<void>>();

  if (!enabled) {
    return {
      enabled: false,
      getRecords: () => records,
      flush: async () => records,
    };
  }

  const onRequest = (req: Request) => {
    if (!shouldRecord(req.url(), req.resourceType(), include, exclude)) return;
    pending.set(req, {
      startedAt: Date.now(),
      method: req.method(),
      url: sanitizeUrl(req.url()),
      resourceType: req.resourceType(),
    });
  };

  const onResponse = (res: Response) => {
    const req = res.request();
    const meta = pending.get(req);
    if (!meta) return;
    pending.delete(req);

    const task = (async () => {
      const status = res.status();
      const ok = res.ok();
      const item: ApiRecordItem = {
        time: new Date().toISOString(),
        method: meta.method,
        url: meta.url,
        status,
        ok,
        durationMs: Date.now() - meta.startedAt,
        resourceType: meta.resourceType,
      };

      const needBody = captureBody || (!ok && captureBodyOnError);
      if (needBody) {
        try {
          const ct = res.headers()['content-type'] || '';
          if (ct.includes('json') || ct.includes('text') || !ok) {
            const text = await res.text();
            item.responsePreview = text.slice(0, bodyMaxChars);
            if (text.length > bodyMaxChars) item.responsePreview += '…';
          }
        } catch (e) {
          item.error = e instanceof Error ? e.message : String(e);
        }
      }

      records.push(item);
      const tag = ok ? '' : ' !FAIL';
      // eslint-disable-next-line no-console
      console.log(
        `[e2e:api]${tag} ${item.method} ${item.status ?? '-'} ${item.durationMs}ms ${item.url}`
      );
    })().finally(() => {
      inflight.delete(task);
    });

    inflight.add(task);
  };

  const onRequestFailed = (req: Request) => {
    const meta = pending.get(req);
    if (!meta) return;
    pending.delete(req);
    const failure = req.failure();
    records.push({
      time: new Date().toISOString(),
      method: meta.method,
      url: meta.url,
      status: null,
      ok: false,
      durationMs: Date.now() - meta.startedAt,
      resourceType: meta.resourceType,
      error: failure?.errorText || 'request failed',
    });
    // eslint-disable-next-line no-console
    console.log(`[e2e:api] !FAIL ${meta.method} NET ${meta.url} (${failure?.errorText || 'failed'})`);
  };

  page.on('request', onRequest);
  page.on('response', onResponse);
  page.on('requestfailed', onRequestFailed);

  return {
    enabled: true,
    getRecords: () => records,
    flush: async (testInfo?: TestInfo) => {
      try {
        // 等在途 response 处理完（含失败响应读 body）
        await Promise.allSettled([...inflight]);
        // 尚未收到响应的请求也记一笔，避免用例失败时丢失
        for (const [, meta] of pending) {
          records.push({
            time: new Date().toISOString(),
            method: meta.method,
            url: meta.url,
            status: null,
            ok: false,
            durationMs: Date.now() - meta.startedAt,
            resourceType: meta.resourceType,
            error: 'no response before test ended',
          });
        }
        pending.clear();
      } finally {
        try {
          page.off('request', onRequest);
          page.off('response', onResponse);
          page.off('requestfailed', onRequestFailed);
        } catch {
          // page 可能已关闭
        }
      }

      const failed = records.filter((r) => !r.ok);
      const payload = {
        testStatus: testInfo?.status,
        testTitle: testInfo?.title,
        count: records.length,
        failed: failed.length,
        records,
      };

      const outDir = path.resolve(__dirname, '../../midscene_run/api');
      fs.mkdirSync(outDir, { recursive: true });
      const statusTag = testInfo?.status && testInfo.status !== 'passed' ? `_${testInfo.status}` : '';
      const safeTitle = (testInfo?.title || 'api')
        .replace(/[^\w\u4e00-\u9fa5-]+/g, '_')
        .slice(0, 80);
      const file = path.join(outDir, `${Date.now()}-${safeTitle}${statusTag}.json`);
      fs.writeFileSync(file, JSON.stringify(payload, null, 2), 'utf8');

      if (testInfo) {
        try {
          await testInfo.attach('api-requests', {
            path: file,
            contentType: 'application/json',
          });
        } catch {
          // attach 失败不影响落盘
        }
      }

      // eslint-disable-next-line no-console
      console.log(
        `[e2e:api] 已记录 ${payload.count} 条（失败 ${payload.failed}），用例状态=${payload.testStatus || '-'} → ${file}`
      );
      return records;
    },
  };
}

function shouldRecord(
  url: string,
  resourceType: string,
  include: string[],
  exclude: string[]
): boolean {
  if (!['xhr', 'fetch', 'document'].includes(resourceType)) return false;
  const lower = url.toLowerCase();
  if (exclude.some((x) => lower.includes(x.toLowerCase()))) return false;
  return include.some((x) => lower.includes(x.toLowerCase()));
}

function sanitizeUrl(url: string): string {
  try {
    const u = new URL(url);
    ['token', 'access_token', 'password', 'pwd'].forEach((k) => {
      if (u.searchParams.has(k)) u.searchParams.set(k, '***');
    });
    return `${u.origin}${u.pathname}${u.search}`;
  } catch {
    return url;
  }
}
