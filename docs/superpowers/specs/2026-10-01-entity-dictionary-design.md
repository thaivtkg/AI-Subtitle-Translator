# P3B.2 Entity Dictionary — Design Spec v1

**Status:** Draft — awaiting user review
**Date:** 2026-10-01
**Scope:** Phase 3B.2 only
**Depends on:** P3B.1 Glossary (CLOSED / LOCKED / MERGED — `9de6cba`)

## 1. Intent and success criteria

Add a project-scoped entity dictionary as the second Translation Intelligence
capability. The entity dictionary tracks named entities (characters, locations,
organizations) with their canonical translations and alternative name forms
(aliases). It must survive `.aisrt` save/load, remain absent from batch
checkpoints, coexist with the glossary under the shared `intelligence`
namespace, and be usable by later Context Integration work without creating a
second translation pipeline.

Success means:

- Valid entity entries preserve their exact user-provided strings for all
  fields: name, entity type, canonical translation, and aliases.
- Each entity has a classified type from a known validated set.
- Aliases provide multiple matchable source-language forms for a single entity,
  with cross-entity uniqueness enforced to prevent ambiguous resolution.
- Matching is deterministic, literal, case-sensitive, and returns only
  non-overlapping hits selected by the same precedence rules as P3B.1 Glossary.
- Alias matches resolve to the canonical entity, reporting both the matched
  form and the canonical entity identity.
- Legacy `.aisrt` files without `intelligence.entities` load as an empty
  entity dictionary and are not rewritten merely because they were loaded.
- Invalid entity data is rejected before project state is committed.
- The accepted translation remains the only authoritative translation state;
  entity matching does not translate, reject, or accept subtitles.
- Glossary data is completely unaffected by entity dictionary operations.

## 2. Verified repository context

- `app/controllers/project_controller.py` owns `.aisrt` JSON save/load. After
  P3B.1 merge, its `intelligence` object contains `glossary`. Entity dictionary
  will add `entities` as a sibling key.
- `app/core/glossary.py` provides the established pattern: frozen dataclass
  entries, copy-on-write atomic mutations, literal substring matching with
  longest-overlap resolution, and `to_payload()`/`from_payload()` persistence.
- `app/core/prompt_builder.py` already instructs "Do NOT translate character
  names or proper nouns" — entity dictionary provides structured data for this
  guidance but does not modify prompt behavior in P3B.2.
- `app/batch/checkpoint.py` stores only batch execution snapshots. Its payload
  has no translation text, no glossary data, and must not gain entity data.
- `app/core` contains Qt-free processing code. The entity dictionary domain
  will remain Qt-free and independently testable.
- No existing entity, character, speaker, or cast data structures exist in the
  codebase. P3B.2 is a fresh domain component.

## 3. Design decisions

### 3.1 Ownership and boundaries

The active project owns one entity dictionary instance. The entity dictionary
domain module owns entry validation, alias uniqueness enforcement, updates, and
matching. The project controller owns only project lifecycle and serialization
wiring.

P3B.2 does not add UI controls, prompt instructions, automatic translation,
automatic acceptance, entity-based text replacement, relationship modeling
between entities, glossary interaction logic, or context injection. Those
belong to later Phase 3B slices (primarily P3B.4).

### 3.2 Entry contract

Each entry has:

| Field | Contract |
| --- | --- |
| `name` | Canonical identity key. Must be a non-empty, non-whitespace-only string. Preserve exactly. This is both the identity and a matchable form. |
| `entity_type` | Must be one of the validated set: `CHARACTER`, `LOCATION`, `ORGANIZATION`, `OTHER`. Case-sensitive, uppercase only. |
| `canonical_translation` | Must be a non-empty, non-whitespace-only string. Preserve exactly. How this entity should be rendered in the target language. |
| `aliases` | Persistence-only sequence of strings. Each value must be non-empty and non-whitespace-only; preserve literal values and deduplicate identical values. An alias must not equal the entry's own `name`. |

No UUID, synthetic ID, trimming, case folding, Unicode normalization,
whitespace collapsing, or other hidden canonicalization is allowed.

