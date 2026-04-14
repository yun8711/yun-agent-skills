#!/usr/bin/env node
/**
 * 递归扫描笔记目录，生成 _index.json 分类索引
 * 用法: node scripts/generate-index.js
 */

const fs = require('fs');
const path = require('path');

const SKILL_DIR = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(SKILL_DIR, 'config.json');

const DEFAULT_EXCLUDE = new Set([
  '.git',
  '.obsidian',
  'assets',
  'node_modules',
  '__pycache__',
  '.DS_Store',
  '.idea',
]);

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('未找到 config.json，请先配置 notesPath');
    process.exit(1);
  }
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const notesPath = config.notesPath?.replace(/^~/, process.env.HOME || '');
  if (!notesPath) {
    console.error('config.json 中未配置 notesPath');
    process.exit(1);
  }
  const excludeDirs = new Set([
    ...DEFAULT_EXCLUDE,
    ...(config.excludeDirs || []),
  ]);
  return { notesPath: path.resolve(notesPath), excludeDirs };
}

function scanDir(dirPath, excludeDirs) {
  const children = {};
  if (!fs.existsSync(dirPath)) return children;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isDirectory() && !excludeDirs.has(entry.name)) {
      const fullPath = path.join(dirPath, entry.name);
      children[entry.name] = { children: scanDir(fullPath, excludeDirs) };
    }
  }
  return children;
}

function flattenPaths(obj, prefix = '') {
  const paths = [];
  for (const [name, node] of Object.entries(obj)) {
    const p = prefix ? `${prefix}/${name}` : name;
    paths.push(p);
    if (Object.keys(node.children).length > 0) {
      paths.push(...flattenPaths(node.children, p));
    }
  }
  return paths;
}

const { notesPath, excludeDirs } = loadConfig();
if (!fs.existsSync(notesPath)) {
  console.error(`笔记目录不存在: ${notesPath}`);
  process.exit(1);
}

const tree = scanDir(notesPath, excludeDirs);
const paths = flattenPaths(tree);

const index = {
  notesRoot: notesPath,
  updatedAt: new Date().toISOString(),
  excludeDirs: [...excludeDirs],
  tree,
  paths,
};

const indexPath = path.join(notesPath, '_index.json');
fs.writeFileSync(indexPath, JSON.stringify(index, null, 2), 'utf8');
console.log(`索引已生成: ${indexPath}`);
console.log(`共 ${paths.length} 个目录`);
