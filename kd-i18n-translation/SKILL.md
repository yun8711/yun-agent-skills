---
name: kd-i18n-translation
description: VoerkaI18n：extract / default.json 与场景 A|B|C 翻译 / compile。门禁后执行；补缺译须用根目录 i18n-pending-translate.json 工作流。与 kd-i18n-marking、kd-i18n-setup 配套。
---

# KD 国际化 - 翻译管理 (kd-i18n-translation)

## 门禁（未满足前禁止动译）

在得到用户 **A|B|C 之一**（及 **A 时的参考分支名**）前，**禁止**：往 `default.json` 或 locale JSON **写译文**；做场景 **A** 的参考分支合并；按场景 **C** 对 diff 增量开译。

**唯一可在门禁前执行的命令**：`pnpm i18n:extract`（及随之 Prettier）。extract **不算**场景确认；用户只说「提取+翻译」且未说明是否对齐分支/是否首次时，**必须先问场景**，不得默认 B/C 全库开译。

**问场景时的交互**：有 **`AskQuestion`** 则用其展示 A/B/C；同一轮**禁止**夹带行数、idMap 分析、长 checklist、extract 日志；先选 A/B/C，**选 A 后再问**参考分支名；不要求用户固定句式（`A`/`场景B`/点选/同轮说清分支均可）。无表单则：一行标题 + 三选项 +「回复 A/B/C」。

**场景 A、用户未直接写出参考分支时**：用 `git branch -a`（或等价）列出**全部**可用分支供选；**仅调整展示/推荐顺序**（不缩小候选池）：① 名中含 **`i18n`**（不区分大小写）置前；② 其余中名中含 **`release`** 的次之；③ 再其它（名中**同时含二者**的只放进 **①**）。用户**可任选任意分支**；**禁止**在未获用户确认前擅自选用列表第一项或其它默认。

| 场景 | 含义 |
| --- | --- |
| **A** | 对齐成熟 i18n **参考分支**（须分支名） |
| **B** | 首次国际化，全量新译 |
| **C** | 已有译库，仅增量 key（`git diff` 收敛） |

## 命令顺序

`pnpm i18n:extract` → **门禁** → 按场景翻译 → **`pnpm i18n:compile`**（均定义在 `package.json`；compile 含 voerkai18n compile + `src/languages/*.*` Prettier）。

## 翻译执行

- 译文仅由**当前对话 AI**写回 JSON。  
- **禁止** DeepL、Google 翻译、`npx voerkai18n translate` 等第三方翻译。

## 补缺译：临时文件（强制路径）

批量补缺译**必须**走此流程，**禁止**无差别整份改 `default.json`。

1. 标出待补：**key + 语种字段**（空、或与中文同形占位等，按项目约定算未译）。  
2. 写入**仅含待译子集**的 JSON → 项目根（与 `package.json` 同级）**`i18n-pending-translate.json`**；根 `.gitignore` 须包含该文件名（无则补）。  
3. **仅**对该文件内字段产出译文；**此时不改**主 `default.json`。  
4. **按 key + 语种**合并进 `default.json`（及项目内其它 locale 文件）：只覆盖本次填上的字段；**不**用临时文件删 key 或整 key 替换；**`$files` 等元数据以主文件为准**。  
5. **删除** `i18n-pending-translate.json`；误暂存则 `git reset` 该文件。

## 场景 A（参考分支合并）

- **分支名**由用户指定，**禁止默认**。未取得前不合并。参考分支可从仓库**任意分支**选取；仅当需要列举分支时，按上文 **i18n → release → 其它** 顺序排序展示。  
- 当前分支先 `pnpm i18n:extract`；读参考分支 `default.json`（及等价路径），与当前**按 key 对齐**。  
- **禁止**用参考的整条对象覆盖当前。  
- **基底**：当前每个 key 的对象；**`$files` 以当前为准**（除非用户明文另约）。  
- **语字段**（`en`/`jp`/`ar`…，不含 `$files`）：参考该语种**非空且为可用译文**（非中文同形占位）→ 采用参考；参考无/空/不可用 → **保留当前**该语种；**双方都已有效译文** → **保留当前**。  
- 仅当前有的新 key：保留当前，缺译走 **临时文件工作流**。  
- 多文件 locale：同规则，以**当前文件**为基底。  
- 新语种：配置齐备后，参考有则按字段规则合并；参考无则占位 + **临时文件工作流**。  
- 合并后：缺译 → **临时文件工作流** → `pnpm i18n:compile`。

## 场景 B

`pnpm i18n:extract` → 几乎全部未译 → **临时文件工作流** → `pnpm i18n:compile`。

## 场景 C

extract 只追加缺失 key。用 `git diff`（`src/languages/translates/`、相关 `.json`）圈增量；增量未译 → **临时文件工作流**；diff 外的条目不重译 → `pnpm i18n:compile`。

## 质量（写回时遵守）

- 占位符 `{name}`、`{count}` 等原样保留。  
- 术语、UI 动作词全项目统一。  
- RTL 语种：译文标点与语义注意方向；布局在业务代码验收。

## 自检（交点前核对）

- 门禁：A|B|C +（A）分支名；提问无长文堆砌、无强制咒语；A 下列分支时按 **i18n → release → 其它** 排序且未擅自替用户选分支。  
- 译文仅 AI；无第三方翻译服务。  
- A：逐语种合并，未整 key 覆盖；`$files` 未被参考整条顶掉。  
- C：范围由 diff 收敛。  
- 补缺译：仅用 **`i18n-pending-translate.json`** → 写回 → **已删**且已 ignore。  
- **`pnpm i18n:compile` 已成功**。

**结束**：compile 成功后，本 Skill 链路结束；构建、发布、走查为人工后续。
