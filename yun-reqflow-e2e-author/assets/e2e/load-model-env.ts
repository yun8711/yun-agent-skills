import fs from 'fs';
import os from 'os';
import path from 'path';

/**
 * 从 ~/.codex 补齐 Midscene 模型环境变量（不覆盖已有值）。
 *
 * 默认走 Midscene 官方 Codex 通道：codex://app-server（无需再抄 API Key）。
 * 若需直连 gateway（OpenAI 兼容 /v1），设 E2E_MODEL_PROVIDER=gateway。
 */
export function loadModelEnvFromCodex(): void {
  if (process.env.E2E_MODEL_FROM_CODEX === '0') return;

  const codexHome = process.env.CODEX_HOME || path.join(os.homedir(), '.codex');
  const configPath = path.join(codexHome, 'config.toml');
  const authPath = path.join(codexHome, 'auth.json');

  const toml = safeRead(configPath);
  const model = (toml && matchToml(toml, /^\s*model\s*=\s*"([^"]+)"/m)) || 'gpt-5.4';
  const provider = matchToml(toml || '', /^\s*model_provider\s*=\s*"([^"]+)"/m) || 'gateway';
  const gatewayBase =
    matchToml(toml || '', /^\s*base_url\s*=\s*"([^"]+)"/m) ||
    'http://gateway.keendata.net:5343';

  const mode = (process.env.E2E_MODEL_PROVIDER || 'codex').toLowerCase();

  setIfEmpty('MIDSCENE_MODEL_NAME', model);
  setIfEmpty('MIDSCENE_MODEL_FAMILY', process.env.E2E_MODEL_FAMILY || 'gpt-5');

  if (mode === 'gateway') {
    const base = normalizeOpenAIBaseURL(process.env.E2E_GATEWAY_BASE_URL || gatewayBase);
    setIfEmpty('MIDSCENE_MODEL_BASE_URL', base);
    if (!process.env.MIDSCENE_MODEL_API_KEY) {
      const key = readCodexApiKey(authPath);
      if (key) process.env.MIDSCENE_MODEL_API_KEY = key;
    }
  } else {
    // 推荐：复用本机 Codex（config.toml + auth），不把 Key 写入项目文件
    setIfEmpty('MIDSCENE_MODEL_BASE_URL', 'codex://app-server');
  }

  if (!process.env.MIDSCENE_MODEL_NAME || !process.env.MIDSCENE_MODEL_FAMILY) {
    console.warn('[e2e] Midscene 模型未配置完整，请检查 .env.e2e 或 ~/.codex');
  }
}

function normalizeOpenAIBaseURL(url: string): string {
  const trimmed = url.replace(/\/$/, '');
  if (/\/v\d+$/i.test(trimmed)) return trimmed;
  return `${trimmed}/v1`;
}

function readCodexApiKey(authPath: string): string | undefined {
  try {
    if (!fs.existsSync(authPath)) return undefined;
    const auth = JSON.parse(fs.readFileSync(authPath, 'utf8')) as Record<string, string>;
    return auth.OPENAI_API_KEY || auth.api_key || undefined;
  } catch {
    return undefined;
  }
}

function setIfEmpty(key: string, value: string) {
  if (!process.env[key]) process.env[key] = value;
}

function safeRead(filePath: string): string | undefined {
  try {
    if (!fs.existsSync(filePath)) return undefined;
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return undefined;
  }
}

function matchToml(content: string, re: RegExp): string | undefined {
  const m = content.match(re);
  return m?.[1];
}