Changing `canonical_translation`, `entity_type`, or `aliases` updates the entry
identified by the existing `name`. Changing `name` is remove-then-add
semantics; it is not an in-place identity mutation.

### 3.3 Matchable-form uniqueness contract

Every entity contributes one or more **matchable forms** to the dictionary:
the entity's `name` plus all of its `aliases`. To prevent ambiguous entity
resolution, every matchable form in the dictionary must be unique across the
entire dictionary. No two different entities may own the same matchable form.

Concretely:

1. An alias must not equal the entry's own `name` (redundant — `name` is
   already a matchable form).
2. An alias must not equal the `name` of any other entity in the dictionary.
3. An alias must not equal an alias of any other entity in the dictionary.
4. A new entity's `name` must not equal any existing alias of another entity
   in the dictionary.

Rules 2 and 4 together enforce symmetry: if entity A owns matchable form `X`
(as name or alias), then entity B cannot own `X` in any capacity.

Uniqueness is checked against the full candidate state (existing entries plus
all entries being added in the current operation). A violation rejects the
entire operation; the dictionary is not partially updated.

### 3.4 Duplicate and conflict rules

**Effective aliases** is the canonical identity form of an entry's alias list,
used for deduplication and conflict comparison:

- Remove exact duplicate values from the input sequence.
- Preserve each alias string exactly (no trimming, case folding, or
  normalization).
- Alias ordering is **not semantic** for identity/conflict comparison:
  `["Iron Man", "Stark"]` and `["Stark", "Iron Man"]` are identical effective
  alias sets.
- For canonical persistence, the stored order is **first-occurrence order after
  deduplication**: `["B", "A", "B"]` → `["B", "A"]`.

Therefore:

```text
["Iron Man", "Stark"]  ==  ["Stark", "Iron Man"]   (same effective aliases)
["Stark", "Stark"]     ==  ["Stark"]                (deduplicated)
[" Stark "]            !=  ["Stark"]                (literal preservation)
```

When an ordered input contains the same `name` more than once:

- Identical `canonical_translation`, identical `entity_type`, and identical
  effective aliases are deduplicated.
- Any field difference (`canonical_translation`, `entity_type`, or effective
  aliases) is rejected as a conflict.
- The dictionary is not partially updated by a rejected operation.

### 3.5 Canonical `.aisrt` representation

