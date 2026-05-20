# Benchmark Results Archive

Historical benchmark data for pi subagent model selection.

---

## 2025-05-20: scope-tracer (research skill)

| Model        | Time | Tools | Tokens | Format | Quality                             |
| ------------ | ---- | ----- | ------ | ------ | ----------------------------------- |
| kimi-k2.5    | 83s  | 14    | 13.7k  | ✅     | Surgical, precise lines             |
| qwen3.5-plus | 209s | 14    | 64.7k  | ✅     | Thorough, expensive                 |
| minimax-m2.5 | 23s  | 4     | 14.1k  | ⚠️     | Direct answer tendency              |
| minimax-m2.7 | 114s | 21    | 5.8k   | ✅     | **Analytical, architectural, lean** |

**Winner**: minimax-m2.7 (thinking: off)

- Best analytical depth for downstream design/plan skills
- Leanest token usage of compliant models
- ~25% faster than qwen with 10× fewer tokens

### Thinking Level Comparison (m2.7)

| Level | Time | Tokens | Quality                  |
| ----- | ---- | ------ | ------------------------ |
| high  | 125s | 6.3k   | Analytical depth         |
| off   | 114s | 5.8k   | **Same quality, leaner** |

Some models have strong inherent reasoning — explicit `thinking: high` adds
overhead without benefit.

---

## 2025-05-20: codebase-analyzer (design/plan skills)

| Model             | Thinking | Time | Tools | Tokens | Format      | Quality                   |
| ----------------- | -------- | ---- | ----- | ------ | ----------- | ------------------------- |
| kimi-k2.5         | high     | 136s | 19    | 15.0k  | ✅ **Best** | Surgical `file:line` refs |
| deepseek-v4-flash | off      | 130s | 43    | 21.5k  | ✅ Good     | Narrative-heavy           |
| minimax-m2.7      | off      | 210s | 31    | 9.5k   | ✅ Good     | Leanest tokens            |
| deepseek-v4-flash | high     | 149s | 32    | 25.5k  | ✅          | Slightly improved         |
| deepseek-v4-flash | xhigh    | 146s | 30    | 24.1k  | ✅          | Diminishing returns       |

**Winner**: kimi-k2.5 (thinking: high)

- Matches agent schema section order exactly
- Surgical `file:line` citations
- Best for downstream skills expecting structured output

### Format Compliance Detail

kimi-k2.5 matched the prescribed section order: Analysis → Overview → Entry
Points → Core Implementation → Data Flow → Key Patterns

deepseek-v4-flash is faster but intersperses more narrative prose between
sections. Prioritize compliance when the agent feeds downstream skills.

---

## 2026-05-20: artifacts-analyzer (revise skill)

| Model             | Thinking | Time      | Tools | Tokens    | Format | Quality                          |
| ----------------- | -------- | --------- | ----- | --------- | ------ | -------------------------------- |
| minimax-m2.7      | off      | **43.3s** | 3     | **12.7k** | ✅     | Surgical, lean, full depth       |
| kimi-k2.5         | high     | 81.6s     | 3     | 19.2k     | ✅     | Excellent, extra narrative layer |
| deepseek-v4-flash | off      | 37.6s     | 3     | 17.9k     | ✅     | Good, slightly prose-heavy       |

**Winner**: minimax-m2.7 (thinking: off)

- Equal analytical depth to kimi at ~2× speed
- Leanest tokens of compliant models
- Best efficiency for parallel revise pipelines

---

## Model Characteristics Summary

| Model             | Format Compliance | Speed    | Token Efficiency | Reasoning Style               | Best For                                |
| ----------------- | ----------------- | -------- | ---------------- | ----------------------------- | --------------------------------------- |
| kimi-k2.5         | **Strong**        | **Fast** | Good             | Surgical, precise             | Codebase-analyzer, adversarial review   |
| qwen3.5-plus      | Strong            | Slow     | Poor             | Thorough, exhaustive          | Deep analysis (budget allowing)         |
| minimax-m2.5      | Variable          | Fast     | Good             | Direct, solution-oriented     | Avoid for complex prompt formats        |
| minimax-m2.7      | **Strong**        | Medium   | **Excellent**    | **Analytical, architectural** | **Research tracer, artifacts-analyzer** |
| deepseek-v4-flash | Good              | **Fast** | Moderate         | Good depth, narrative-heavy   | Fast analysis when format is flexible   |
