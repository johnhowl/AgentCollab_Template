# FIXLOG — Codex 自治修复留痕

Codex 每做一次 **A 级自治修复**（确定性、范围局部、不改任何契约/接口/测试期望的
低级 bug），必须在这里追加一条，作为对 Claude 的**通知与留痕**。Claude 在下一轮
review / plan 时会读这里。判定与边界见 `AGENTS.md`「改动分级与自治边界」。

- A 级修复：直接修 → `scripts\New-FixNote.ps1` 追加条目 → 单独 `[autofix]` 原子提交。
- B 级（改方案/审查/验收规范、改接口/schema/容差、动协同机制、跨任务范围）：
  不许在这里记账了事，必须走对齐通道（query → resolution）。

格式由 `scripts\New-FixNote.ps1` 生成，请勿手改历史条目。

---

