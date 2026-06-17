# 入口文件发现

## 默认排除（遍历与收录均跳过）

- 目录：`node_modules/`、`.git/`、`dist/`、`build/`、`coverage/`、`.next/`、`vendor/`、`__pycache__/`
- 文件：锁文件（`package-lock.json`、`yarn.lock`、`pnpm-lock.yaml`）、`.min.js`、`.map`、图片/字体/视频等二进制
- 用户提供的 `exclude_patterns`

## 按技术栈推断入口

| 栈 | 查找顺序 |
|----|----------|
| Vue 2/3 | `package.json` 的 `main` / `module`；或 `src/main.js`、`src/main.ts`、`src/index.js` |
| React | `src/index.tsx`、`src/index.jsx`、`src/main.tsx` |
| Node 后端 | `package.json` 的 `main`；或 `src/index.js`、`app.js`、`server.js` |
| Python | `pyproject.toml` / `setup.py` 的 entry；或 `main.py`、`app/__init__.py`、`manage.py` |
| Go | `cmd/*/main.go` 或根目录 `main.go` |
| Java | 含 `public static void main` 的类；或 `pom.xml` / `build.gradle` 声明的 mainClass |

多个候选时 **AskQuestion 或对话确认**，不要静默猜测。

## 依赖跟随（BFS）

从入口起，解析以下引用并 enqueue（路径相对项目根，去重）：

- JS/TS/Vue SFC： `import … from '…'`、`require('…')`、`import('…')`
- 相对路径：`./`、`../` 解析为实际文件（尝试 `.js`、`.ts`、`.vue`、`.jsx`、`.tsx`、`/index.js`）
- Python：`import`、`from … import`
- 无法解析的包名（npm 包、stdlib）跳过，不跟 node_modules

遍历顺序 = BFS 发现顺序；收录时按此顺序追加文件。
