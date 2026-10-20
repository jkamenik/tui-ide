# tui-ide-ADR-0037: Model capability testing via `check-models` and an OpenCode skill

**Status:** Accepted
**Date:** 2026-10-20

## Context

Different machines and networks have access to different AI models and providers
(e.g., Bifrost at Censys, OpenCode Go on personal machines, or local gateways).
Discovery endpoints often expose hundreds of models (over 800 on Bifrost), many
of which fail due to guardrail policies, missing provider API keys, non-chat
modalities (embeddings, TTS), or lack of tool-calling support required by agent
workflows.

Testing hundreds of models individually wastes tokens, quota, and time.
Furthermore, choosing optimal models across task types (fast subagents, daily
drivers, complex reasoning) requires comparing actual gateway token pricing and
context limits against verified capabilities.

## Decision

1. Deliver `check-models` as a standalone Node.js script in `bin/check-models`
   (on `$PATH` via [ADR-0033](0033-repo-scripts-in-bin-on-path.md)), with an
   accompanying OpenCode skill stowed under
   `dotfiles/opencode-agents/.config/opencode/skills/check-models/SKILL.md`.
2. Group candidate models into classes (e.g. `openrouter/deepseek`,
   `vertex/claude`, `vertex/gemini`, `mimo`, `minimax`) and test the cheapest
   chat-eligible model first as a canary. If the canary fails (401/403 auth,
   404 route, quota exceeded, guardrail block), mark the entire class as failed
   and skip remaining models.
3. Verify models across capability tiers:
   - Level 1: Chat completion ping.
   - Level 2: Structured tool calling (`get_weather` test). Required for agent
     recommendations.
   - Level 3: Full OpenCode CLI harness (`opencode run`).
4. Persist test results incrementally in `~/.cache/opencode/model-test-cache.json`
   (machine-local, untracked per Convention 4). Default runs skip unchanged
   cached models; `--force` rechecks all.
5. Provide `check-models report` to generate a markdown shortlist of the top
   3–5 models giving the highest bang for the buck across three archetypes:
   Subagent, Daily Driver, and Heavy Reasoning.
6. Provide `check-models configure` to update machine-owned
   `~/.config/opencode/opencode.jsonc` (backing it up first per Convention 3) so
   OpenCode's dynamic discovery only exposes verified working models.

## Consequences

### Positive

- Identifies working models in seconds using class-canary fail-fast logic rather
  than making hundreds of doomed API requests.
- Ranks models objectively based on verified Level 2+ tool support and exact
  gateway token pricing ($/M tokens) rather than guesswork.
- Works across different providers (Bifrost, OpenCode Go, generic
  OpenAI-compatible endpoints).
- Seamlessly accessible both as a shell command and as an OpenCode skill.

### Negative

- Requires Node.js (already part of the standard developer toolchain on all
  supported machines).
- Provider pricing schemas vary; fallback heuristics are needed when endpoints
  do not report inline pricing.

### Neutral

- Cache state is machine-local and not shared across devices.

## See Also

- [ADR-0030](0030-stow-the-global-opencode-agents-md.md): Stow the global opencode AGENTS.md
- [ADR-0033](0033-repo-scripts-in-bin-on-path.md): Repo helper scripts in `bin/` on `$PATH`
- [ADR-0035](0035-machine-owned-config-includes-tracked-config.md): Machine-owned config includes tracked config
