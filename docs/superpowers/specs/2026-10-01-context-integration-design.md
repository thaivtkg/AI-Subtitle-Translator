# P3B.4 Context Integration — Design Spec v1

**Status:** Draft — awaiting user review
**Date:** 2026-10-01
**Scope:** Phase 3B.4 only
**Depends on:**
- P3B.1 Glossary (CLOSED / LOCKED / MERGED — `9de6cba`)
- P3B.2 Entity Dictionary (CLOSED / LOCKED / MERGED — `bf52573`)
- P3B.3 Translation Memory (CLOSED / LOCKED / MERGED — `a24e481`)

## 1. Intent and success criteria

Connect the three Translation Intelligence pillars (Glossary, Entity Dictionary,
and Translation Memory) directly into the translation execution pipeline.
This represents the final capstone of Phase 3B: translating subtitle text with
strict adherence to project-scoped terminology, named entities, and instant
reuse of verified translations.

Success means:

- **Instant TM Short-Circuit:** Subtitles with a 100% exact match in
  `TranslationMemory` bypass LLM inference completely, returning the cached
  target text with zero thread overhead and zero token cost.
- **Asynchronous Safety:** Short-circuit completions emit signals via
  `QTimer.singleShot(0, ...)` to respect the Qt event loop and prevent race
  conditions with `TranslationPipelineAdapter._pending`.
- **Authoritative Status Invariant:** Both TM short-circuit and LLM generation
  mark subtitles as `TRANSLATED`. No automatic transition to `ACCEPTED` is
  permitted; human approval remains authoritative.
- **Selective Injection:** Only glossary terms and entities that actually match
  the current subtitle are injected into the system prompt. Unmatched project
  data is excluded to save context window and avoid hallucination.
- **Forbidden Alternatives Enforcement:** Activates the deferred P3B.1 contract
  by explicitly commanding the LLM `(ABSOLUTELY FORBIDDEN: ...)` for terms with
  forbidden synonyms.
- **Entity Identity Mapping:** Entities matched by alias clearly identify both
  the matched form and the canonical entity name and type.
- **Clean Decoupling:** `TranslationController` accepts an optional
  `bind_intelligence(glossary, entities, tm)` dependency injection. When
  unbound, fallback behavior is 100% backward compatible with existing tests.

## 2. Verified repository context

- `app/controllers/project_controller.py` owns the active instances:
  `self.glossary`, `self.entity_dictionary`, `self.translation_memory`.
- `app/controllers/translation_controller.py` owns `requestTranslation(index, ...)`,
  which serves as the sole chokepoint for both single-line UI translation and
  batch translation (`TranslationPipelineAdapter`).
- `app/core/prompt_builder.py` builds the ChatML prompt `<|im_start|>system`
  and `<|im_start|>user` sections. Currently, it includes general rules and
  Vietnamese-specific localization rules.
- `app/llm/worker.py` is a `QThread` designed specifically for heavy I/O and
  streaming LLM tokens from GGUF/Ollama backends.
- `app/services/translation_pipeline_adapter.py` listens to
  `controller.translationCompleted` and `controller.translationFailed`. It sets
  `self._pending = (target_index, ...)` right before calling
  `requestTranslation`.

## 3. Design decisions

### 3.1 Integration Point and Ownership

The orchestration of intelligence lives in `TranslationController`, not in
`TranslationWorker`:

- Placing TM short-circuiting in `TranslationController` eliminates the
  overhead of spawning an unnecessary OS worker thread.
- `TranslationController` receives intelligence instances via dependency
  injection:
  ```python
  def bind_intelligence(self, glossary=None, entities=None, translation_memory=None):
      self._glossary = glossary
      self._entities = entities
      self._translation_memory = translation_memory
  ```
- If any intelligence parameter is `None`, it defaults to empty/inactive,
  preserving 100% backward compatibility for standalone tests and harnesses.
- In `main.py` and `AppHarness`, wiring is established simply:
  ```python
  translation_controller.bind_intelligence(
      project_controller.glossary,
      project_controller.entity_dictionary,
      project_controller.translation_memory
  )
  ```

### 3.2 Translation Memory Short-Circuit Contract

When `requestTranslation(index, source_lang, target_lang, story_summary)` is
called:

