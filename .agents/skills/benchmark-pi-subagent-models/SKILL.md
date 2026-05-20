---
name: benchmark-pi-subagent-models
description: Benchmark LLM models for pi subagents to find optimal model and thinking level. Supports sequential and parallel benchmarking with format compliance testing.
---

# Benchmark pi Subagent Models

Find the optimal model and thinking level for a specific pi subagent.

## When to Use

- Adding a new subagent — unsure which model to default
- Existing agent producing inconsistent / low-quality results
- Validating if a newer/cheaper model can replace current default
- Troubleshooting format compliance (agent answers instead of researching)

## Prerequisites

- Agent definition exists at `~/.pi/agent/agents/<agent-name>.md`
- Know which skill invokes this agent (determines prompt format)
- Representative task matching that skill's calling pattern
- Multiple candidate models to test
- **For two-step agents** (e.g. `artifacts-locator` → `artifacts-analyzer`):
  test the full calling pattern

> **Note:** This skill's prompt format is determined by the **caller skill**,
> not the agent itself. See [Skill-Specific Notes](#skill-specific-notes).

## Candidate Models

| Model                 | Strengths                                  | Try When                                                               |
| --------------------- | ------------------------------------------ | ---------------------------------------------------------------------- |
| **kimi-k2.5**         | Best format compliance, surgical precision | Agent feeds downstream skills needing exact schema, adversarial review |
| **minimax-m2.7**      | Leanest tokens, analytical depth           | Research/analysis agents, cost-sensitive pipelines                     |
| **deepseek-v4-flash** | Fastest raw speed, decent depth            | Speed matters more than schema precision                               |
| qwen3.5-plus          | Exhaustive, thorough                       | Budget allows, need maximum depth                                      |
| minimax-m2.5          | Fast, cheap                                | Prompt sensitivity — test before committing                            |

See [RESULTS.md](RESULTS.md) for full historical benchmark data.

## Process

### 1. Identify the Caller Skill and Prompt Format

Agents are invoked from **two locations** in the rpiv-pi extension:

- `skills/<name>/SKILL.md` — skill definitions that dispatch agents
- `agents/<name>.md` — other agent definitions that dispatch agents

Find the rpiv-pi extension directory, then search **both** locations:

```bash
rpiv_dir=$(find /nix/store -maxdepth 1 -type d -name '*-rpiv-pi-patched' 2>/dev/null | head -1)
grep -r "<agent-name>" "$rpiv_dir/skills/" "$rpiv_dir/agents/"
```

Look for `Agent({ subagent_type: "<your-agent>" ... })` calls and inspect the
`prompt:` value. If the call is in a skill file, also read that skill's SKILL.md
for context on how the prompt is constructed.

### 2. Prepare the Benchmark Prompt

- Match the caller skill's prompt format exactly
- Exercise the agent's core responsibilities
- Must be **identical across all model variants**
- **Present the prompt to the user for review before running** — format
  dramatically affects results

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

### 4. Run Benchmark Iteration (Sequential)

Each agent reads `model` and `thinking` from its `.md` file at spawn time
(rpiv-pi's agent dispatch ignores `model`/`thinking` on the `Agent` tool call).
Edit the config, then dispatch:

```
Agent({
  subagent_type: "<agent-name>",
  description: "Benchmark <model> <thinking>",
  prompt: "<test prompt matching caller skill format>"
})
```

Edit the `.md` file again with the next model/thinking and dispatch again.

Capture per run: **Time**, **Tool uses**, **Tokens**, **Format compliance**,
**Quality**.

### 5. Evaluate Results

| Dimension   | What to Check                            | Why It Matters                        |
| ----------- | ---------------------------------------- | ------------------------------------- |
| **Speed**   | Duration, tool uses                      | Throughput in pipelines               |
| **Tokens**  | Output token count, context usage        | Cost and context pressure             |
| **Format**  | Follows agent's output schema?           | Downstream skills depend on structure |
| **Quality** | Analytical depth, citations, correctness | Value of the analysis                 |

### 6. Select Winner

Weight by the agent's role:

| Agent Role                          | Prioritize                           |
| ----------------------------------- | ------------------------------------ |
| Research tracer (`scope-tracer`)    | Format compliance, analytical depth  |
| Code analyzer (`codebase-analyzer`) | Format compliance, precise citations |
| Design / plan generator             | Balanced depth + precision           |
| Cost-sensitive deployments          | Token efficiency, speed              |

## Advanced: Parallel Benchmarking

Spawn **all benchmark runs at once** — multiple `Agent` tool calls in the same
assistant message. The pi-subagents extension manages concurrency (typically max
4 concurrent, excess queued).

### Technique

Each agent loads its model config from the `.md` file at spawn time and keeps it
for the duration. This means you can:

1. **Set Model A** in `~/.pi/agent/agents/<agent>.md`
2. **Spawn Agent A** with `run_in_background: true` via the `Agent` tool (no
   `model`/`thinking` params — rpiv-pi ignores those)
3. **Immediately change to Model B** in the config file
4. **Spawn Agent B** (also `run_in_background: true`) — extension queues if at
   capacity
5. Repeat for all models
6. **Retrieve results** from each agent as they complete

Each agent keeps its originally-loaded model even though the config file changed
between spawns.

### Example: All 5 benchmark runs at once

```
# 1. Edit ~/.pi/agent/agents/codebase-analyzer.md → model: kimi-k2.5, thinking: high
Agent({
  subagent_type: "codebase-analyzer",
  description: "Benchmark kimi-k2.5 high",
  prompt: "<test prompt>",
  run_in_background: true
})

# 2. Edit config → model: deepseek-v4-flash, thinking: off
Agent({
  subagent_type: "codebase-analyzer",
  description: "Benchmark deepseek-v4-flash off",
  prompt: "<test prompt>",
  run_in_background: true
})

# 3. Edit config → model: minimax-m2.7, thinking: off
Agent({
  subagent_type: "codebase-analyzer",
  description: "Benchmark minimax-m2.7 off",
  prompt: "<test prompt>",
  run_in_background: true
})

# 4. Edit config → model: deepseek-v4-flash, thinking: high
Agent({
  subagent_type: "codebase-analyzer",
  description: "Benchmark deepseek-v4-flash high",
  prompt: "<test prompt>",
  run_in_background: true
})

# 5. Edit config → model: deepseek-v4-flash, thinking: xhigh
Agent({
  subagent_type: "codebase-analyzer",
  description: "Benchmark deepseek-v4-flash xhigh",
  prompt: "<test prompt>",
  run_in_background: true
})
```

**Important**: The `# Edit config → ...` comments are instructions to you (the
agent running this skill), not shell commands. You edit the `.md` file between
each `Agent()` dispatch.

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

1. **Wrong prompt format** — Using detailed instructions when caller passes
   exact questions (or vice versa)
2. **Testing only one model** — Format compliance varies dramatically across
   models
3. **Ignoring thinking level** — Default `high` isn't always optimal; test `off`
4. **Trivial prompts trigger direct answers** — Use genuine research prompts
   requiring analysis, not simple file lookups
5. **Not checking downstream compatibility** — Agent output feeds other skills;
   verify their expected format

## Recording Results

After benchmarking, update [RESULTS.md](RESULTS.md)
