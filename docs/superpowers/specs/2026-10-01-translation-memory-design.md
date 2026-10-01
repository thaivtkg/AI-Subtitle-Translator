# P3B.3 Translation Memory — Design Spec v1

**Status:** Draft — awaiting user review
**Date:** 2026-10-01
**Scope:** Phase 3B.3 only
**Depends on:**
- P3B.1 Glossary (CLOSED / LOCKED / MERGED — `9de6cba`)
- P3B.2 Entity Dictionary (CLOSED / LOCKED / MERGED — `bf52573`)

## 1. Intent and success criteria

Add a project-scoped translation memory (TM) as the third Translation
Intelligence capability. The translation memory stores previously verified,
segment-level translations (pairs of source text and target text) to enable
instant reuse when identical subtitle lines appear. It must survive `.aisrt`
save/load, remain absent from batch checkpoints, coexist with glossary and
entities under the shared `intelligence` namespace, and be usable by later
Context Integration work without creating a second translation pipeline.

Success means:

- Valid TM entries preserve their exact user-provided strings for both
  `source_text` and `target_text`.
- Lookup operates on whole-segment exact string equality (100% literal match);
  it does not perform substring search, tokenization, or fuzzy matching.
- Adding an entry with an existing `source_text` follows last-write-wins
  semantics, updating the `target_text` without raising a conflict error.
- Legacy `.aisrt` files without `intelligence.translation_memory` load as an
  empty translation memory and are not rewritten merely because they were
  loaded.
- Invalid TM data is rejected before project state is committed (atomic load).
- The accepted translation remains the only authoritative translation state;
  TM lookup does not translate, reject, or accept subtitles automatically.
- Glossary and entity dictionary data are completely unaffected by TM
  operations.

## 2. Verified repository context

- `app/controllers/project_controller.py` owns `.aisrt` JSON save/load. Its
  `intelligence` object currently serializes `glossary` and `entities`.
  Translation memory will add `translation_memory` as a sibling key.
- `app/core/glossary.py` and `app/core/entity_dictionary.py` provide the
  established pattern: frozen dataclass entries, copy-on-write atomic
  mutations, and `to_payload()`/`from_payload()` persistence.
- `app/batch/checkpoint.py` stores only batch execution snapshots. Its
  payload has no translation text, no glossary, no entity data, and must not
  gain TM data.
- `app/core` contains Qt-free processing code. The translation memory domain
  module will remain Qt-free and independently testable.
- Subtitle segments in `SubtitleModel` contain `original` and `translation`
  strings, with `ACCEPTED` being the authoritative user-verified status. TM
  will store segment-level pairs.

## 3. Design decisions

### 3.1 Ownership and boundaries

The active project owns one translation memory instance. The translation
memory domain module (`app/core/translation_memory.py`) owns entry
validation, storage, mutation, and exact lookup. The project controller owns
project lifecycle and serialization wiring.

P3B.3 does not add UI controls, automatic subtitle acceptance, automatic text
replacement, background listeners on `SubtitleModel`, fuzzy matching,
Levenshtein distance calculation, external similarity libraries, or prompt/LLM
integration. Those belong to later slices (P3B.4 Context Integration or later
phases).

### 3.2 Entry contract

Each entry has:

| Field | Contract |
| --- | --- |
| `source_text` | Canonical identity key. Must be a non-empty, non-whitespace-only string. Preserve exactly. Represents the complete source subtitle segment. |
| `target_text` | Verified translation. Must be a non-empty, non-whitespace-only string. Preserve exactly. Represents the target translation. |

No UUID, synthetic ID, trimming, case folding, Unicode normalization,
whitespace collapsing, or other hidden canonicalization is allowed.

### 3.3 Mutation and conflict resolution (Last-Write-Wins)

Unlike Glossary (which treats different translations for the same source term
as a conflict), Translation Memory follows **last-write-wins (overwrite)**
semantics for duplicate source segments:

- When an entry with an existing `source_text` is added, its `target_text`
  replaces the prior translation.
- This directly models the natural translation workflow: when a user re-translates
  or refines a previously accepted sentence, the latest accepted version becomes
  the active memory.
