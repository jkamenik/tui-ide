# Global Rules

## AI Attribution in Git Commits

When you create a git commit for work you contributed to, add a trailer to the
commit message identifying the AI, in this format:

```
Assisted-by: LLM <model> <agent-tool> [TOOL1] [TOOL2]
```

- `<model>` — the model that performed the work (e.g. `deepseek-v4.1-flash`,
  `claude-opus`). Use the model you are actually running as.
- `<agent-tool>` — the AI agent/CLI used (e.g. `opencode`, `claude-code`).
- `[TOOL1] [TOOL2]` — optional specialized analysis tools used, e.g.
  `coccinelle`, `sparse`, `smatch`, `clang-tidy`.

Do NOT list basic development tools (git, gcc, make, editors).

Only add this trailer when the commit includes AI-assisted changes, and only
when the user has asked you to commit. Place it after any other trailers
(e.g. `Signed-off-by`).

Example:

```
Assisted-by: LLM deepseek-v4.1-flash opencode
```
