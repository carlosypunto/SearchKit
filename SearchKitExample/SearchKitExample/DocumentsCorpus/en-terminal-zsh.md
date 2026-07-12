---
id: en-terminal-zsh
title: Command Line Fluency
language: en
family: devops
---
Command-line fluency compounds like interest: every workflow you script stops costing attention forever after. GUIs are discoverable; the terminal is composable, and composition is where the leverage lives.

The Unix philosophy — small programs, text streams, pipes — turns one-liners into ad-hoc tools. Count the most common error types in a log: `grep ERROR app.log | cut -d: -f3 | sort | uniq -c | sort -rn`. No log-analysis product required. Redirection routes streams (`>` overwrite, `>>` append, `2>&1` merge stderr), and exit codes chain commands conditionally with `&&` and `||`.

Zsh, the macOS default shell, rewards configuration. Tab completion is programmable per tool; Ctrl+R searches history incrementally; extended globs like `**/*.swift` recurse without `find`. Your `.zshrc` accumulates aliases and functions — the moment you type a long command twice, it deserves a name.

Modernize the classic toolkit: `ripgrep` (rg) searches code respecting .gitignore at remarkable speed, `fd` is find with humane syntax, `fzf` bolts fuzzy interactive selection onto anything that emits lines — history, file pickers, git branch switchers — and `jq` queries and reshapes JSON mid-pipe.

Small habit with outsized payoff: keep a personal snippets file of one-liners that solved real problems; it becomes your private manual.
