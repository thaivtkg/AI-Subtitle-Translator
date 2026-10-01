# P3B.1 Glossary — Design Spec v1

**Status:** Draft — awaiting user review
**Date:** 2026-10-01
**Scope:** Phase 3B.1 only

## 1. Intent and success criteria

Add project-scoped glossary data and a deterministic literal matcher as the
first Translation Intelligence capability. The glossary must survive `.aisrt`
save/load, remain absent from batch checkpoints, and be usable by later
Context Integration work without creating a second translation pipeline.

Success means:

- Valid glossary entries preserve their exact user-provided strings.
- Matching is deterministic, literal, case-sensitive, and returns only
  non-overlapping hits selected by the locked precedence rules.
- Legacy `.aisrt` files without `intelligence.glossary` load as an empty
  glossary and are not rewritten merely because they were loaded.
- Invalid glossary data is rejected before project state is committed.
- The accepted translation remains the only authoritative translation state;
  glossary matching does not translate, reject, or accept subtitles.

## 2. Verified repository context

- `app/controllers/project_controller.py` currently owns `.aisrt` JSON
  save/load. Its root contains `metadata`, `story_summary`, and `subtitles`.
- `app/models/subtitle.py` owns subtitle translation/status data. `ACCEPTED`
  is an existing terminal user-approved status.
- `app/core/context_engine.py` already uses prior translations only when their
  status is `ACCEPTED`; other context remains source text.
- `app/batch/checkpoint.py` stores only the batch execution snapshot under a
  separate checkpoint schema. Its current payload has no translation text.
- `app/core` contains Qt-free processing code, so the glossary domain and
  matcher will remain Qt-free and independently testable.

## 3. Design decisions

### 3.1 Ownership and boundaries

The active project owns one glossary instance. The glossary domain module owns
entry validation, duplicate handling, updates, and matching. The project
controller owns only project lifecycle and serialization wiring.

P3B.1 does not add UI controls, prompt instructions, automatic translation,
automatic acceptance, forbidden-alternative enforcement, entity dictionary
behavior, translation memory, or context injection. Those belong to later
Phase 3B slices.

### 3.2 Entry contract

Each entry has:

| Field | Contract |
| --- | --- |
| `source_term` | Canonical identity/key. Must be a non-empty, non-whitespace-only string. Preserve exactly. |
| `preferred_translation` | Must be a non-empty, non-whitespace-only string. Preserve exactly. |
| `forbidden_alternatives` | Persistence-only sequence of strings. Each value must be non-empty and non-whitespace-only; preserve literal values and deduplicate identical values. |

No UUID, synthetic ID, composite ID, trimming, case folding, Unicode
normalization, whitespace collapsing, or other hidden canonicalization is
allowed.

Changing only `preferred_translation` updates the entry identified by the
existing `source_term`. Changing `source_term` is remove-then-add semantics;
it is not an in-place identity mutation.

When an ordered input contains the same `source_term` more than once:

- identical `preferred_translation` and identical effective forbidden values
  are deduplicated;
- a different `preferred_translation` is rejected as a conflict;
- the glossary is not partially updated by a rejected operation.

### 3.3 Canonical `.aisrt` representation

The project stores the glossary only at `intelligence.glossary`, keyed by the
exact `source_term`:

```json
{
  "intelligence": {
    "glossary": {
      "Captain": {
        "preferred_translation": "Đại úy",
        "forbidden_alternatives": ["Thuyền trưởng"]
      }
    }
  }
}
```

An empty glossary is serialized canonically as:

```json
{"intelligence": {"glossary": {}}}
```

The canonical writer emits `preferred_translation` and
`forbidden_alternatives` for every stored entry. It does not create a sidecar
file or duplicate glossary data inside a checkpoint.

For loading, a missing `intelligence` object or missing `glossary` member is
treated as an empty glossary for legacy compatibility. If the glossary member
exists but is malformed, loading fails; it is not silently replaced with an
empty glossary.

### 3.4 Matcher contract

The matcher accepts source text and the project glossary and returns immutable
hits with at least:

```text
source_term, preferred_translation, start, end
```

Spans use half-open indexing `[start, end)`. Matching is literal substring
search, case-sensitive, and includes multiple occurrences, including
occurrences that would overlap before conflict resolution. The matcher does
not use token boundaries, regular expressions, fuzzy matching, stemming,
normalization, or translation-model calls.

Overlap resolution is deterministic:

1. Generate all literal occurrence candidates.
2. Consider candidates by descending `source_term` length, then ascending
   `start` position.
3. Keep a candidate only when its span does not overlap a previously kept
   candidate; discard overlapping candidates.
4. Return kept hits sorted by ascending `start` position.

Thus the longest overlapping term wins; equal-length ties prefer the earlier
start; non-overlapping occurrences remain. Matching never mutates the source
text, glossary, subtitle model, or translation status.

`forbidden_alternatives` is deliberately absent from matcher hits and has no
effect on matching in P3B.1. Enforcement is deferred to P3B.4.

## 4. Persistence and atomicity

### Save

Project save includes the canonical `intelligence.glossary` object every time,
including when it is empty. Existing metadata, story summary, subtitle data,
file extension handling, and user-visible save behavior remain unchanged.

