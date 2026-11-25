#!/usr/bin/env bash
#
# Claude Code PreToolUse hook: nudge the model to use the toolsmith instead of
# writing a helper script (ADR-0049).
#
# It WARNS ONLY. It always exits 0 and never sets a permission decision, so the
# tool call proceeds. When the call looks like a helper script it prints a JSON
# `additionalContext` message the model reads before the tool runs. Any error,
# a missing jq, or TOOLSMITH_NUDGE=0 in the environment makes it a silent no-op.
#
# What counts as "looks like a script":
#   Bash   a heredoc (except for git commit / gh pr / gh issue bodies); an inline
#          interpreter program (python -c, node -e, perl -e, ruby -e) longer than
#          5 lines or 300 characters; or a shell loop in a command of more than
#          5 lines.
#   Write  a script file (shebang, or .sh .py .pl .rb .js .mjs .ts) written to a
#          scratch location (a scratchpad, /tmp, /private/tmp, /var/folders).
# Scripts that ship with a project (scripts/, tests, Taskfile) are mission work;
# the warning says so and the model decides.

set -u

[ "${TOOLSMITH_NUDGE:-1}" = "0" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)" || exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)" || exit 0
reason=""

case "$tool" in
  Bash)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
    [ -n "$cmd" ] || exit 0
    lines="$(printf '%s\n' "$cmd" | wc -l | tr -d ' ')"
    chars="${#cmd}"

    # A heredoc is `<<` (not the here-string `<<<`) followed by an optional `-`
    # and a delimiter word. Commit and PR text legitimately uses one.
    heredoc_re='<<-?[[:space:]]*["'"'"'\\]?[A-Za-z_]'
    mission_re='(^|[[:space:];&|(])(git[[:space:]]+commit|gh[[:space:]]+(pr|issue|release)[[:space:]])'
    interp_re='(^|[[:space:];&|(])(python[0-9.]*|node|perl|ruby)[[:space:]]+(-[A-Za-z]*[ce][A-Za-z]*)[[:space:]]'
    loop_re='(^|[;&|[:space:]])(for|while|until)[[:space:]].*;?[[:space:]]*do([[:space:];]|$)'

    if [[ $cmd =~ $heredoc_re ]] && ! [[ $cmd =~ $mission_re ]]; then
      reason="a heredoc"
    elif [[ $cmd =~ $interp_re ]] && { [ "$lines" -gt 5 ] || [ "$chars" -gt 300 ]; }; then
      reason="an inline interpreter program ($lines lines, $chars chars)"
    elif [[ $cmd =~ $loop_re ]] && [ "$lines" -gt 5 ]; then
      reason="a shell loop in a $lines-line command"
    fi
    ;;
  Write)
    path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
    [ -n "$path" ] || exit 0
    content_head="$(printf '%s' "$input" | jq -r '.tool_input.content // empty' 2>/dev/null | head -n 1)" || true
    scratch_re='(/scratchpad/|^/tmp/|^/private/tmp/|^/var/folders/|^/private/var/folders/)'
    script_ext_re='\.(sh|bash|zsh|py|pl|rb|js|mjs|cjs|ts)$'
    if [[ $path =~ $scratch_re ]] && { [[ $path =~ $script_ext_re ]] || [[ $content_head == '#!'* ]]; }; then
      reason="a script file written to a scratch directory ($path)"
    fi
    ;;
  *)
    exit 0
    ;;
esac

[ -n "$reason" ] || exit 0

msg="Note from the user's toolsmith hook: this tool call looks like a helper script ($reason). The user's standing rule (global CLAUDE.md) is that helper scripts that are not part of the project's deliverable come from the toolsmith: search ~/.local/share/toolsmith/tools/CATALOG.md, then use a match or brief the toolsmith:toolsmith agent (toolsmith:writing-tools skill). Scratch and temp directories are for data only, never code. Scripts, tests, build glue and Taskfile tasks that ship in the project's own repo, and commit-message heredocs, are not covered by the rule. The call is not blocked."

jq -n --arg msg "$msg" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
exit 0
