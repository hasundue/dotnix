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

| Model             | Format Compliance             | Speed    | Token Efficiency | Reasoning Style               | Best For                                                                         |
| ----------------- | ----------------------------- | -------- | ---------------- | ----------------------------- | -------------------------------------------------------------------------------- |
| kimi-k2.5         | **Strong**                    | **Fast** | Good             | Surgical, precise             | Codebase-analyzer, adversarial review                                            |
| qwen3.5-plus      | Strong                        | Slow     | Poor             | Thorough, exhaustive          | Deep analysis (budget allowing)                                                  |
| minimax-m2.5      | Variable                      | Fast     | Good             | Direct, solution-oriented     | Avoid for complex prompt formats, web-search-researcher (misses context)         |
| minimax-m2.7      | **Strong**                    | Medium   | **Excellent**    | **Analytical, architectural** | **Research tracer, artifacts-analyzer, slice-verifier, artifact-reviewer**       |
| deepseek-v4-flash | Good (improves with thinking) | **Fast** | Moderate         | Good depth, narrative-heavy   | Fast analysis, **adversarial verification (claim-verifier with thinking: high)** |

## 2026-05-20: artifact-reviewer (blueprint skill)

Test: adversarial post-finalization review against a 2-phase audio device
switcher plan artifact in pre-review state (deliberate bugs: missing
`BEFORE the in keyword` note, missing `BEGIN` awk initializer, duplicate `│` in
char class, missing muted CSS rule). Models evaluated on finding genuine bugs vs
noise.

| Model             | Thinking | Time       | Tools | Tokens    | Findings | Caught OFS bug? | Caught missing CSS? | Caught line shift? |
| ----------------- | -------- | ---------- | ----- | --------- | -------- | --------------- | ------------------- | ------------------ |
| minimax-m2.7      | high     | **240.3s** | 9     | **24.1k** | 6        | ✅ **Yes** (2x) | ❌ No               | ❌ No              |
| kimi-k2.5         | high     | 291.5s     | 20    | 29.8k     | 5        | ❌ No           | ✅ Yes              | ✅ **Yes**         |
| deepseek-v4-flash | xhigh    | 383.5s     | 9     | 30.1k     | **9**    | ❌ No           | ❌ No               | ❌ No              |

**Winner**: minimax-m2.7 (thinking: high)

- Fastest, most token-efficient
- Caught the **highest-value finding** (awk OFS bug causing silent ID lookup
  failure — a genuine runtime blocker that kimi and flash both missed)
- Caught missing `format` on module (another real rendering issue)
- Only model to check for gawk dependency

### Why m2.7 wins despite fewer total findings

The OFS bug is a **silent runtime failure** — device switching appears to work
(fuzzel opens, you select a device) but `wpctl set-default` never fires because
the ID lookup always fails. This is exactly the class of bug that
post-finalization review should catch: mechanically plausible code that breaks
at runtime. kimi-k2.5 and flash missed it.

kimi-k2.5 remains strong on breadth (caught the structural line-number shift)
and is a solid fallback. flash was slowest and missed the key bugs despite most
total findings.

---

## 2026-05-20: slice-verifier (blueprint skill)

Test: adversarial per-slice verification of Phase 2 against Phase 1 in a
realistic 2-phase plan artifact for the audio device switcher feature. Phase 1
code fence was deliberately truncated (script bodies in success criteria but not
in code fence) to test cross-slice composition sensitivity.

| Model             | Thinking | Time       | Tools | Tokens    | Format | Quality                                                                      |
| ----------------- | -------- | ---------- | ----- | --------- | ------ | ---------------------------------------------------------------------------- |
| kimi-k2.5         | high     | 187.9s     | 3     | 15.8k     | ✅     | Surgical, precise; found scroll increment bug; missed cross-slice truncation |
| minimax-m2.7      | high     | 265.8s     | 11    | **15.4k** | ✅     | **Deepest adversarial — caught Phase 1 code fence truncation**               |
| deepseek-v4-flash | xhigh    | 281.5s     | 4     | 37.0k     | ✅     | Most thorough on completeness (2 violations); missed cross-slice bug         |
| qwen3.5-plus      | high     | **162.6s** | 6     | 68.4k     | ✅     | Found incomplete pulseaudio block; **missed scroll increment bug**           |

**Winner**: minimax-m2.7 (thinking: high)

- Only model that found the deliberate cross-slice composition bug (Phase 1 code
  fence missing script bodies that Phase 2 references as Nix variables)
- Highest-value finding for temporal-composition specialist role
- Used most tools (11 — read target files, grep/find) — thorough investigation
- Matches scope-tracer and artifacts-analyzer pattern: m2.7 wins adversarial
  depth

### Thinking Level Comparison (m2.7)

| Level | Time   | Tools | Tokens | Caught cross-slice truncation? |
| ----- | ------ | ----- | ------ | ------------------------------ |
| high  | 265.8s | 11    | 15.4k  | ✅ **Yes**                     |
| off   | 155.9s | 3     | 11.1k  | ❌ No                          |

Unlike scope-tracer, where `thinking: off` matched `high` in quality, for
slice-verifier the extra depth from `thinking: high` is critical — the
cross-slice code fence truncation was the highest-value finding and only
surfaced with deeper investigation (more tool uses, more careful reading).

### Notes

- kimi-k2.5 remains strong for speed (187s vs 265s, 30% faster) but the
  cross-slice finding is the primary signal for this agent role
- deepseek-v4-flash with xhigh thinking was token-wasteful (37.0k tokens) for no
  coverage gain over m2.7
- qwen3.5-plus was expensive (68.4k tokens) and missed both the cross-slice bug
  and the scroll increment issue — worst quality-to-cost ratio

