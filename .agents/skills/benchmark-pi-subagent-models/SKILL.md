---
name: benchmark-pi-subagent-models
description: Benchmark LLM models for pi subagents to find optimal model and thinking level. Supports sequential and parallel benchmarking with format compliance testing.
---

# Benchmark pi Subagent Models

Benchmark different LLM models for a pi subagent (rpiv-pi agent) to find the
optimal model and thinking level for a specific agent type.

## When to Use

Use this skill when:

- Adding a new pi subagent and unsure which model to default to
- Existing agent produces inconsistent or low-quality results
- Want to validate if a newer/cheaper model can replace current default
- Troubleshooting format compliance issues (agent answers instead of
  researching)

## Prerequisites

- Agent definition file exists at `~/.pi/agent/agents/<agent-name>.md`
- Know which skill(s) will invoke this agent (determines prompt format)
- A representative task/query matching that skill's calling pattern
- Multiple candidate models to test (see available models with `pi models list`)

## Critical: Prompt Format is Determined by the Caller

**The skill that invokes the agent determines the prompt format** — not the
agent itself.

| Skill      | Agent(s) it calls         | Prompt Format                                          |
| ---------- | ------------------------- | ------------------------------------------------------ |
| `research` | `scope-tracer`            | **Exact user question** — passes `$ARGUMENTS` directly |
| `design`   | `codebase-analyzer`, etc. | **Dense question paragraphs** — scope-tracer's output  |
| `plan`     | Various analysis agents   | **Phased instructions** — detailed requirements        |

**To benchmark accurately**: Match the prompt format of the skill that will
actually invoke your agent.

## Process

### 1. Identify the Caller Skill and Prompt Format

Find which skill invokes your agent and determine its prompt pattern:

```bash
# Read the skill that calls your agent
cat ~/.pi/agent/skills/<caller-skill>/SKILL.md
# or
cat /nix/store/.../rpiv-pi-patched/skills/<caller-skill>/SKILL.md
```

Look for the `Agent({ subagent_type: "<your-agent>" ... })` call and see what
`prompt:` value it uses.

### 2. Prepare the Benchmark

Choose a **representative task**:

- Must match the caller skill's prompt format
- Should exercise the agent's core responsibilities
- Should be answerable with the codebase content
- Must be **identical across all model variants**

**Examples by caller skill:**

| Caller Skill                   | Example Prompt                                                           |
| ------------------------------ | ------------------------------------------------------------------------ |
| `research` → `scope-tracer`    | `"can we add a new waybar icon for sound inputs?"` (exact user question) |
| `design` → `codebase-analyzer` | `"{Full dense question paragraph from scope-tracer output}"`             |

### 3. Edit Agent Configuration

Edit `~/.pi/agent/agents/<agent-name>.md`:

```yaml
---
model: <candidate-model>
thinking: <level>  # off, minimal, low, medium, high, xhigh
name: <agent-name>
# ... rest unchanged
---
```

### 4. Run Benchmark Iteration

```bash
# For each (model, thinking) combination:
pi agent <agent-name> "<test prompt matching caller skill format>"
```

Capture:

- **Time** to completion
- **Tool uses** (api cost proxy)
- **Tokens** (context window pressure)
- **Format compliance** (did it follow the agent's defined output schema?)
- **Quality** (depth, correctness, usefulness for downstream skills)

### 5. Evaluate Results

Evaluate across four dimensions:

| Dimension             | What to Check                                                 | Why It Matters                                |
| --------------------- | ------------------------------------------------------------- | --------------------------------------------- |
| **Speed**             | Duration, tool uses                                           | Throughput in multi-agent pipelines           |
| **Tokens**            | Output token count, context usage                             | Cost and context window pressure              |
| **Format Compliance** | Follows agent's defined output schema? Section order correct? | Downstream skills depend on structured output |
| **Quality**           | Analytical depth, file:line citations, correctness            | Value of the analysis itself                  |

#### Format Compliance Check

Critical for agents that feed downstream skills:

| Model   | Compliant? | Indicators                                                          |
| ------- | ---------- | ------------------------------------------------------------------- |
| ✅ Pass | Yes        | Follows defined output schema (Discovery Summary + questions, etc.) |
| ❌ Fail | No         | Gives direct answers, skips schema, "helpful assistant" override    |

**Common failure mode**: Models treating short prompts as questions to answer
rather than research tasks to structure.

#### Key Finding from Our Benchmark

`minimax-m2.5` has a **format compliance bug with exact prompts**:

| Model        | Prompt Source         | Result                            |
| ------------ | --------------------- | --------------------------------- |
| minimax-m2.5 | Detailed instructions | ✅ Research format                |
| minimax-m2.5 | Exact user question   | ❌ Direct answer (broke contract) |
| minimax-m2.7 | Exact user question   | ✅ Research format (fixed)        |

**Lesson**: If your caller skill passes exact user questions (like `research`),
avoid m2.5 — use m2.7+.

#### Key Finding: Format Compliance Trade-offs

For **codebase-analyzer** (called by design/plan skills with dense prompts):

| Model             | Thinking | Tokens | Format Compliance                          |
| ----------------- | -------- | ------ | ------------------------------------------ |
| kimi-k2.5         | high     | 15.0k  | ✅ **Best** — matches agent schema exactly |
| deepseek-v4-flash | off      | 21.5k  | ✅ Good — improves with thinking level     |
| minimax-m2.7      | off      | 9.5k   | ✅ Good — leanest tokens                   |

**kimi-k2.5 wins** on format compliance — it matched the agent's prescribed
section order (Analysis → Overview → Entry Points → Core Implementation → Data
Flow → Key Patterns) with surgical `file:line` references. **deepseek-v4-flash**
is faster but uses more narrative prose between sections.

**Lesson**: Prioritize format compliance when the agent feeds downstream skills
that expect structured output. A slightly slower model with better compliance
prevents broken artifacts.

#### Thinking Level Comparison

For **minimax-m2.7** with exact prompts:

| Level | Time | Tokens | Quality                  |
| ----- | ---- | ------ | ------------------------ |
| high  | 125s | 6.3k   | Analytical depth         |
| off   | 114s | 5.8k   | **Same quality, leaner** |

Some models have strong inherent reasoning — explicit `thinking: high` adds
overhead without benefit.

### 6. Select Winner

Weight dimensions based on the agent's role in the pipeline:

| Agent Role                          | Prioritize                                                           |
| ----------------------------------- | -------------------------------------------------------------------- |
| Research tracer (`scope-tracer`)    | **Format compliance**, analytical depth, constraint identification   |
| Code analyzer (`codebase-analyzer`) | **Format compliance**, precise citations, line numbers, thoroughness |
| Design/plan generator               | Balanced — both depth and precision                                  |
| Cost-sensitive deployments          | Token efficiency, speed                                              |

## Example Benchmark Output

```
## Results: scope-tracer (called by research skill with exact user prompt)

| Model | Time | Tools | Tokens | Format | Quality |
|-------|------|-------|--------|--------|---------|
| kimi-k2.5 | 83s | 14 | 13.7k | ✅ | Surgical, precise lines |
| qwen3.5-plus | 209s | 14 | 64.7k | ✅ | Thorough, expensive |
| minimax-m2.5 | 23s | 4 | 14.1k | ❌ | **Direct answer — wrong format** |
| minimax-m2.7 | 114s | 21 | 5.8k | ✅ | **Analytical, architectural, lean** |

**Winner**: minimax-m2.7 (thinking: off)
- Format compliant with exact prompts (required by research skill)
- Best analytical depth for downstream design/plan skills
- Leanest token usage of compliant models
- ~25% faster than qwen with 10x fewer tokens
```

## Advanced: Parallel Benchmarking

Spawn **all benchmark runs in parallel** — the pi-subagents extension manages
concurrency automatically (typically max 4 concurrent, excess queued).

### Technique

Each agent loads its model config at spawn time and keeps it for the duration.
This means you can:

1. **Set Model A** in `~/.pi/agent/agents/<agent>.md`
2. **Spawn Agent A** with `run_in_background: true`
3. **Immediately change to Model B** in the config file
4. **Spawn Agent B** (also background) — extension queues if at capacity
5. Repeat for all models
6. **Retrieve results** from each agent as they complete

Each agent keeps its originally-loaded model even though the config file changed
between spawns.

### Example: All 5 benchmark runs at once

```bash
# Model 1: kimi-k2.5 high
# Edit config: model: kimi-k2.5, thinking: high
pi agent codebase-analyzer "<prompt>" --background

# Model 2: deepseek-v4-flash off
# Edit config: model: deepseek-v4-flash, thinking: off
pi agent codebase-analyzer "<prompt>" --background

# ... repeat for all model variants
```

**Results collected as agents complete** (not necessarily in spawn order):

| Agent | Model                   | Duration | Tools | Tokens |
| ----- | ----------------------- | -------- | ----- | ------ |
| 1     | kimi-k2.5               | 136s     | 19    | 15.0k  |
| 2     | deepseek-v4-flash       | 130s     | 43    | 21.5k  |
| 3     | minimax-m2.7 off        | 210s     | 31    | 9.5k   |
| 4     | deepseek-v4-flash high  | 149s     | 32    | 25.5k  |
| 5     | deepseek-v4-flash xhigh | 146s     | 30    | 24.1k  |

### When to Use Parallel Benchmarking

| Scenario                             | Recommendation                                              |
| ------------------------------------ | ----------------------------------------------------------- |
| Same prompt, compare multiple models | ✅ Ideal — spawn all at once, extension manages concurrency |
| Different prompts per model          | ❌ Sequential is clearer                                    |
| Sequential fallback                  | ⚠️ Extension at capacity — fall back to sequential          |
| Production agent selection           | ⚠️ Run 2-3 times each for statistical confidence            |

### Caveat: Trivial Tasks Trigger Helpful-Assistant Override

Our parallel test used a **minimal task**: `"find waybar configuration files"`.
**Both models short-circuited** to direct answers instead of following the
research protocol:

- ❌ No Discovery Summary
- ❌ No numbered questions
- ✅ Just file listings

**Lesson**: Use a **genuine research prompt** that requires architectural
analysis, not just file lookup. Good:
`"can we add a new waybar icon for sound inputs?"` (requires tracing
investigation paths). Bad: `"find X files"` (triggers direct answer mode).

## Common Pitfalls

1. **Wrong prompt format** — Using detailed instructions when the caller passes
   exact questions (or vice versa)
2. **Testing only one model** — Format compliance varies dramatically (m2.5 vs
   m2.7)
3. **Ignoring thinking level** — Default `high` isn't always optimal; test `off`
4. **Ignoring format compliance** — Fast, cheap models may skip required output
   schemas
5. **Not checking downstream compatibility** — Agent output feeds other skills;
   verify the format they expect
6. **Token blind spot** — High-token models (qwen3.5-plus at 164k vs minimax at
   6k) hurt on long sessions

## Recording Results

After benchmarking, document findings:

1. Update agent's `.md` file with winning model/thinking:
   ```yaml
   model: minimax-m2.7
   thinking: off
   ```

2. Add comment explaining choice:
   ```yaml
   # Benchmarked 2025-05-20 for research skill (exact prompt format):
   # - kimi-k2.5: good, fast, precise
   # - qwen3.5-plus: thorough but 10x tokens
   # - minimax-m2.5: breaks format with exact prompts (avoid)
   # - minimax-m2.7: best analytical depth, leanest tokens, format compliant
   # Winner: m2.7 (thinking: off) — analytical > surgical for research tracer
   ```

3. Optional: Link to detailed notes in `.agents/notes/<agent-name>-benchmark.md`

## Quick Reference: Model Characteristics

From our scope-tracer benchmark (research skill → exact prompt format):

| Model             | Format Compliance             | Speed    | Token Efficiency | Reasoning Style               | Best For                              |
| ----------------- | ----------------------------- | -------- | ---------------- | ----------------------------- | ------------------------------------- |
| kimi-k2.5         | **Strong** (exact)            | **Fast** | Good             | Surgical, precise lines       | **Codebase-analyzer, implementation** |
| qwen3.5-plus      | Strong                        | Slow     | Poor             | Thorough, exhaustive          | Deep analysis (budget allowing)       |
| minimax-m2.5      | **Weak** (exact prompt)       | Fast     | Good             | Direct, solution-oriented     | Avoid for research skills             |
| minimax-m2.7      | **Strong** (exact)            | Medium   | **Excellent**    | **Analytical, architectural** | **Research tracer**                   |
| deepseek-v4-flash | Good (improves with thinking) | **Fast** | Moderate         | Good depth, narrative-heavy   | Fast analysis when format is flexible |

## Skill-Specific Notes

### Research → Scope-Tracer

- **Prompt format**: Exact user question (`$ARGUMENTS`)
- **Output required**: Discovery Summary + 5-10 numbered questions
- **Critical for**: Downstream design/plan skills consume these questions
- **Format failure mode**: Agent answers question directly instead of producing
  questions

### Design → Codebase-Analyzer

- **Prompt format**: Dense question paragraph(s) from scope-tracer
- **Output required**: Deep analysis with file:line references
- **Critical for**: Architecture decisions in design artifact
- **Format failure mode**: Shallow answers, missing citations

### Plan → Various

- **Prompt format**: Phased instructions with success criteria
- **Output required**: Implementable plan artifact
- **Critical for**: Implementation handoff
- **Format failure mode**: Missing success criteria, non-atomic phases