The project stores the entity dictionary at `intelligence.entities`, keyed by
the exact `name`, as a sibling of `intelligence.glossary`:

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
        "aliases": ["Iron Man", "Stark"]
      },
      "Wakanda": {
        "entity_type": "LOCATION",
        "canonical_translation": "Wakanda",
        "aliases": []
      }
    }
  }
}
```

An empty entity dictionary is serialized canonically as:

```json
{"intelligence": {"glossary": {}, "entities": {}}}
```

The canonical writer emits `entity_type`, `canonical_translation`, and
`aliases` for every stored entry. It does not create a sidecar file or
duplicate entity data inside a checkpoint.

For loading, a missing `intelligence` object or missing `entities` member is
treated as an empty entity dictionary for legacy compatibility. If the
`entities` member exists but is malformed, loading fails; it is not silently
replaced with an empty dictionary.

Glossary loading and entity loading are independent: a valid glossary with an
invalid entity payload fails the entire load (and vice versa). Neither is
partially committed.

### 3.6 Matcher contract

The matcher accepts source text and the project entity dictionary and returns
immutable hits with at least:

```text
entity_name, matched_form, canonical_translation, entity_type, start, end
```

- `entity_name`: the canonical `name` of the matched entity.
- `matched_form`: the actual text that matched (may be `name` or one of
  `aliases`).
- `canonical_translation`: the entity's canonical translation.
- `entity_type`: the entity's type.
- Spans use half-open indexing `[start, end)`.

Matching searches for every entity's `name` and all of its `aliases` as
literal substrings in the source text. Matching is literal, case-sensitive,
and includes multiple occurrences, including occurrences that would overlap
before conflict resolution. The matcher does not use token boundaries, regular
expressions, fuzzy matching, stemming, normalization, or translation-model
calls.

Overlap resolution is deterministic (identical to P3B.1 Glossary):

1. Generate all literal occurrence candidates across all entities' names and
   aliases.
2. Consider candidates by descending `matched_form` length, then ascending
   `start` position.
3. Keep a candidate only when its span does not overlap a previously kept
   candidate; discard overlapping candidates.
4. Return kept hits sorted by ascending `start` position.

Thus the longest matched form wins; equal-length ties prefer the earlier
start; non-overlapping occurrences remain. Matching never mutates the source
text, entity dictionary, subtitle model, or translation status.

## 4. Persistence and atomicity

### Save

Project save includes the canonical `intelligence.entities` object every time,
alongside `intelligence.glossary`, including when either or both are empty.
Existing metadata, story summary, subtitle data, file extension handling, and
user-visible save behavior remain unchanged.

### Load

Project load stages and validates all intelligence payloads (glossary and
entities) before committing either the active glossary, the active entity
dictionary, or loading new subtitle data. If any intelligence entry is
invalid, conflicting, has an invalid alias, or violates alias uniqueness,
the operation fails with no partial project-model commit.

Missing legacy entity data commits an empty entity dictionary without
rewriting the source file. A successful later save writes the canonical
entity namespace alongside the glossary namespace.

The batch checkpoint contract is unchanged. `CheckpointStore.save()` and
`CheckpointStore.load()` continue to serialize only batch execution state;
entity data must not appear there.

### Atomicity ordering

During `loadProject`, the staging sequence is:

1. Parse and validate glossary payload → `loaded_glossary`
2. Parse and validate entity payload → `loaded_entities`
3. If both succeed, load subtitle data
4. Commit `self.glossary = loaded_glossary`
5. Commit `self.entity_dictionary = loaded_entities`

If step 1 or step 2 fails, no model or intelligence state changes. This
preserves the atomic load guarantee established by P3B.1.

## 5. Impact and failure preview

| Failure | Cause | Impact | Detection/recovery |
| --- | --- | --- | --- |
| Invalid entry accepted | Incomplete boundary validation | Bad project state or ambiguous matching | Domain/persistence tests; reject before commit |
| Alias collision undetected | Missing cross-entity matchable-form uniqueness check (including name→alias direction) | Ambiguous entity resolution; multiple entities claim the same matched form | Matchable-form uniqueness tests; validate full candidate state symmetrically |
| Alias equals own name accepted | Missing self-reference check | Redundant alias stored; potential confusion | Domain test; reject before commit |
| Wrong overlap winner | Incorrect candidate ordering or span test | Inconsistent downstream entity identification | Dedicated overlap/tie tests; fix matcher ordering |
| Legacy file rewritten on load | Load path saves implicitly | Unrequested file mutation | Round-trip/load test; load must be read-only |
| Partial project load | Entity validation occurs after model mutation | Mixed old/new project state | Stage all intelligence validation before model commit |
| Entity leaks into checkpoint | Shared serialization code reused incorrectly | Batch resume identity/schema regression | Assert checkpoint payload contains no entity fields |
| Glossary corrupted by entity ops | Shared `intelligence` namespace mishandled | Cross-feature regression | Coexistence test; independent persistence assertion |
| Invalid entity_type accepted | Missing type validation | Untyped or mis-typed entities in project state | Type validation test; reject unknown types |

## 6. Acceptance contract

The following 23 groups are the reviewable P3B.2 contract. They are behavior
requirements, not an instruction to add a second pipeline or UI surface.

| ID | Acceptance group | Required behavior |
| --- | --- | --- |
| TC-P3B2-01 | Valid entry | Accept valid `name`, `entity_type`, `canonical_translation`, and `aliases`; preserve all exactly. |
| TC-P3B2-02 | Entry validity | Reject empty or whitespace-only `name` and `canonical_translation`; do not mutate existing state. |
| TC-P3B2-03 | Entity type validation | Reject `entity_type` not in `{CHARACTER, LOCATION, ORGANIZATION, OTHER}`; accept all valid types. |
| TC-P3B2-04 | Alias validity | Reject empty or whitespace-only alias values; preserve valid literal values and deduplicate identical values. |
| TC-P3B2-05 | Alias self-reference | Reject alias that equals the entity's own `name`. |
| TC-P3B2-06 | Matchable-form cross-entity uniqueness | Reject any operation where a matchable form (name or alias) of one entity collides with a matchable form of another entity — including a new entity's `name` colliding with an existing entity's alias; leave prior dictionary state unchanged. |
| TC-P3B2-07 | Duplicate deduplication | Deduplicate repeated identical entity definitions (same `name`, `entity_type`, `canonical_translation`, and effective aliases) without changing the effective dictionary. |
| TC-P3B2-08 | Duplicate conflict | Reject the same `name` with a different `canonical_translation`, `entity_type`, or effective aliases; leave the prior dictionary unchanged. |
| TC-P3B2-09 | Case-sensitive matching | Match `name` and aliases with exact case only; differently cased text does not match. |
| TC-P3B2-10 | Literal substring matching | Match inside larger words and punctuation without token-boundary rules. |
| TC-P3B2-11 | Alias resolution | Alias occurrence in source text resolves to the canonical entity, returning both `matched_form` (the alias) and `entity_name` (the canonical name). |
| TC-P3B2-12 | Multiple occurrences | Return every non-discarded literal occurrence with correct half-open spans. |
| TC-P3B2-13 | Longest overlap | For overlapping candidates, keep the longest matched form and discard the shorter overlap. |
| TC-P3B2-14 | Equal-length tie | For equal-length overlapping candidates, keep the candidate with the smaller start position. |
| TC-P3B2-15 | Non-overlap retention | Keep all candidates whose spans do not overlap a selected candidate. |
| TC-P3B2-16 | Result order | Return final hits sorted by ascending start position. |
| TC-P3B2-17 | Matcher immutability | Matching does not mutate source text, entity entries, subtitle data, or statuses; it does not call a model or accept anything. |
| TC-P3B2-18 | `.aisrt` round-trip | Save and load preserves entity names, types, canonical translations, and aliases. |
| TC-P3B2-19 | Canonical empty save | Saving an empty entity dictionary writes `intelligence.entities` as `{}`. |
| TC-P3B2-20 | Legacy load | Missing `intelligence` or `entities` loads as empty and does not rewrite the file during load. |
| TC-P3B2-21 | Atomic invalid load | Any invalid entity payload is rejected before project/dictionary state changes; no partial load is visible. |
| TC-P3B2-22 | Checkpoint isolation | Batch checkpoint save/load remains unchanged and contains no entity data. |
| TC-P3B2-23 | Glossary coexistence | Entity dictionary and glossary persist independently under `intelligence`; adding/removing entities does not affect glossary data, and vice versa. |

## 7. Verification strategy for implementation

Implementation must add focused Qt-free domain tests for entry validation,
entity type validation, alias validity, alias uniqueness (self-reference and
cross-entity), duplicates, literal matching with alias resolution, spans,
overlap ordering, and immutability; project persistence tests for
canonical/legacy/atomic behavior and glossary coexistence; and a checkpoint
regression assertion for isolation.

The existing canonical test command and software Qt backend policy remain the
verification baseline for the repository. All existing P3B.1 glossary tests
must continue to pass without modification.

No UI test or real-model test is required for P3B.2 because no UI or model
behavior changes in this slice. P3B.4 will own tests for entity context
injection and prompt integration.

## 8. Non-goals and deferred work

- No entity import/export file format.
- No UI editor or QML properties.
- No automatic replacement of source or translation text based on entities.
- No automatic acceptance or rejection of a translation.
- No relationship modeling between entities (e.g., "X is father of Y").
- No entity notes/description field (may be added in a future slice).
- No interaction logic between entity dictionary and glossary matchers.
- No prompt modification or context injection using entity data.
- No entity-aware translation guidance or forbidden-term enforcement.
- No rewrite/migration of a legacy `.aisrt` on load.
- No changes to batch checkpoint schema or resume behavior.
- No changes to P3B.1 Glossary semantic or implementation.

## 9. Gate status

This artifact is ready for user review. Implementation planning, feature
branch creation, product code, tests, commit, and push remain blocked until
the user approves this written spec and the next implementation-plan gate is
completed.
