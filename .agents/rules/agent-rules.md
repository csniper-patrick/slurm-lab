# Agent Coding Rules

These rules apply to every task in this project unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

* **Rule 1 — Think Before Coding:**
  * State assumptions explicitly. If uncertain, ask rather than guess.
  * Present multiple interpretations when ambiguity exists.
  * Push back when a simpler approach exists.
  * Stop when confused. Name what's unclear.
* **Rule 2 — Simplicity First:**
  * Minimum code that solves the problem. Nothing speculative.
  * No features beyond what was asked. No abstractions for single-use code, scripts, or configurations.
  * Test: would a senior engineer say this is overcomplicated? If yes, simplify.
* **Rule 3 — Surgical Changes:**
  * Touch only what you must. Clean up only your own mess.
  * Don't "improve" adjacent code, playbooks, comments, or formatting.
  * Don't refactor what isn't broken. Match existing style.
* **Rule 4 — Goal-Driven Execution:**
  * Define success criteria. Loop until verified.
  * Don't follow steps blindly. Define success and iterate.
  * Strong success criteria let you loop independently.
* **Rule 5 — Leverage the model's strengths:**
  * Use me for: large-scale context analysis, multi-modal data extraction, architectural drafting, and cross-file summarization.
  * Do NOT use me for: deterministic transforms, executing pipelines, or tasks where simple scripts suffice.
  * If a native tool or code can answer, let it.
* **Rule 6 — Context is vast, but focus is critical:**
  * While my context window is massive, do not unnecessarily bloat it with irrelevant logs or unrelated data dumps.
  * If the project shifts to a completely new domain, summarize the current state and start fresh to maintain absolute precision.
  * Surface any context drift. Do not silently lose track of the core objective.
* **Rule 7 — Surface conflicts, don't average them:**
  * If two patterns or configurations contradict, pick one (more recent / more tested).
  * Explain why. Flag the other for cleanup.
  * Don't blend conflicting architectures or patterns.
* **Rule 8 — Read before you write:**
  * Before adding code, read exports, immediate callers, shared utilities, and relevant deployment pipelines.
  * "Looks orthogonal" is dangerous. If unsure why code or infrastructure is structured a certain way, ask.
* **Rule 9 — Tests verify intent, not just behavior:**
  * Tests (and CI checks) must encode WHY behavior matters, not just WHAT it does.
  * A test that can't fail when business logic or system state changes is wrong.
* **Rule 10 — Checkpoint after every significant step:**
  * Summarize what was done, what's verified, what's left.
  * Don't continue from a state you can't describe back.
  * If you lose track of the state, stop and restate.
* **Rule 11 — Match the project's conventions, even if you disagree:**
  * Conformance > taste inside the repository.
  * If you genuinely think a convention is harmful, surface it. Don't fork silently or introduce divergent setups.
* **Rule 12 — Fail loud:**
  * "Completed" is wrong if anything was skipped silently.
  * "Pipelines pass" is wrong if any checks were bypassed.
  * Default to surfacing system errors and uncertainty, not hiding them.

