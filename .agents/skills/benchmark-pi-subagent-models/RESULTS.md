# Benchmark Results Archive

Historical benchmark data for pi subagent model selection.

> **Pricing reference** (opencode-go provider, USD per million tokens, source:
> [anomalyco/models.dev](https://github.com/anomalyco/models.dev/tree/dev/providers/opencode-go/models)):
>
> - deepseek-v4-flash: **$0.14 in / $0.28 out** ⬅ cheapest
> - qwen3.5-plus: $0.20 in / $1.20 out
> - minimax-m2.5 / m2.7: $0.30 in / $1.20 out
> - kimi-k2.5: $0.60 in / $3.00 out
> - deepseek-v4-pro: $1.74 in / $3.48 out
> - kimi-k2.6: $0.95 in / $4.00 out
>
> **Always compute effective cost**, not raw tokens: flash output ($0.28/M) is
> 4.3×
>
>> cheaper than minimax ($1.20/M), so flash can use 4× more output tokens and
>> still be cost-competitive.

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

## 2026-05-20: precedent-locator (research/design skills)

**Prompt format**: Natural language task description — the research and design
skills pass detailed instructions about finding git history precedent. The agent
searches commit log, blast radius, follow-up fixes, and .rpiv/artifacts/ docs.

| Model             | Thinking | Time      | Tools | Tokens | Format | Quality                             |
| ----------------- | -------- | --------- | ----- | ------ | ------ | ----------------------------------- |
| minimax-m2.7      | off      | **37.8s** | 13    | 18.8k  | ✅     | **5 lessons, focused, analytical**  |
| kimi-k2.5         | high     | 124.9s    | 38    | 26.9k  | ✅     | 6 lessons, surgical details         |
| deepseek-v4-flash | off      | 155.4s    | 78    | 43.7k  | ✅     | 6 lessons, verbose (2.3× tokens)    |
| qwen3.5-plus      | high     | 216.1s    | 31    | 224.1k | ✅     | 6 lessons, 7 precedents (12× bloat) |

**Winner**: minimax-m2.7 (thinking: off)

- **3.3× faster** than kimi-k2.5, **5.7× faster** than qwen
- **44% fewer tokens** than kimi-k2.5, **92% fewer** than qwen
- Same format compliance and comparable lesson quality
- qwen3.5-plus had **12× token bloat** (224k vs 18.8k) — avoid for this agent

### Quality Assessment

All four models produced **format-compliant** output matching the expected
structure (Composite Lessons, blast radius, follow-up fixes). Key differences:

- **minimax-m2.7**: Lean, analytical — 18.8k tokens, 37.8s. Found 3 high-value
  precedents with focused, actionable takeaways. Best quality per token ratio.

- **kimi-k2.5**: Thorough but 3.3× slower — 26.9k tokens, 124.9s, 38 tools. Same
  precedent coverage. More granular blast radius analysis, but the additional
  depth doesn't translate to better downstream actionability.

- **deepseek-v4-flash**: Most verbose — 43.7k tokens, 155.4s, 78 tool uses. 2.3×
  more tokens than minimax for similar lesson quality. The 78 tools (vs 13 for
  minimax) suggest over-mining: it read more individual git objects and files
  than necessary for the task scope.

- **qwen3.5-plus**: **12× token bloat** (224.1k vs 18.8k) for essentially the
  same quality output. It found 7 precedents (more than others) but at extreme
  cost. Not suitable for this agent type.

**Verdict**: minimax-m2.7 captures the same essential analysis as kimi at 3× the
speed with 44% fewer tokens. deepseek is overzealous with tool use for this
git-history mining use case.

---

## 2026-05-20: web-search-researcher (ecosystem scan)

| Model             | Thinking | Time      | Tools | Tokens   | Format           | Quality                                                    |
| ----------------- | -------- | --------- | ----- | -------- | ---------------- | ---------------------------------------------------------- |
| deepseek-v4-flash | off      | **84.3s** | 14    | 29.5k    | ✅ Good          | Excellent depth, 4 options + tailored per-user recs        |
| deepseek-v4-flash | xhigh    | 130.4s    | 18    | 42.9k    | ✅ Good          | More thorough citations, honorable mention added           |
| minimax-m2.5      | off      | 120.4s    | **9** | 19.1k    | ✅ Good          | Good depth but missed agenix itself (listed opnix instead) |
| minimax-m2.7      | off      | 119.8s    | 12    | **8.8k** | ✅ **Excellent** | Equal depth, cleaner structure, tighter format             |

**Winner**: deepseek-v4-flash (thinking: off)

After factoring in real-world pricing: deepseek-v4-flash is **~10× cheaper per
token** than minimax models. The effective cost comparison:

| Model         | Raw tokens | × price multiplier | Effective cost | Time         |
| ------------- | ---------- | ------------------ | -------------- | ------------ |
| flash (off)   | 29.5k      | ×1                 | **29.5k** 🏆   | **84.3s** 🏆 |
| flash (xhigh) | 42.9k      | ×1                 | 42.9k          | 130.4s       |
| m2.5          | 19.1k      | ×10                | 191k           | 120.4s       |
| m2.7          | 8.8k       | ×10                | 88k            | 119.8s       |

Flash off is **~3× cheaper than m2.7** and **30% faster**, with quality
essentially equal. The default stays.

### Thinking Level Diminishing Returns (deepseek-v4-flash)

| Level | Time      | Tools | Tokens | Quality Delta                              |
| ----- | --------- | ----- | ------ | ------------------------------------------ |
| off   | **84.3s** | 14    | 29.5k  | Base — excellent quality                   |
| xhigh | 130.4s    | 18    | 42.9k  | +55% time, +45% tokens, minor quality gain |

`xhigh` added an honorable mention (agenix-rekey) and slightly more structured
citations, but the core analysis is identical. **Diminishing returns are
severe** — xhigh is 55% slower and 45% more tokens for marginal improvement in
breadth. The `off` setting captures the same essential quality at significantly
lower cost.

### Analysis

`web-search-researcher` is unique among the agents benchmarked so far: its
prompt is relatively straightforward (natural-language instructions, no
structured schema), and all model variants conform well.

The deciding factor here is **pricing**: deepseek-v4-flash is ~10× cheaper per
token than minimax models. The leaner token count of m2.7 (8.8k vs 29.5k)
doesn't overcome a 10× price multiplier — flash ends up ~3× cheaper in effective
cost while also being faster.

- **deepseek-v4-flash (off)** — clear winner: fastest, cheapest, excellent
  quality
- **deepseek-v4-flash (xhigh)** — skip: +55% time, +45% tokens for marginal
  breadth gain
- **minimax-m2.7** — strong contender quality-wise, but the 10× price premium
  makes it hard to justify
- **minimax-m2.5** — avoid: missed situational context (didn't list agenix) and
  same price premium as m2.7

The existing default of `deepseek-v4-flash (off)` is the right choice.

## Model Characteristics Summary

| Model             | Format Compliance | Speed    | Token Efficiency | Reasoning Style               | Best For                                                                           |
| ----------------- | ----------------- | -------- | ---------------- | ----------------------------- | ---------------------------------------------------------------------------------- |
| kimi-k2.5         | **Strong**        | **Fast** | Good             | Surgical, precise             | Codebase-analyzer, adversarial review                                              |
| qwen3.5-plus      | Strong            | Slow     | Poor             | Thorough, exhaustive          | Deep analysis (budget allowing)                                                    |
| minimax-m2.5      | Variable          | Fast     | Good             | Direct, solution-oriented     | Avoid for complex prompt formats, web-search-researcher (misses context)           |
| minimax-m2.7      | **Strong**        | Medium   | **Excellent**    | **Analytical, architectural** | **Research tracer, artifacts-analyzer, web-search-researcher**                     |
| deepseek-v4-flash | Good              | **Fast** | Moderate         | Good depth, narrative-heavy   | Fast analysis when format is flexible, **web-search-researcher** (best cost-value) |