- All mutations (add, update, remove) are atomic and copy-on-write, ensuring
  thread-safety and consistency.

### 3.4 Matcher / Lookup contract

TM lookup is whole-string exact matching:

```text
lookup(source_text: str) -> Optional[TMEntry]
```

- **Exact equality:** The query string must match `entry.source_text` exactly
  (`query == entry.source_text`).
- **Case-sensitive:** `"Hello"` does not match `"hello"`.
- **Whitespace-sensitive:** `"Hello world"` does not match `"Hello  world"`.
- **Not a substring search:** Querying `"apple"` will **not** match an entry
  with `source_text = "I like apples"`. (Segment-level memory, not term
  glossary).
- **Immutability:** Lookup does not mutate TM internal state, subtitle models,
  or translation status.

### 3.5 Canonical `.aisrt` representation

The project stores translation memory at `intelligence.translation_memory`,
keyed by the exact `source_text`, as a sibling of `glossary` and `entities`:

```json
{
  "intelligence": {
    "glossary": {
      "Captain": {
        "preferred_translation": "Đại úy",
        "forbidden_alternatives": ["Thuyền trưởng"]
      }
    },
    "entities": {
      "Tony Stark": {
        "entity_type": "CHARACTER",
        "canonical_translation": "Tony Stark",
        "aliases": ["Iron Man"]
      }
    },
    "translation_memory": {
      "Good morning, Captain.": {
        "target_text": "Chào buổi sáng, Đại úy."
      },
      "All systems are operational.": {
        "target_text": "Tất cả các hệ thống đã sẵn sàng hoạt động."
      }
    }
  }
}
```

An empty translation memory is serialized canonically as:

```json
{
  "intelligence": {
    "glossary": {},
    "entities": {},
    "translation_memory": {}
  }
}
```

The canonical writer emits `target_text` for every stored entry. It does not
create a sidecar file or duplicate TM data inside a checkpoint.

For loading, a missing `intelligence` object or missing `translation_memory`
member is treated as an empty translation memory for legacy compatibility. If
the `translation_memory` member exists but is malformed, loading fails; it is
not silently replaced with an empty dictionary.

## 4. Persistence and atomicity

### Save

Project save includes the canonical `intelligence.translation_memory` object
every time, alongside `glossary` and `entities`, including when any or all are
empty. Existing metadata, story summary, subtitle data, file extension
handling, and user-visible save behavior remain unchanged.

### Load

Project load stages and validates all intelligence payloads before committing
any of them or mutating the subtitle model:

1. Parse and validate glossary payload → `loaded_glossary`
2. Parse and validate entities payload → `loaded_entities`
3. Parse and validate TM payload → `loaded_tm`
4. Load subtitle model data
5. Commit `self.glossary = loaded_glossary`
6. Commit `self.entity_dictionary = loaded_entities`
7. Commit `self.translation_memory = loaded_tm`

If any staging step fails (malformed JSON, invalid types, empty strings), the
entire load operation aborts with an error notification. The existing
project state, subtitle model, glossary, entity dictionary, and translation
memory remain completely untouched.

### Checkpoint isolation

Batch checkpoints (`app/batch/checkpoint.py`) serialize only batch execution
state. Translation memory data must never appear in `checkpoint.json`.

## 5. Impact and failure preview

| Failure | Cause | Impact | Detection/recovery |
| --- | --- | --- | --- |
| Invalid entry accepted | Incomplete boundary validation | Bad project state or corrupt `.aisrt` | Domain/persistence tests; reject before commit |
| Substring match attempted | Incorrect search algorithm (using `find` instead of `==`) | False positive TM hits on partial sentences | Exact lookup tests; assert whole-string match |
| Case/whitespace normalized | Premature `.strip()` or `.lower()` | Loss of original formatting; unexpected lookups | Domain tests preserving raw whitespace/case |
| Partial load commit | TM validated after subtitle model mutation | Inconsistent project state on error | Staging order in `loadProject`; test atomic failure |
| Legacy file rewritten on load | Load path writes back immediately | Unrequested file modification | Round-trip/load test; load must be read-only |
| TM leaks into checkpoint | Shared serialization code reused | Checkpoint schema pollution | Assert checkpoint payload contains no TM data |
| Cross-feature collision | Sibling keys overwritten under `intelligence` | Glossary or entities wiped out on save | Coexistence tests verifying all 3 namespaces |

