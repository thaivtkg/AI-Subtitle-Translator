# Auto-Glossary & Pronoun Biasing Offline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 100% offline automatic entity extraction and pronoun biasing from story summaries with 2s debounce, visual Liquid Glass controls, dialogue continuity, and mandatory A/B comparative tests.

**Architecture:** A lightweight rule-based `ContextAnalyzer` extracts entities and character archetypes offline using Regex without heavy NLP dependencies. `ProjectController` orchestrates state, persistence into `.aisrt`, and anti-resurrection sets. `ContextEngine` and `PromptBuilder` maintain dialogue continuity across subtitles by passing translated preceding lines. QML UI adds a 2000ms debounce timer in `ContextInspector.qml` and an archetype dropdown capsule in `TranslationWorkspace.qml` header.

**Tech Stack:** Python 3.10+, PySide6 (Qt Quick / QML), MultiEffect, pytest.

**Spec:** `docs/superpowers/specs/2026-10-19-auto-glossary-pronoun-biasing-design.md`

## Global Constraints

- 100% Offline: No external HTTP calls, no heavy deep-learning dependencies (no spaCy, no huggingface).
- Debounce: Exactly 2000ms after user stops typing in Summary input.
- Data Preservation: Auto-generated glossary terms (`is_auto: True`) must never overwrite or delete manual terms (`is_auto: False`).
- Anti-Resurrection: User-dismissed (`✕`) auto terms must never be resurrected by subsequent debounce cycles.
- Token Limit: Maximum 30 terms and 1 active pronoun pair injected into LLM prompt.
- Target Scope: Pronoun biasing rules are active only when `target_lang.lower() == "vietnamese"`.
- Strict A/B Test Rule: If enriched prompt matches baseline prompt (no difference in pronoun/rules), test MUST fail.

## Review Focus

- Empty or whitespace summary input does not crash and defaults to `ARCHETYPE_CUSTOM` with clean empty glossary.
- Tech keywords in summary (e.g. "code", "bug", "lập trình") prevent false positive ancient/martial arts genre matching.
- Preceding subtitle formatting does not cause Qwen 3B to echo line numbering prefixes in output text.
- Manual archetype selection on Header Capsule remains locked (`is_archetype_locked = True`) despite subsequent summary edits.
- Dismissing an auto term adds it to `dismissed_auto_terms` so the next 2-second debounce ignores it.

---

### Task 1: Core Domain Engine (`app/core/context_analyzer.py`)

**Files:**
- Create: `app/core/context_analyzer.py`
- Test: `tests/test_context_analyzer.py`

**Interfaces:**
- Produces:
  - `ContextAnalyzer.extract_entities(text: str, source_lang: str) -> list[dict]`
  - `ContextAnalyzer.classify_archetype(text: str) -> tuple[str, str]` (archetype_id, pronoun_pair)
  - Archetype constants: `ARCHETYPE_ANCIENT_FANTASY`, `ARCHETYPE_ANIME_SCHOOL`, `ARCHETYPE_MODERN_ACTION`, `ARCHETYPE_ROMANCE_FAMILY`, `ARCHETYPE_CUSTOM`

- [ ] **Step 1: Write failing test in `tests/test_context_analyzer.py`**

