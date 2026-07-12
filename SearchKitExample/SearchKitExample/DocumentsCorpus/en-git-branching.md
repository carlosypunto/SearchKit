---
id: en-git-branching
title: Branching, Merging and Rebasing
language: en
family: devops
---
Because a Git branch is only a pointer, branching is free — and modern workflows exploit that: short-lived branches per change, integrated through pull requests, deleted after merge. The interesting decisions are about integration.

Merging preserves truth: a merge commit with two parents records that histories converged. Rebasing rewrites your commits on top of the target branch, producing linear history that reads like a story. Both are legitimate; teams choose their trade-off between forensic accuracy and readability. The one hard rule: never rebase commits that exist on a shared remote — rewriting published history strands every collaborator who built on it.

Conflicts are overlapping edits awaiting human judgment, not failures. Git fences the disputed lines; you decide, stage, and continue. Frequent integration keeps conflicts small — a week of divergence buys an afternoon of archaeology.

The precision toolkit: `cherry-pick` transplants a single commit (the hotfix workflow), `stash` shelves uncommitted work for a quick context switch, and interactive rebase squashes the "fix typo" noise into coherent commits before review. `git bisect` deserves fame — binary search over history that finds the commit introducing a bug in logarithmic steps, automated with a test script.

Guiding principle: curate history before publishing; respect it afterwards.
