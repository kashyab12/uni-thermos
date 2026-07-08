---
name: thermo-nuclear-code-quality-review
description: "Run an unusually strict structural code quality review for maintainability, abstraction quality, file growth, spaghetti conditionals, boundary leaks, and missed simplifications. Use for thermo-nuclear review, thermonuclear review, harsh code quality audit, deep maintainability review, PR structure review, branch quality review, or when a user asks whether an implementation should be simpler before approval."
---

# Thermo-nuclear code quality review

This skill audits a branch, PR, diff, or changed files with a high bar for maintainability. Its job is to find structural regressions and missed simplifications, not cosmetic nits.

## Host protocol

1. Identify the review target. Prefer the current branch against its base. If no base is obvious, inspect git remotes and branch history before choosing.
2. In Codex, use native Codex subagents when available for independent review coverage. Keep workers read-only.
3. In Claude Code, usually delegate the review to Codex CLI unless the user explicitly asks to keep the review inside Claude. Use `scripts/spawn-codex-reviewer.sh` from this skill.
4. Use `codex review --uncommitted`, `codex review --base <branch>`, or a read-only `codex exec` worker when that fits the target better.
5. Inspect the diff yourself after any worker returns. Worker output is evidence, not the final answer.

Claude Code default:

```bash
thermo-nuclear-code-quality-review/scripts/spawn-codex-reviewer.sh \
  --cwd "$PWD" \
  --base main \
  --output ".pstack/workers/thermo-review.md"
```

Use `--target uncommitted` for unstaged or staged local changes. Use `--prompt "extra focus"` to add user-specific review scope.

## Update installed skill

When asked to update this skill, uni-thermos, or installed copies, prefer:

```bash
thermo-nuclear-code-quality-review/scripts/update-self.sh
```

From a source checkout, use:

```bash
./install.sh --update
```

Narrow the target only when requested:

```bash
./install.sh --update --codex
./install.sh --update --claude
```

## Review workflow

1. Read the changed files and the surrounding code that owns the same concepts.
2. Measure file growth. Treat a file crossing 1000 lines as a presumptive design problem.
3. Trace new conditionals, flags, optional fields, casts, wrappers, and helper layers back to the invariant they claim to model.
4. Search for existing canonical helpers, ownership boundaries, state models, and modules before accepting bespoke code.
5. Ask whether a smaller structure could preserve behavior while deleting concepts, branches, helpers, modes, or layers.
6. Report only findings that change an approval decision or materially improve maintainability.

## Review bar

Presume a finding is blocking when the diff:

- Preserves incidental complexity when a clear simplification could delete it.
- Pushes a file from under 1000 lines to over 1000 lines without a strong reason.
- Adds ad-hoc branches, scattered special cases, nullable modes, or one-off booleans into busy flows.
- Solves a local feature by leaking logic into a shared layer or the wrong package.
- Adds thin wrappers, identity abstractions, generic magic, casts, `any`, `unknown`, or optionality that hides the real invariant.
- Duplicates an existing helper or bypasses the canonical owner for a concept.
- Serializes independent work or creates partial-update paths where a clearer atomic structure is obvious.

Do not approve merely because behavior appears correct. Approve only when there is no obvious structural regression, no missed high-value simplification, no unjustified file-size growth, no spaghetti condition growth, and no boundary or abstraction drift that will make the next change harder.

## Questions to ask

- Is there a code-judo move that makes this dramatically simpler?
- Can the behavior stay the same while fewer concepts exist?
- Did the change make the local architecture better or worse?
- Did repeated conditionals reveal a missing model, helper, policy object, state machine, or dispatcher?
- Is the logic in the canonical layer?
- Did a cohesive module become more coupled, more stateful, or harder to scan?
- Does the abstraction earn its keep?
- Did the diff add casts, optionality, or ad-hoc object shapes instead of naming the invariant?
- Could independent orchestration run in parallel without making the code harder to reason about?
- Could related updates become more atomic?

## Preferred remedies

Prefer remedies that remove structure:

- Delete a layer of indirection instead of polishing it.
- Reframe the state model so branches disappear.
- Move ownership so the feature becomes a natural extension of an existing abstraction.
- Turn special cases into a simpler default flow.
- Split a large file into focused modules.
- Move feature-specific logic behind a dedicated abstraction.
- Replace condition chains with a typed model or explicit dispatcher.
- Separate orchestration from business logic.
- Collapse duplicate branches into one clear flow.
- Reuse the canonical helper.
- Make type boundaries explicit.
- Parallelize independent work when it also clarifies orchestration.
- Make related updates atomic when partial state is harder to reason about.

## Output

Lead with findings. Order them by severity.

For each finding include:

- File and line.
- Why this harms maintainability.
- The simpler structure to prefer.
- Whether it should block approval.

Keep the list short. High-conviction structural comments beat a long list of nits.

If there are no blocking findings, say that clearly and name the residual risks or test gaps.

Useful phrasing:

- `this pushes the file past 1000 lines. can we decompose this first?`
- `this adds another special-case branch into an already busy flow. can we move it behind its own abstraction?`
- `this works, but it makes the surrounding code more tangled. keep the behavior and restructure the implementation.`
- `this feels like feature logic leaking into a shared path. can we isolate it?`
- `this abstraction seems unnecessary. can we keep the direct flow?`
- `why does this need a cast or optional here? can we make the boundary explicit instead?`
- `this looks like a bespoke helper for something the codebase already owns. can we reuse the canonical one?`