```python
import pytest
from app.core.context_analyzer import (
    ContextAnalyzer,
    ARCHETYPE_ANCIENT_FANTASY,
    ARCHETYPE_ANIME_SCHOOL,
    ARCHETYPE_MODERN_ACTION,
    ARCHETYPE_CUSTOM,
)

def test_extract_pair_definitions():
    text = 'Phim về "Xiao Yan": Tiêu Viêm và "Master Yao" -> Dược Lão.'
    entities = ContextAnalyzer.extract_entities(text)
    source_terms = [e["source_term"] for e in entities]
    translations = [e["preferred_translation"] for e in entities]
    assert "Xiao Yan" in source_terms
    assert "Tiêu Viêm" in translations
    assert "Master Yao" in source_terms
    assert "Dược Lão" in translations

def test_extract_quotes_and_katakana():
    text = 'Nhân vật 「ナルト」 và "Cyberpunk" sống tại Tokyo.'
    entities = ContextAnalyzer.extract_entities(text)
    sources = [e["source_term"] for e in entities]
    assert "ナルト" in sources
    assert "Cyberpunk" in sources

def test_classify_archetype_ancient():
    text = "Phim cổ trang tu tiên, hai kiếm hiệp đối đầu sinh tử"
    archetype, pronouns = ContextAnalyzer.classify_archetype(text)
    assert archetype == ARCHETYPE_ANCIENT_FANTASY
    assert pronouns == "Ta - Ngươi"

def test_classify_archetype_school():
    text = "Câu chuyện về các bạn nữ sinh trung học và ma thuật học đường"
    archetype, pronouns = ContextAnalyzer.classify_archetype(text)
    assert archetype == ARCHETYPE_ANIME_SCHOOL
    assert pronouns == "Tớ - Cậu"

def test_anti_collision_tech_keywords():
    text = "Lập trình viên chiến đấu với bug và hệ thống máy tính như dũng giả"
    archetype, pronouns = ContextAnalyzer.classify_archetype(text)
    assert archetype == ARCHETYPE_MODERN_ACTION
    assert pronouns == "Tôi - Bạn"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_context_analyzer.py -v`  
Expected: FAIL (ModuleNotFoundError: No module named 'app.core.context_analyzer')

- [ ] **Step 3: Implement `ContextAnalyzer` in `app/core/context_analyzer.py`**

Implement regex-based entity extraction (`"..."`, `「...」`, `『...』`, `【...】`, `A: B`, Katakana `[\u30A0-\u30FF]{2,}`) and keyword scoring dictionary for archetypes with anti-collision tech filters.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_context_analyzer.py -v`  
Expected: PASS (5 passed)

- [ ] **Step 5: Commit**

```bash
git add app/core/context_analyzer.py tests/test_context_analyzer.py
git commit -m "feat(core): implement offline ContextAnalyzer for entity extraction and archetype pronoun classification"
```

---

### Task 2: Dialogue Continuity & Mandatory A/B Comparative Test (`ContextEngine` & `PromptBuilder`)

**Files:**
- Modify: `app/core/context_engine.py:10-20`
- Modify: `app/core/prompt_builder.py:20-65`
- Create: `tests/test_comparative_translation.py`

**Interfaces:**
- Consumes: `ContextAnalyzer` archetype & pronoun constants from Task 1.
- Produces:
  - `ContextEngine.get_context(subtitles, index)` includes translations for `ACCEPTED`, `TRANSLATED`, and `EDITED` lines.
  - `PromptBuilder.build(..., active_pronoun_pair: str = "", canonical_names: tuple = ()) -> str`

- [ ] **Step 1: Write failing A/B comparative test in `tests/test_comparative_translation.py`**

```python
import pytest
from app.core.prompt_builder import PromptBuilder
from app.core.context_engine import ContextEngine
from app.core.context_analyzer import ContextAnalyzer

def test_mandatory_ab_comparative_prompt_difference():
    # 1. Baseline: No summary, no glossary
    baseline_prev = ["Hello there."]
    current_sub = "What do you want from me?"
    baseline_prompt = PromptBuilder.build(
        story_summary="",
        source_lang="English",
        target_lang="Vietnamese",
        prev_context=baseline_prev,
        current_sub=current_sub,
        next_context=[],
        active_pronoun_pair="",
    )

    # 2. Enriched: Ancient Fantasy summary with detected Ta - Ngươi
    summary = "Phim cổ trang kiếm hiệp, hai cao thủ đối đầu sinh tử"
    archetype, pronoun_pair = ContextAnalyzer.classify_archetype(summary)
    
    # Rolling context with translated previous subtitle
    enriched_prev = ["Ngươi muốn gì ở ta?"]
    enriched_prompt = PromptBuilder.build(
        story_summary=summary,
        source_lang="English",
        target_lang="Vietnamese",
        prev_context=enriched_prev,
        current_sub=current_sub,
        next_context=[],
        active_pronoun_pair=pronoun_pair,
        canonical_names=("Tiêu Viêm",),
    )

    # 3. Mandatory assertions
    assert enriched_prompt != baseline_prompt, "FAIL: Enriched prompt MUST be different from baseline!"
    assert "Ta - Ngươi" in enriched_prompt or "ta" in enriched_prompt.lower(), "FAIL: Enriched prompt MUST enforce Ta - Ngươi!"
    assert "Tiêu Viêm" in enriched_prompt, "FAIL: Canonical name must be injected!"
    assert "Ngươi muốn gì ở ta?" in enriched_prompt, "FAIL: Previous translated dialogue must be passed for continuity!"

