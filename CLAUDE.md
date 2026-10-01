# FST Claude Code Context Shim

`AGENTS.md` is the single L0 governance and media-safety kernel for every
harness. Follow it before this file; this shim adds no competing project
policy or startup bundle.

## Startup

- Read `AGENTS.md` and only the HOT header of `handoffs/CURRENT_HANDOFF.md`.
- Refresh branch, `HEAD`, worktree, and upstream state. Fetch before comparing
  remotes; fast-forward only when clean. Preserve dirty state.
- Search the supplied GitHub Issue and matching task-history entries. Load only
  the direct authority, role, skill, source, and tests needed for the task.
- Use CodeGraph only for production-source work or graph tooling, and only when
  available. Source, tests, repository state, and active authority docs win.

## Authority and Role

GitHub/repository state is canonical. CURRENT is an operational snapshot, not
truth or a journal. Memory and Worker output are evidence, not authority.
Preserve unknowns and contradictions. Load `FST_AI/roles/claude-primary-reviewer.md`
when assigned a review; load another focused role only when routing requires it.

## Handoff

For meaningful work, use the existing publisher and verify CURRENT, timestamped
history, and the single INDEX entry. For BRAIN-routed changes, complete one
coherent commit, push, fetch/verify upstream equality, then run the existing
exporter through `fst-brain-return-finalizer`. It is the only Desktop writer
and writes only `~/Desktop/03_FST_BRAIN.md`. Workers propose one next decision;
BRAIN owns review, classification, acceptance, and active next. Stop after the
compact exporter return.
