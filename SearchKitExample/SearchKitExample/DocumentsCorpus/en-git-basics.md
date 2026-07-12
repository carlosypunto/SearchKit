---
id: en-git-basics
title: Git Mental Models
language: en
family: devops
---
Git stops feeling arcane once you see its data model: a graph of immutable snapshots. Every commit stores a complete tree of the project plus pointers to parent commits; branches are just movable labels on nodes of that graph. Nearly everything Git does is manipulating labels and adding nodes — destruction is rare and recovery is usually possible.

Day-to-day flow crosses three areas. The working directory holds your edits; the staging area (index) holds what `git add` selected for the next snapshot; `git commit` turns the stage into a permanent node. Staging exists so commits can be deliberate — commit the bug fix separately from the drive-by rename, and reviewers and future bisects will thank you.

`git status` tells you where you stand, `git diff` compares any two of the three areas, and `git log --graph --oneline` shows the actual shape of history. Remotes add a publishing layer: `fetch` downloads without touching your work, `pull` is fetch plus integrate, `push` uploads your label positions.

Write commit messages as documentation: imperative summary line under fifty characters, blank line, then the why — the diff already shows the what.

Safety net for the anxious: `git reflog` records every position HEAD has held; almost nothing committed is ever truly lost.
