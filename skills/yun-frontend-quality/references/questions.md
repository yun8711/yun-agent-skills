# 3.3 对照案例

对话里展示代码，AskQuestion 选项只用短标签。一次一题。无共识则不要写「行业常见做法」。

未探测到 Vue 且未探测到 React 时，跳过「`>` 位置」和「属性换行」。

## 引号

A 单引号 `const n = 'hi'`  
B 双引号 `const n = "hi"`

## 分号

A 有 `const n = 1;`  
B 无 `const n = 1`

## 尾逗号

```js
const a = {
  x: 1, // 多行对象最后一项
}
```

A 不要尾逗号  
B 仅多行结构有（常见于 ES5 风格配置值）  
C 凡能加都加

## 行宽

同一段在 80 / 100 / 120 列下的折行对照（对象或模板均可）。选项：80 / 100 / 120。

## 缩进

A 2 空格  B 4 空格  C Tab

## 多行标签的 `>`（Vue/React）

A `>` 单独一行：

```vue
<Foo
  a="1"
  b="2"
>
```

B `>` 跟在最后一个属性后：

```vue
<Foo
  a="1"
  b="2">
```

## 属性换行（Vue/React）

A 一行放得下就一行；超宽再拆  
B 多属性时强制每行一个

## 箭头函数括号（可选，用户未提可跳过）

A `x => x`（单参数无括号）  
B `(x) => x`

---

## commitlint 例句（勾了才问）

A `feat: add login` / `fix(api): handle timeout`（conventional）  
B 其它仓内已有规则（保持现有配置）

坏例仅作说明：`update`、`改了点东西`（无类型前缀时 conventional 会拒）。

## tsconfig 三档（勾了才问）

用「同一段代码在该档会不会报」对照，不要列全部选项：

- 松：少强制，升级旧 JS 常见  
- 常用：`strict` 一类常规打开，`skipLibCheck` 常开  
- 严：再开未使用变量/参数等（与 `noUnusedLocals` 同类）

选项含「保持现有 tsconfig」。