1. Retrieve the source text: `current_sub = subtitles[index].get("original", "")`.
2. If `self._translation_memory` is present:
   ```python
   hit = self._translation_memory.lookup(current_sub)
   ```
3. If `hit` is found (100% exact match):
   - Update model immediately:
     `self._subtitle_model.update_translation(index, hit.target_text, "TRANSLATED")`
   - Update controller internal state:
     `self._status = "TRANSLATED"`
     `self._current_translation = hit.target_text`
     `self._set_engine_status("Ready")`
   - Emit signals deferred via `QTimer.singleShot(0, ...)`:
     - `self.translationUpdated.emit(hit.target_text)`
     - `self.statusChanged.emit("TRANSLATED")`
     - `self.translationCompleted.emit(index)`
   - **Return immediately.** No `TranslationWorker` is instantiated or started.

### 3.3 Prompt Builder Intelligence Extension

`PromptBuilder.build` signature is extended with optional parameters:
```python
@staticmethod
def build(story_summary: str, source_lang: str, target_lang: str,
          prev_context: list, current_sub: str, next_context: list,
          glossary_hits: tuple = (), entity_hits: tuple = ()) -> str:
```

When `glossary_hits` or `entity_hits` are non-empty, a dedicated
`PROJECT-SPECIFIC TRANSLATION RULES` section is appended to the `system_prompt`
immediately following `GENERAL RULES`:

```text
PROJECT-SPECIFIC TRANSLATION RULES (MANDATORY):
You must strictly follow these rules for the matching terms and entities in this subtitle:

[GLOSSARY]
- "source_term" MUST be translated as "preferred_translation".
- "source_term_2" MUST be translated as "preferred_translation_2". (ABSOLUTELY FORBIDDEN: "forbidden_1", "forbidden_2")

[ENTITIES]
- "matched_form" (CHARACTER, canonical name: "Tony Stark") MUST be translated as "Tony Stark".
- "Wakanda" (LOCATION, canonical name: "Wakanda") MUST be translated as "Wakanda".
```

#### Formatting Constraints:
- Terms and entities are sorted deterministically by hit `start` position.
- If `forbidden_alternatives` is non-empty on a `GlossaryHit` (queried from
  Glossary entry), the `(ABSOLUTELY FORBIDDEN: ...)` constraint is appended.
- If no glossary hits exist, the `[GLOSSARY]` subsection is omitted.
- If no entity hits exist, the `[ENTITIES]` subsection is omitted.
- If both are empty, the entire `PROJECT-SPECIFIC TRANSLATION RULES` block is
  omitted (maintaining 100% byte-for-byte fidelity with pre-P3B.4 prompts).

### 3.4 Matcher Flow on TM Miss

When TM lookup returns `None`:

1. Run Glossary matcher:
   `glossary_hits = self._glossary.match(current_sub) if self._glossary else ()`
2. Run Entity matcher:
   `entity_hits = self._entities.match(current_sub) if self._entities else ()`
3. Retrieve forbidden alternatives for each glossary hit by querying
   `self._glossary.get(hit.source_term)`.
4. Call `PromptBuilder.build(..., glossary_hits=enriched_glossary_hits, entity_hits=entity_hits)`.
5. Instantiate and start `TranslationWorker` with the augmented prompt.

## 4. Persistence and atomicity

P3B.4 does not alter the `.aisrt` file schema or batch checkpoint schema:
- `.aisrt` continues to serialize `intelligence.glossary`,
  `intelligence.entities`, and `intelligence.translation_memory` as locked in
  P3B.1–P3B.3.
- Batch checkpoints remain 100% isolated and contain no intelligence data.
- Atomic load staging in `ProjectController` remains untouched.

## 5. Impact and failure preview

| Failure | Cause | Impact | Detection/recovery |
| --- | --- | --- | --- |
| Synchronous signal race | Immediate `emit` inside `requestTranslation` | Batch adapter misses completion; pipeline hangs | Use `QTimer.singleShot(0, ...)` for TM hits |
| Prompt bloat | Injecting entire dictionary instead of hits | Token exhaustion, slower inference, hallucination | Assert only matched hits appear in prompt |
| False positive substring TM | Using substring lookup instead of exact `==` | Wrong sentence translated | Verify TM uses exact whole-string equality |
| Broken regression | PromptBuilder signature breaking older callers | Existing tests crash | Optional default arguments `glossary_hits=(), entity_hits=()` |
| Status corrupted | TM hit sets status to `ACCEPTED` | Violates user-authoritative invariant | Assert status is strictly `TRANSLATED` |
| Thread leak | Worker thread launched on TM hit | Unnecessary VRAM/CPU usage | Assert no worker is created when TM hits |