## 6. Acceptance contract

The following 16 test groups define the reviewable P3B.3 contract.

| ID | Acceptance group | Required behavior |
| --- | --- | --- |
| TC-P3B3-01 | Valid entry | Accept valid `source_text` and `target_text`; preserve both exactly as literal strings. |
| TC-P3B3-02 | Entry validity | Reject empty or whitespace-only `source_text` and `target_text`; do not mutate existing state. |
| TC-P3B3-03 | Last-write-wins | Adding an entry with an existing `source_text` replaces the `target_text` cleanly without raising an error. |
| TC-P3B3-04 | Update and remove | `update()` modifies existing entry (or raises `KeyError` if absent); `remove()` deletes entry cleanly. |
| TC-P3B3-05 | Exact match 100% | Exact match query returns the corresponding `TMEntry` / target translation. |
| TC-P3B3-06 | Case-sensitive lookup | Differently cased query does not match (`"Hello"` != `"hello"`). |
| TC-P3B3-07 | Whole-string boundary | Substring query does not match (`"world"` does not match `"Hello world"`). |
| TC-P3B3-08 | Whitespace sensitivity | Queries with different whitespace do not match (`"A B"` != `"A  B"`). |
| TC-P3B3-09 | Miss lookup | Lookup on non-existent `source_text` returns `None`. |
| TC-P3B3-10 | Lookup immutability | Lookup does not mutate TM internal state, subtitle model, or translation status. |
| TC-P3B3-11 | `.aisrt` round-trip | Save and load preserves all TM entries under `intelligence.translation_memory`. |
| TC-P3B3-12 | Canonical empty save | Saving an empty TM writes `intelligence.translation_memory` as `{}`. |
| TC-P3B3-13 | Legacy load | Missing `intelligence` or `translation_memory` loads as empty and does not rewrite the file during load. |
| TC-P3B3-14 | Atomic invalid load | Any invalid TM payload is rejected before project/model state changes; no partial load is visible. |
| TC-P3B3-15 | Checkpoint isolation | Batch checkpoint save/load remains unchanged and contains no TM data. |
| TC-P3B3-16 | Intelligence coexistence | Glossary, Entity Dictionary, and Translation Memory persist independently under `intelligence`; changes to one do not affect the others. |

## 7. Verification strategy for implementation

Implementation will add:

1. **Qt-free domain tests** (`tests/test_translation_memory.py`):
   - Entry validation (non-empty, non-whitespace, exact preservation).
   - Last-write-wins overwrite semantics.
   - Exact whole-segment matching (case sensitivity, whitespace sensitivity, whole-string boundary, miss handling).
   - Immutability of lookup.
2. **Project persistence tests** (`tests/test_project_translation_memory.py`):
   - `.aisrt` round-trip serialization.
   - Canonical empty save namespace.
   - Legacy compatibility (missing TM key loads empty without modifying file).
   - Atomic load failure on corrupted TM payload.
   - Checkpoint isolation assertion.
   - Three-way coexistence assertion (Glossary + Entities + TM).
3. **Regression suite**:
   - P3B.1 Glossary tests (26 tests).
   - P3B.2 Entity Dictionary tests (42 tests).
   - Full test suite execution.

## 8. Non-goals and deferred work

- No fuzzy matching (Levenshtein, token similarity, threshold matching).
- No external similarity dependencies (e.g. RapidFuzz).
- No background auto-sync from `SubtitleModel` in `app/core/`.
- No automatic subtitle text replacement based on TM matches.
- No automatic status change to `ACCEPTED`.
- No UI components or QML views for TM editing.
- No metadata fields (`created_at`, `score`, `user`).
- No prompt injection or LLM context modification (deferred to P3B.4).
- No changes to batch checkpoint schema or resume logic.
- No changes to P3B.1 Glossary or P3B.2 Entity Dictionary semantics.

## 9. Gate status

This artifact is ready for user review. Implementation planning, feature branch
creation, product code, tests, commit, and push remain blocked until the user
approves this written spec and completes the Design Gate.