def test_context_engine_includes_translated_status():
    subtitles = [
        {"original": "Line 1", "translation": "Câu 1 dịch xong", "status": "TRANSLATED"},
        {"original": "Line 2", "translation": "Câu 2 đã duyệt", "status": "ACCEPTED"},
        {"original": "Line 3", "translation": "", "status": "PENDING"},
    ]
    prev_ctx, current, next_ctx = ContextEngine.get_context(subtitles, 2)
    assert "Câu 1 dịch xong" in prev_ctx
    assert "Câu 2 đã duyệt" in prev_ctx
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_comparative_translation.py -v`  
Expected: FAIL

- [ ] **Step 3: Update `ContextEngine.py` and `PromptBuilder.py`**

In `ContextEngine`:
Allow `status in ["ACCEPTED", "TRANSLATED", "EDITED"]` to provide `sub.get("translation")` if non-empty.

In `PromptBuilder`:
Accept `active_pronoun_pair: str = ""` and `canonical_names: tuple = ()`. Under `if target_lang.lower() == "vietnamese":`, inject active pronoun pair instructions and dialogue continuity directives.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_comparative_translation.py -v`  
Expected: PASS (2 passed)

- [ ] **Step 5: Commit**

```bash
git add app/core/context_engine.py app/core/prompt_builder.py tests/test_comparative_translation.py
git commit -m "feat(core): enhance ContextEngine dialogue continuity, PromptBuilder pronoun biasing, and add mandatory A/B test"
```

---

### Task 3: Controller State Management & Persistence (`ProjectController` & `TranslationController`)

**Files:**
- Modify: `app/controllers/project_controller.py`
- Modify: `app/controllers/translation_controller.py`
- Create: `tests/test_project_intelligence_controller.py`

**Interfaces:**
- Produces:
  - `ProjectController.activeArchetype: str` (Q_PROPERTY)
  - `ProjectController.activePronounPair: str` (Q_PROPERTY)
  - `ProjectController.isArchetypeLocked: bool` (Q_PROPERTY)
  - `ProjectController.archetypeDisplayLabel: str` (Q_PROPERTY)
  - `ProjectController.archetypeList: list[dict]` (Q_PROPERTY)
  - `ProjectController.analyzeSummary(summary_text: str)` (Slot)
  - `ProjectController.selectArchetype(archetype_id: str, manual_lock: bool = True)` (Slot)
  - `ProjectController.dismissAutoTerm(source_term: str)` (Slot)
  - `TranslationController` consumes `active_pronoun_pair` when calling `PromptBuilder.build`.

- [ ] **Step 1: Write failing controller test in `tests/test_project_intelligence_controller.py`**

```python
import pytest
from unittest.mock import MagicMock
from app.controllers.project_controller import ProjectController
from app.core.context_analyzer import ARCHETYPE_ANCIENT_FANTASY, ARCHETYPE_ANIME_SCHOOL

def test_project_controller_summary_analysis_and_dismissal():
    ctrl = ProjectController()
    
    # 1. Analyze summary
    ctrl.analyzeSummary("Phim cổ trang kiếm hiệp, nhân vật \"Lăng Ba\": Khinh công")
    assert ctrl.activeArchetype == ARCHETYPE_ANCIENT_FANTASY
    assert ctrl.activePronounPair == "Ta - Ngươi"
    
    # 2. Check auto term added
    glossary = ctrl.glossary
    assert glossary is not None
    assert glossary.get("Lăng Ba") is not None
    assert glossary.get("Lăng Ba").is_auto is True

    # 3. Dismiss auto term
    ctrl.dismissAutoTerm("Lăng Ba")
    assert glossary.get("Lăng Ba") is None
    assert "Lăng Ba" in ctrl.dismissed_auto_terms

    # 4. Debounce again with same summary -> Must NOT resurrect dismissed term
    ctrl.analyzeSummary("Phim cổ trang kiếm hiệp, nhân vật \"Lăng Ba\": Khinh công")
    assert glossary.get("Lăng Ba") is None

    # 5. Manual selection locks archetype
    ctrl.selectArchetype(ARCHETYPE_ANIME_SCHOOL, manual_lock=True)
    assert ctrl.isArchetypeLocked is True
    assert ctrl.activeArchetype == ARCHETYPE_ANIME_SCHOOL
    assert ctrl.activePronounPair == "Tớ - Cậu"

    # Subsequent summary does not overwrite locked archetype
    ctrl.analyzeSummary("Phim cổ trang kiếm hiệp khác")
    assert ctrl.activeArchetype == ARCHETYPE_ANIME_SCHOOL
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_project_intelligence_controller.py -v`  
Expected: FAIL