---

## 2026-05-20: claim-verifier (code-review skill)

Test: adversarial claim verification against 6 fabricated findings on the
audio-switcher codebase. 3 findings designed to be Falsified (credulity traps),
1 Weakened (partially true), 2 genuinely Verified. Key test: does the model
mechanically verify the quote (credulous) or _challenge the claim's premise_
(truly adversarial)?

| Model             | Thinking | Time     | Tools | Tokens   | Correct tags | Format           | Notes                                                                      |
| ----------------- | -------- | -------- | ----- | -------- | ------------ | ---------------- | -------------------------------------------------------------------------- |
| deepseek-v4-flash | high     | 331s     | 69    | 38.4k    | 4/6          | ✅ **Clean**     | Clean code-block output, 1 prose line only; slightly less adversarial edge |
| deepseek-v4-flash | off      | **258s** | 40    | 24.4k    | **5/6**      | ⚠️ **Narrative** | Challenged all 3 credulity traps but leaked internal monologue into output |
| minimax-m2.7      | off      | 266s     | 36    | **6.7k** | 3/6          | ✅ Clean         | Accepted 3 false claims at face value — credulous, worst adversarial score |

**Winner**: deepseek-v4-flash (thinking: **high**)

- flash `off` had the best adversarial score (5/6 correct tags) but its output
  leaked internal deliberation into the final message ("Wait — I need to
  double-check a nuance…", narrative prose before and between rows). This
  pollutes the orchestrator's context at \~$0.0004/token.
- flash `high` traded one tagging point (4/6 vs 5/6) for **clean output** — one
  intro line, a fenced code block, six rows, nothing else. The orchestrator can
  parse this directly without filtering noise.
- The two tags flash `high` got "wrong" were both borderline:
  - I2 → **Weakened** (not Falsified) — actually more precise: "risk stands
    narrower" is a better verdict than flat Falsified
  - G4 → **Verified** (not Weakened) — slightly generous to the claim, but
    acceptable
- flash `high` is still \~10× cheaper than m2.7 per token, and even at 38.4k
  tokens the total run cost is \~$0.09 vs \~$0.60 for m2.7

### Format comparison

**flash off** output (excerpt):

```
Now I have enough context. Let me compile my findings.

Wait — I need to double-check a nuance. Let me re-examine Q3 more carefully.
The claim says "ponymix is missing from waybar's `home.packages` — ponymix
is only available if already pulled in by another module". But `ponymix` IS
available through `pkgs` which is the full nixpkgs...

FINDING Q3 | Falsified | ...
FINDING S1 | Falsified | ...
...
```

**flash high** output (verbatim):

```
Here are my verified results:
```

FINDING Q3 | Falsified | ... FINDING S1 | Falsified | ... ...

```
```

For the orchestrator (code-review skill) that consumes claim-verifier output,
the clean format of flash `high` prevents context pollution — the rows are
parseable directly without stripping narrative.

### Why flash high for claim-verifier

claim-verifier's job is adversarial verification — being _skeptical_ of claims
and grounding them against actual code. flash's naturally probe-heavy style is
an asset here, unlike roles requiring strict schema output. m2.7's strength
(lean, follows the schema) works against it — it accepted claims without
challenge.

`thinking: high` improves format compliance enough to suppress the narrative
leak while preserving most of flash's adversarial edge. The 69 tool uses (38.4k
tokens) reflect deeper investigation — which is exactly what adversarial
verification needs.

This is the inverse of the pattern we saw in artifact-reviewer, where m2.7's
depth caught the OFS bug but flash missed it. For claim-verifier, the
verification target is much simpler (just tag each claim), and flash's higher
exploration benefits the adversarial dimension.

---

## Cross-Role Patterns

Emerging model-selection heuristics from 5 benchmarked subagent roles:

| Model profile                                                                | When it wins                                                                                                | Roles that use it                 |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **m2.7 off** — lean, analytical, schema-compliant                            | Output feeds downstream skills; depth must fit a tight token budget; thinking level doesn't improve results | scope-tracer, artifacts-analyzer  |
| **m2.7 high** — deep adversarial investigation (more tools, careful reading) | The highest-value signal is a subtle cross-boundary bug; the agent must probe beyond the prompt             | slice-verifier, artifact-reviewer |
| **flash high** — probe-heavy, skeptical, needs thinking to constrain output  | Fast + cheap + adversarial required; output must be parseable without filtering; ~10× cheaper than m2.7     | claim-verifier                    |
| **kimi-k2.5** — surgical, best format compliance                             | Format compliance is the primary constraint; the agent's output drives downstream artifact structure        | codebase-analyzer                 |

### Key insights

1. **m2.7 shines where analytical depth meets a tight output schema** — it
   naturally produces structured, concise text without extra tokens. This makes
   it ideal for the research → design → plan pipeline where each stage consumes
   the previous stage's structured output.

2. **flash needs thinking to suppress narrative leak** — at `thinking: off`,
   flash frequently spills internal reasoning into the output. `high` fixes this
   at the cost of more tokens and tool uses, but still lands ~10× cheaper than
   m2.7 per token.

3. **Skepticism vs schema is the axis** — m2.7 is better at producing structured
   output within a schema. flash is better at questioning the prompt's
   assumptions. For verification roles (claim-verifier), skepticism is the
   primary virtue. For generative roles (artifacts-analyzer, codebase-analyzer),
   schema compliance is.

4. **Thinking level tuning is role-specific** — m2.7 `off` equals `high` for
   scope-tracer but loses the critical finding for slice-verifier. flash `high`
   suppresses narrative leak for claim-verifier but adds cost without benefit
   for artifacts-analyzer. Always test both levels.