### Load

Project load stages and validates the complete glossary payload before
committing the active glossary or loading new subtitle data. If any glossary
entry is invalid, conflicting, or has an invalid forbidden alternative, the
operation fails with no partial glossary/project-model commit.

Missing legacy glossary data commits an empty glossary without rewriting the
source file. A successful later save writes the canonical glossary location.

The batch checkpoint contract is unchanged. `CheckpointStore.save()` and
`CheckpointStore.load()` continue to serialize only batch execution state;
glossary data must not appear there.

## 5. Impact and failure preview

| Failure | Cause | Impact | Detection/recovery |
| --- | --- | --- | --- |
| Invalid entry accepted | Incomplete boundary validation | Bad project state or ambiguous matching | Domain/persistence tests; reject before commit |
| Conflicting duplicate | Same source key with different preferred translation | Nondeterministic translation guidance | Validate the full input; keep prior state unchanged |
| Wrong overlap winner | Incorrect candidate ordering or span test | Inconsistent downstream guidance | Dedicated overlap/tie tests; fix matcher ordering |
| Legacy file rewritten on load | Load path saves implicitly | Unrequested file mutation | Round-trip/load test; load must be read-only |
| Partial project load | Glossary validation occurs after model mutation | Mixed old/new project state | Stage all glossary validation before model commit |
| Glossary leaks into checkpoint | Shared serialization code is reused incorrectly | Batch resume identity/schema regression | Assert checkpoint payload contains no glossary/translation fields |

## 6. Acceptance contract

The following 18 groups are the reviewable P3B.1 contract. They are behavior
requirements, not an instruction to add a second pipeline or UI surface.

| ID | Acceptance group | Required behavior |
| --- | --- | --- |
| TC-P3B1-01 | Valid entry | Accept valid `source_term` and `preferred_translation`; preserve both exactly. |
| TC-P3B1-02 | Entry validity | Reject empty or whitespace-only `source_term` and `preferred_translation`; do not mutate existing state. |
| TC-P3B1-03 | Forbidden validity | Reject empty or whitespace-only forbidden values; preserve valid literal values and deduplicate identical values. |
| TC-P3B1-04 | Duplicate deduplication | Deduplicate repeated identical source mappings without changing the effective glossary. |
| TC-P3B1-05 | Duplicate conflict | Reject the same `source_term` with a different `preferred_translation`; leave the prior glossary unchanged. |
| TC-P3B1-06 | Case sensitivity | Match `source_term` with exact case only; differently cased text does not match. |
| TC-P3B1-07 | Literal substring | Match inside larger words and punctuation without token-boundary rules. |
| TC-P3B1-08 | Multiple occurrences | Return every non-discarded literal occurrence with correct half-open spans. |
| TC-P3B1-09 | Longest overlap | For overlapping candidates, keep the longest source term and discard the shorter overlap. |
| TC-P3B1-10 | Equal-length tie | For equal-length overlapping candidates, keep the candidate with the smaller start position. |
| TC-P3B1-11 | Non-overlap retention | Keep all candidates whose spans do not overlap a selected candidate. |
| TC-P3B1-12 | Result order | Return final hits sorted by ascending start position. |
| TC-P3B1-13 | Matcher immutability | Matching does not mutate source text, glossary entries, subtitle data, or statuses; it does not call a model or accept anything. |
| TC-P3B1-14 | `.aisrt` round-trip | Save and load preserves entry keys, literal preferred translations, and forbidden alternatives. |
| TC-P3B1-15 | Canonical empty save | Saving an empty glossary writes `intelligence.glossary` as `{}`. |
| TC-P3B1-16 | Legacy load | Missing `intelligence` or `glossary` loads as empty and does not rewrite the file during load. |
| TC-P3B1-17 | Atomic invalid load | Any invalid glossary payload is rejected before project/glossary state changes; no partial load is visible. |
| TC-P3B1-18 | Checkpoint isolation | Batch checkpoint save/load remains unchanged and contains no glossary data. |

## 7. Verification strategy for implementation

Implementation must add focused Qt-free domain tests for entry validation,
duplicates, literal matching, spans, overlap ordering, and immutability; project
persistence tests for canonical/legacy/atomic behavior; and a checkpoint
regression assertion for isolation. The existing canonical test command and
software Qt backend policy remain the verification baseline for the repository.

No UI test or real-model test is required for P3B.1 because no UI or model
behavior changes in this slice. P3B.4 will own tests for forbidden-alternative
enforcement and context/prompt integration.

## 8. Non-goals and deferred work

- No glossary import/export file format.
- No UI editor or QML properties.
- No automatic replacement of source or translation text.
- No automatic acceptance or rejection of a translation.
- No forbidden-alternative enforcement in the matcher.
- No entity dictionary, translation memory, or context prompt integration.
- No rewrite/migration of a legacy `.aisrt` on load.
- No changes to batch checkpoint schema or resume behavior.

## 9. Gate status

This artifact is ready for user review. Implementation planning, feature
branch creation, product code, tests, commit, and push remain blocked until
the user approves this written spec and the next implementation-plan gate is
completed.
