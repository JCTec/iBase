# START — Bootstrap a New App From This Template

**Audience: the AI agent.** If you are reading this file, you have been asked to start a new iOS app from this template. Follow these phases in order. Do not skip the questionnaire, and do not leave the template folder behind when done.

## Phase 1 — Read the template

Read every file in this `iOSTemplate/` folder before doing anything else:

1. `README.md` — how the template fits together
2. `01-Principles.md` — non-negotiable principles
3. `02-ProjectStructure.md` — folders, targets, naming
4. `03-CodeStyle.md` — formatting and idiom rules
5. `04-Architecture.md` — entry point, coordinator, models, MVVM-when-earned
6. `05-DesignTokens.md` — token files (copied verbatim) and color strategy
7. `06-UIPatterns.md` — view-layer patterns
8. `07-Testing.md` — tests, previews, launch flags
9. `08-Tooling.md` — App Intents, screenshot automation
10. `09-Checklist.md` — shipping checklist

These are the default rules. If project requirements conflict with a rule, flag the conflict and propose an alternative — never silently drop a rule.

## Phase 2 — Gather project info

If the user already supplied project info (a brief, a spec, or answers inline), use it and only ask about gaps. Otherwise, run a short questionnaire — use an interactive question tool if available, plain questions if not. Batch questions; don't drip one at a time.

**Required:**

1. **App name** — product name and bundle-friendly name (becomes `MyApp` everywhere).
2. **One-sentence purpose** — the single job of the app ("Focus over features": one purpose only).
3. **Primary model** — the core entity (becomes `Item`): its name, stored properties with types and defaults, and its business rules/invariants (what mutations exist, what's guarded).
4. **Screens** — which of the canonical three apply, plus any extras:
   - list/dashboard of entities?
   - immersive detail/interaction screen?
   - create/edit form (shared editor)?
   Each screen becomes a coordinator route.
5. **Primary action** — the one interaction the app exists for (gets heavy haptics, spring feedback, and an App Intent).

**Defaulted (ask only if the user wants to deviate):**

6. User-chosen colors on entities? (default yes → hex storage, presets + picker, runtime adaptive contrast; if no, skip contrast machinery)
7. Minimum iOS target (default: latest major)
8. Prominent changing numbers? (default yes → monospaced digits + numeric transitions)
9. CloudKit sync now or later? (default: later, but models CloudKit-ready)
10. Anything explicitly out of scope? (record it — scope discipline is a feature)

Confirm your summarized understanding with the user before Phase 3.

## Phase 3 — Generate app-specific documentation

Create a `docs/` folder in the project root (sibling of where the app target will live) containing the template files **rewritten for this specific app**:

- Replace every `MyApp` → the real app name, `Item` → the real model name; rewrite generic snippets (model, view model, coordinator routes, seed data) with the real properties, validations, and routes from Phase 2.
- `02` gets the real feature-folder tree; `04` gets the real coordinator enum and full model/view-model code; `07` gets seed data and the real end-to-end UI-test journey; `08` gets the real App Intent phrasing; `09` becomes the project's live checklist.
- Drop sections that don't apply (per Phase 2 answers) with a one-line note of what was dropped and why.
- Keep file numbering and names so the docs stay navigable.
- Add `docs/00-ProjectBrief.md` capturing the Phase 2 answers verbatim, including out-of-scope items.

If asked to also scaffold code, do so following the docs you just generated — docs first, code second.

## Phase 4 — Delete the template

Once the app-specific docs exist and the user confirms they look right:

1. Verify every template file has a corresponding app-specific replacement in `docs/`.
2. Delete the entire `iOSTemplate/` folder (this file included). Ask for confirmation before deleting if your environment requires approval for destructive actions.
3. Final response: list the generated docs, note any template rules that were flagged/adapted, and confirm the template folder was removed.

The end state is a project with no trace of the generic template — only app-specific documentation (and code, if requested) that fully embodies it.
