---
name: Check Models
description: Test and verify working models across configured providers, generate bang-for-buck model recommendations, and filter OpenCode model discovery
metadata:
  opencode/autoinvoke: true
---

# Skill: Check Models

Use this skill when the user asks to:
1. Test which models work on the current machine or network.
2. Generate a "bang for the buck" model report with top recommendations.
3. Filter or configure OpenCode to only discover/show verified models.
4. Diagnose model availability, rate limits, or tool-calling support.

## Core Script

The standalone CLI script is installed on `$PATH` at `bin/check-models`.
It runs directly in the terminal or can be invoked via the shell tool:

```bash
check-models [command] [options] [pattern]
```

### Key Workflows

#### 1. Test Available Models (Incremental)
To test newly discovered or untested models:
```bash
check-models
```

To test a specific class or namespace:
```bash
check-models "vertex/*"
check-models "openrouter/deepseek*"
check-models "mimo*"
```

To run a fast canary sweep across all classes without testing every variant:
```bash
check-models --canary-only
```

To force a recheck of all models (ignoring cached results):
```bash
check-models --force
```

#### 2. Generate Bang-for-the-Buck Recommendations
To produce a markdown report ranking verified models across 3 core archetypes
(Subagent, Daily Driver, Heavy Reasoning) based on gateway token pricing and context limits:
```bash
check-models report
```

#### 3. Configure OpenCode Discovery Whitelist
To configure OpenCode (`~/.config/opencode/opencode.jsonc`) so that dynamic discovery
only shows models that passed Level 2+ tool calling:
```bash
# Preview changes first
check-models configure --dry-run

# Apply changes (creates automatic timestamped backup first)
check-models configure
opencode service restart
```

#### 4. Inspect or Reset Cache
```bash
# View all tested models, statuses, and capability levels
check-models list

# Clear cache to start fresh
check-models clean
```

## Capability Levels

- **Level 1 (Chat Ping):** Validates authentication, network route, and basic response.
- **Level 2 (Tool Calling):** Validates structured function calling (`get_weather` test). Required for OpenCode agent workflows.
- **Level 3 (OpenCode Harness):** Validates invocation through `opencode run -m <model>`.

## Fail-Fast Canary Strategy

Models are grouped into classes (e.g., `openrouter/deepseek`, `vertex/claude`, `vertex/gemini`, `mimo`, `minimax`). The cheapest chat-eligible model is tested first as the canary. If the canary fails due to permissions, guardrail policies, route 404, or missing upstream keys, the entire class is marked failed and skipped, sparing time, quota, and rate limits.