## 6. Acceptance contract

The following 14 test groups define the reviewable P3B.4 contract:

| ID | Acceptance group | Required behavior |
| --- | --- | --- |
| TC-P3B4-01 | TM short-circuit hit | Source text exactly matching TM returns target text immediately without invoking worker/LLM. |
| TC-P3B4-02 | TM deferred signal timing | Signals `translationCompleted` and `translationUpdated` fire asynchronously via event loop (`QTimer.singleShot(0)`). |
| TC-P3B4-03 | Status invariant on TM hit | TM short-circuit marks subtitle status as `TRANSLATED`, never `ACCEPTED`. |
| TC-P3B4-04 | Zero worker overhead | No `TranslationWorker` instance or QThread is started when TM hits. |
| TC-P3B4-05 | TM miss proceeds to matchers | When TM has no exact match, flow proceeds to Glossary/Entity matching and LLM worker invocation. |
| TC-P3B4-06 | Glossary prompt injection | Matched glossary hits are formatted into the system prompt under `[GLOSSARY]`. |
| TC-P3B4-07 | Forbidden alternatives clause | When a matched glossary term has forbidden alternatives, `(ABSOLUTELY FORBIDDEN: ...)` is appended to its prompt line. |
| TC-P3B4-08 | Entity prompt injection | Matched entity hits (name or alias) are formatted under `[ENTITIES]` showing `matched_form`, `entity_type`, `canonical_name`, and `canonical_translation`. |
| TC-P3B4-09 | Selective injection only | Only terms/entities appearing literally in `current_sub` are injected; unreferenced entries are omitted. |
| TC-P3B4-10 | Deterministic hit ordering | Injected glossary and entity rules appear in deterministic ascending order of start position. |
| TC-P3B4-11 | Backward compatibility fallback | When no intelligence is bound (or empty hits), generated prompt is identical to baseline (no project rules header). |
| TC-P3B4-12 | Coexistence in prompt | A subtitle containing both glossary terms and entities contains both formatted sections cleanly. |
| TC-P3B4-13 | Batch pipeline integration | Batch translation seamlessly benefits from TM short-circuiting and intelligence prompt injection via `TranslationPipelineAdapter`. |
| TC-P3B4-14 | Unbound controller safety | `TranslationController` functions normally without error when `bind_intelligence` has not been called. |

## 7. Verification strategy for implementation

1. **Unit Tests (`tests/test_context_integration.py`):**
   - PromptBuilder formatting tests:
     - Prompt with glossary hits (with and without forbidden alternatives).
     - Prompt with entity hits (name matches and alias matches).
     - Prompt with combined hits.
     - Backward compatibility: prompt without hits matches baseline.
   - TranslationController intelligence orchestration tests:
     - TM short-circuit: verifies status `TRANSLATED`, target text updated, signals emitted, and worker factory NOT invoked.
     - TM miss: verifies matchers called, prompt built with hits, and worker factory invoked with augmented prompt.
     - Unbound controller fallback.
2. **Batch Integration Tests (`tests/batch/test_batch_context_integration.py`):**
   - Batch translation job over items where some match TM and some require LLM.
   - Verifies batch completes correctly, TM items finish instantaneously, and items without TM receive intelligence-enriched prompts.
3. **Full Regression Suite:**
   - P3B.1 Glossary tests (26 tests).
   - P3B.2 Entity Dictionary tests (42 tests).
   - P3B.3 Translation Memory tests (22 tests).
   - Full repository test suite (215+ tests).

## 8. Non-goals and deferred work

- No UI/QML controls for manually toggling intelligence on/off.
- No automatic learning into TM during batch execution (TM remains project-populated).
- No fuzzy matching in TM (locked to 100% exact match).
- No translation model fine-tuning or few-shot exemplars injection.
- No changes to batch checkpoint schema.
- No changes to P3B.1, P3B.2, or P3B.3 domain data models.

## 9. Gate status

This artifact is ready for user review. Implementation planning, feature branch
creation, product code, tests, commit, and push remain blocked until the user
approves this written spec and completes the Design Gate.