- [ ] **Step 3: Implement controller state, persistence in `.aisrt`, and slots**

Update `ProjectController`:
- Add properties, `analyzeSummary`, `selectArchetype`, `dismissAutoTerm`.
- Add `dismissed_auto_terms = set()`.
- Add `active_archetype` and `active_pronoun_pair` to `saveProject` / `loadProject` `.aisrt` JSON.
Update `TranslationController`:
- Pass `active_pronoun_pair` from `ProjectController` to `PromptBuilder.build(...)`.
- Add regex sanitizer in `on_finished` stripping leading `[Line \d+]:`.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_project_intelligence_controller.py -v`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/project_controller.py app/controllers/translation_controller.py tests/test_project_intelligence_controller.py
git commit -m "feat(controller): implement archetype state, auto-glossary management, and .aisrt persistence"
```

---

### Task 4: Liquid Glass UI Controls (`TranslationWorkspace.qml` & `ContextInspector.qml`)

**Files:**
- Modify: `ui/qml/components/TranslationWorkspace.qml:45-85`
- Modify: `ui/qml/components/ContextInspector.qml:385-450, 465-545`
- Modify: `tests/e2e/test_batch_ui.py` or new UI test

**Interfaces:**
- Consumes: Controller properties and slots from Task 3.
- Produces:
  - Header Capsule `[ 🎭 Cổ Trang • Ta - Ngươi ▾ ]` with dropdown Menu in `TranslationWorkspace.qml`.
  - 2000ms debounce timer on `summaryInput` in `ContextInspector.qml`.
  - Dynamic Flow of Liquid Glass chips in Tab 2 with delete button `✕`.

- [ ] **Step 1: Write UI E2E test verifying elements exist and react**

```python
# In tests/e2e/test_archetype_ui.py
from tests.e2e.app_harness import AppHarness
from PySide6.QtCore import QCoreApplication

def test_archetype_capsule_and_summary_debounce():
    h = AppHarness(None)
    h.window.show()
    [QCoreApplication.processEvents() for _ in range(5)]

    capsule = h.driver.find("archetypeCapsule")
    assert capsule is not None
    assert capsule.property("visible") is True
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/e2e/test_archetype_ui.py -v`  
Expected: FAIL (capsule not found)

- [ ] **Step 3: Implement QML Components**

1. In `TranslationWorkspace.qml`:
   Add `archetypeCapsule` Rectangle with `MouseArea` and `Menu` for archetype selection, placed before `statusBadge`.
2. In `ContextInspector.qml`:
   - Tab 3: Add `Timer { id: summaryDebounceTimer; interval: 2000; repeat: false; onTriggered: projectController.analyzeSummary(summaryInput.text) }`.
   - Tab 2: Add dynamic Flow repeater showing chips:
     - Sapphire badge for auto terms with `✕` button calling `projectController.dismissAutoTerm(modelData.source_term)`.
     - Amber badge for manual terms.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/e2e/test_archetype_ui.py -v`  
Expected: PASS

- [ ] **Step 5: Run full regression and smoke test**

Run: `pytest tests/ -v` and `python main.py --smoke-test`  
Expected: All tests PASS, smoke test exit code 0.

- [ ] **Step 6: Commit**

```bash
git add ui/qml/components/TranslationWorkspace.qml ui/qml/components/ContextInspector.qml tests/e2e/test_archetype_ui.py
git commit -m "feat(ui): add archetype header capsule dropdown and debounced auto-glossary chips"
```
