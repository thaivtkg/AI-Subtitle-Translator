# Subtitle QA Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a real-time, non-blocking Subtitle Quality Assurance (QA) engine (CPS, CPL, line count, tag integrity, timing checks) with dynamic UI indicators, $O(1)$ Qt model caching, and an advisory SRT export confirmation prompt.

**Architecture:** Pure deterministic Python domain engine in `app/core/qa_engine.py` calculating reading metrics (with HTML entity unescaping, attribute-aware tag extraction, and self-closing tag handling); precalculated $O(1)$ QA caching in `SubtitleModel` (`item["_qa_severity"]`, `item["_qa_tooltip"]`); overloaded PySide6 slots in `ProjectController`; surfaced non-blockingly in QML views (`SubtitleListView`, `TranslationWorkspace`, `Main.qml`).

**Tech Stack:** Python 3.11, PySide6 (QAbstractListModel, Qt Quick/QML), pytest, pytest-qt, stdlib (`html`, `re`, `dataclasses`, `typing`).

**Spec:** `docs/superpowers/specs/2026-10-09-subtitle-qa-engine-design.md`

## Global Constraints

- **Python Version:** Python 3.11+
- **Zero Third-party Dependencies:** QA Engine must rely solely on Python stdlib (`html`, `re`, `dataclasses`, `typing`).
- **In-Memory Volatile State:** QA issues are cached dynamically in item dictionaries in-memory; no changes or migrations to `.aisrt` file persistence.
- **Performance Guarantee:** `SubtitleModel.data()` must NEVER perform dynamic regex or string calculations. QA results are computed during `load_data()` and `update_translation()`, ensuring $O(1)$ lookup during high-frequency Qt UI rendering.
- **Language & Conventions:** Python identifiers and functions in English; docstrings and user-facing messages in natural Vietnamese.
- **Advisory UX:** QA checks never block accepting edits (`Non-blocking`). Exporting with red errors prompts for user confirmation with an override option.

## Review Focus

1. **HTML Entities & Real Length:** Inputs like `Tom &amp; Jerry` or `Xin ch&agrave;o&nbsp;bạn` must be unescaped using `html.unescape` so character count accurately reflects the visual string length.
2. **Self-closing & Attribute-bearing Tags:** Tags like `<font color="#ff0000">text</font>` and self-closing tags `<br/>`, `<br />` must be parsed safely without falsely triggering `TAG_MISMATCH`.
3. **Empty Middle Lines & Trailing Whitespace:** Formats like `"Dòng 1\n\nDòng 2\n"` must strip blank lines before counting lines (`len([l for l in lines if l.strip()]) <= 2`).
4. **Timing Edge Cases:** Subtitles with `start_time >= end_time`, `end_time - start_time == 0`, or corrupted timestamp strings must return `TIME_ERROR` without throwing `ZeroDivisionError` or crashing.
5. **PySide6 Slot Overload:** `ProjectController.exportSrt` must use `@Slot(str)` and `@Slot(str, bool)` so QML calls with 1 or 2 arguments resolve without `TypeError`.

---

### Task 1: Core QA Engine (`app/core/qa_engine.py`)

**Files:**
- Create: `app/core/qa_engine.py`
- Test: `tests/test_qa_engine.py`

**Interfaces:**
- Produces:
  ```python
  @dataclass(frozen=True)
  class QAIssue:
      code: str        # 'TIME_ERROR', 'CPS_HIGH', 'CPL_LONG', 'LINE_OVERFLOW', 'TAG_MISMATCH'
      severity: str    # 'WARNING' or 'ERROR'
      message: str

  def time_to_ms(time_val: int | str) -> int: ...
  def strip_html_tags(text: str) -> str: ...
  def analyze_subtitle(start_time: int | str, end_time: int | str, original: str, translated: str) -> tuple[QAIssue, ...]: ...
  ```

- [ ] **Step 1: Write failing tests for Core QA Engine in `tests/test_qa_engine.py`**
  Cover TC-QA-01 (Sanitization & True Length with HTML entities), TC-QA-02 (Timing Resilience), TC-QA-03 (Boundary Correctness), TC-QA-04 (Line Overflow & Empty Middle Lines), TC-QA-05 (Tag Integrity with attributes and self-closing tags), and TC-QA-06 (Empty Subtitle Handling).

```python
import pytest
from app.core.qa_engine import QAIssue, analyze_subtitle, strip_html_tags, time_to_ms

def test_tc_qa_01_sanitization_and_html_entities():
    # "Tom &amp; Jerry" unescapes to "Tom & Jerry" (11 chars)
    assert strip_html_tags("Tom &amp; Jerry") == "Tom & Jerry"
    assert len(strip_html_tags("Tom &amp; Jerry")) == 11

    # "<i>Xin chào các bạn</i>" raw 22 chars -> clean 16 chars
    issues = analyze_subtitle(0, 1000, "Hello friends", "<i>Xin chào các bạn</i>")
    assert not any(i.code == "CPS_HIGH" for i in issues)

def test_tc_qa_02_timing_resilience_zero_or_negative():
    issues_zero = analyze_subtitle(1000, 1000, "Hi", "Chào")
    assert any(i.code == "TIME_ERROR" and i.severity == "ERROR" for i in issues_zero)

    issues_negative = analyze_subtitle(2000, 1000, "Hi", "Chào")
    assert any(i.code == "TIME_ERROR" and i.severity == "ERROR" for i in issues_negative)

    issues_invalid = analyze_subtitle("invalid", "00:00:02,000", "Hi", "Chào")
    assert any(i.code == "TIME_ERROR" and i.severity == "ERROR" for i in issues_invalid)

def test_tc_qa_03_cps_cpl_boundaries():
    # Exact CPS = 17.0 (17 chars in 1.0 sec) -> Pass
    text_17 = "12345678901234567"
    issues = analyze_subtitle(0, 1000, "Source", text_17)
    assert not any(i.code == "CPS_HIGH" for i in issues)

    # CPS 18.0 (18 chars in 1.0 sec) -> WARNING
    text_18 = "123456789012345678"
    issues = analyze_subtitle(0, 1000, "Source", text_18)
    cps_issues = [i for i in issues if i.code == "CPS_HIGH"]
    assert len(cps_issues) == 1 and cps_issues[0].severity == "WARNING"

    # CPS 21.0 (21 chars in 1.0 sec) -> ERROR
    text_21 = "123456789012345678901"
    issues = analyze_subtitle(0, 1000, "Source", text_21)
    cps_issues = [i for i in issues if i.code == "CPS_HIGH"]
    assert len(cps_issues) == 1 and cps_issues[0].severity == "ERROR"

    # Exact CPL = 40 -> Pass
    line_40 = "A" * 40
    issues = analyze_subtitle(0, 5000, "Source", line_40)
    assert not any(i.code == "CPL_LONG" for i in issues)

    # CPL = 41 -> WARNING
    line_41 = "A" * 41
    issues = analyze_subtitle(0, 5000, "Source", line_41)
    cpl_issues = [i for i in issues if i.code == "CPL_LONG"]
    assert len(cpl_issues) == 1 and cpl_issues[0].severity == "WARNING"

    # CPL = 43 -> ERROR
    line_43 = "A" * 43
    issues = analyze_subtitle(0, 5000, "Source", line_43)
    cpl_issues = [i for i in issues if i.code == "CPL_LONG"]
    assert len(cpl_issues) == 1 and cpl_issues[0].severity == "ERROR"

def test_tc_qa_04_line_overflow_and_empty_middle_lines():
    # 2 lines with accidental empty middle line -> Pass (only 2 real lines)
    text_with_empty_line = "Dòng 1\n\nDòng 2\n"
    issues = analyze_subtitle(0, 3000, "Source", text_with_empty_line)
    assert not any(i.code == "LINE_OVERFLOW" for i in issues)

    # 3 real lines -> ERROR
    text_3_lines = "Dòng 1\nDòng 2\nDòng 3"
    issues = analyze_subtitle(0, 3000, "Source", text_3_lines)
    line_issues = [i for i in issues if i.code == "LINE_OVERFLOW"]
    assert len(line_issues) == 1 and line_issues[0].severity == "ERROR"

def test_tc_qa_05_tag_integrity_attributes_and_self_closing():
    # Unclosed tag in translation
    issues = analyze_subtitle(0, 2000, "<i>Hello</i>", "<i>Xin chào")
    assert any(i.code == "TAG_MISMATCH" and i.severity == "ERROR" for i in issues)

    # Missing tag from source
    issues = analyze_subtitle(0, 2000, "<i>Hello</i>", "Xin chào")
    assert any(i.code == "TAG_MISMATCH" and i.severity == "ERROR" for i in issues)

    # Matching tags with attributes (e.g. font color)
    issues = analyze_subtitle(0, 2000, '<font color="#ff0000">Red</font>', '<font color="red">Đỏ</font>')
    assert not any(i.code == "TAG_MISMATCH" for i in issues)

    # Self-closing tag <br/> or <br /> does not trigger tag mismatch
    issues_br = analyze_subtitle(0, 2000, "Line 1<br/>Line 2", "Dòng 1<br />Dòng 2")
    assert not any(i.code == "TAG_MISMATCH" for i in issues_br)

def test_tc_qa_06_empty_or_whitespace_translation():
    assert analyze_subtitle(0, 2000, "Hello", "") == ()
    assert analyze_subtitle(0, 2000, "Hello", "   \n  ") == ()
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_qa_engine.py -v`
  Expected: FAIL with `ModuleNotFoundError: No module named 'app.core.qa_engine'`

- [ ] **Step 3: Implement `app/core/qa_engine.py`**
  Implement:
  - `QAIssue` dataclass (`code`, `severity`, `message`).
  - `time_to_ms`: handles integer milliseconds or SRT format `HH:MM:SS,mmm`.
  - `strip_html_tags`: `html.unescape(re.sub(r'<[^>]+>', '', text))` and strip leading/trailing whitespace.
  - Tag parity & balance:
    - Self-closing tags regex exclusion: ignore tags matching `<[^>]+/\s*>` or `<br\s*/?>`.
    - Tag name extraction: `re.findall(r'<\s*([a-zA-Z0-9]+)', ...)` ignoring case.
    - Stack-based tag balancing for translation.
    - Parity of tag names between source and target.
  - `analyze_subtitle`: integrates timing checks, duration calculation, CPS, CPL, line count (filtering empty lines), and tag integrity.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_qa_engine.py -v`
  Expected: PASS (all 6 tests pass)

- [ ] **Step 5: Commit**
  ```bash
  git add app/core/qa_engine.py tests/test_qa_engine.py
  git commit -m "feat(qa): implement core Subtitle QA Engine with CPS, CPL, unescape, and tag parity"
  ```

---

### Task 2: SubtitleModel $O(1)$ QA Roles (`app/models/subtitle.py`)

**Files:**
- Modify: `app/models/subtitle.py`
- Test: `tests/test_subtitle_model_qa.py`

**Interfaces:**
- Consumes: `app.core.qa_engine.analyze_subtitle`
- Produces:
  - `SubtitleModel.QaSeverityRole = Qt.UserRole + 7` (`qaSeverity` -> `""`, `"WARNING"`, `"ERROR"`)
  - `SubtitleModel.QaTooltipRole = Qt.UserRole + 8` (`qaTooltip` -> Multiline string of issue messages)
  - Method `get_qa_summary() -> dict` returning `{'total_errors': int, 'total_warnings': int}`

- [ ] **Step 1: Write failing tests for SubtitleModel QA roles in `tests/test_subtitle_model_qa.py`**

```python
import pytest
from PySide6.QtCore import QModelIndex
from app.models.subtitle import SubtitleModel

def test_subtitle_model_qa_roles_o1():
    model = SubtitleModel()
    data = [
        {
            "index": 1,
            "start_time": "00:00:01,000",
            "end_time": "00:00:02,000",
            "original": "Short text",
            "translation": "Câu ngắn chuẩn",
            "status": "TRANSLATED"
        },
        {
            "index": 2,
            "start_time": "00:00:03,000",
            "end_time": "00:00:04,000",
            "original": "Fast text",
            "translation": "Đây là câu dịch có tốc độ đọc cực kỳ nhanh vượt ngưỡng 20 ký tự trên giây",
            "status": "TRANSLATED"
        }
    ]
    model.load_data(data)

    idx_clean = model.index(0, 0)
    assert model.data(idx_clean, SubtitleModel.QaSeverityRole) == ""
    assert model.data(idx_clean, SubtitleModel.QaTooltipRole) == ""

    idx_error = model.index(1, 0)
    assert model.data(idx_error, SubtitleModel.QaSeverityRole) == "ERROR"
    assert "Tốc độ đọc" in model.data(idx_error, SubtitleModel.QaTooltipRole)

    # Verify cached fields in item dictionary
    assert data[0]["_qa_severity"] == ""
    assert data[1]["_qa_severity"] == "ERROR"

def test_subtitle_model_qa_reactivity():
    model = SubtitleModel()
    data = [{
        "index": 1,
        "start_time": "00:00:01,000",
        "end_time": "00:00:02,000",
        "original": "Hello",
        "translation": "",
        "status": "PENDING"
    }]
    model.load_data(data)
    idx = model.index(0, 0)
    assert model.data(idx, SubtitleModel.QaSeverityRole) == ""

    # Update to an error translation (CPS > 20)
    model.update_translation(0, "Câu này quá dài trong vòng một giây", "TRANSLATED")
    assert model.data(idx, SubtitleModel.QaSeverityRole) == "ERROR"
    assert data[0]["_qa_severity"] == "ERROR"

    # Fix it to a short translation
    model.update_translation(0, "Ngắn", "EDITED")
    assert model.data(idx, SubtitleModel.QaSeverityRole) == ""
    assert data[0]["_qa_severity"] == ""
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_subtitle_model_qa.py -v`
  Expected: FAIL with `AttributeError: type object 'SubtitleModel' has no attribute 'QaSeverityRole'`

- [ ] **Step 3: Modify `app/models/subtitle.py`**
  - Define `QaSeverityRole = Qt.UserRole + 7` and `QaTooltipRole = Qt.UserRole + 8`.
  - Add to `roleNames()`: `self.QaSeverityRole: b"qaSeverity"`, `self.QaTooltipRole: b"qaTooltip"`.
  - Add helper `_update_item_qa(sub)`:
    - Calls `analyze_subtitle(sub.get("start_time", 0), sub.get("end_time", 0), sub.get("original", ""), sub.get("translation", ""))`.
    - If issues: max severity (`"ERROR"` if any error else `"WARNING"`), tooltip is `"\n".join(i.message for i in issues)`.
    - Store directly in `sub["_qa_severity"]` and `sub["_qa_tooltip"]`.
  - In `load_data()`: call `self._update_item_qa(sub)` for each item.
  - In `update_translation()`: update `sub["translation"]`, call `self._update_item_qa(sub)`, and emit `dataChanged` with all affected roles.
  - In `data()`: perform strict $O(1)$ lookup: `sub.get("_qa_severity", "")` and `sub.get("_qa_tooltip", "")`.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_subtitle_model_qa.py -v`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add app/models/subtitle.py tests/test_subtitle_model_qa.py
  git commit -m "feat(qa): precompute and cache qaSeverity and qaTooltip in SubtitleModel for O(1) rendering"
  ```

---

### Task 3: Overloaded Export Hook in ProjectController (`app/controllers/project_controller.py`)

**Files:**
- Modify: `app/controllers/project_controller.py`
- Test: `tests/test_project_qa_export.py`

**Interfaces:**
- Produces:
  - Signal: `qaExportWarningRequired = Signal(str, int)`
  - Overloaded Slot:
    ```python
    @Slot(str)
    @Slot(str, bool)
    def exportSrt(self, file_path, force=False): ...
    ```

- [ ] **Step 1: Write failing test in `tests/test_project_qa_export.py`**

```python
import pytest
from app.controllers.project_controller import ProjectController
from app.models.subtitle import SubtitleModel

def test_export_intercept_when_qa_errors_exist(qtbot, tmp_path):
    model = SubtitleModel()
    controller = ProjectController(subtitle_model=model)
    export_path = str(tmp_path / "output.srt")

    # Load 1 valid item and 1 item with QA ERROR (CPL > 42)
    model.load_data([
        {
            "index": 1,
            "start_time": "00:00:01,000",
            "end_time": "00:00:05,000",
            "original": "Source 1",
            "translation": "Bản dịch 1",
            "status": "ACCEPTED"
        },
        {
            "index": 2,
            "start_time": "00:00:06,000",
            "end_time": "00:00:10,000",
            "original": "Source 2",
            "translation": "Dòng này cố tình vượt quá bốn mươi hai ký tự để kích hoạt lỗi QA Error tràn màn hình",
            "status": "ACCEPTED"
        }
    ])

    warning_emitted = []
    controller.qaExportWarningRequired.connect(lambda path, count: warning_emitted.append((path, count)))

    # 1-argument call without force -> must intercept
    controller.exportSrt(export_path)

    assert len(warning_emitted) == 1
    assert warning_emitted[0][0] == export_path
    assert warning_emitted[0][1] == 1

    # 2-argument call with force=True -> must export without extra warning
    controller.exportSrt(export_path, True)
    assert len(warning_emitted) == 1
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_project_qa_export.py -v`
  Expected: FAIL with `AttributeError: 'ProjectController' object has no attribute 'qaExportWarningRequired'`

- [ ] **Step 3: Modify `app/controllers/project_controller.py`**
  - Add `qaExportWarningRequired = Signal(str, int)`.
  - Decorate `exportSrt` with both `@Slot(str)` and `@Slot(str, bool)`.
  - In `exportSrt`:
    - Before writing file, check `subtitles`: count items where `sub.get("_qa_severity") == "ERROR"`.
    - If `not force` and `error_count > 0`: emit `qaExportWarningRequired.emit(file_path, error_count)` and return.
    - Otherwise proceed to `SRTExporter.export()`.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_project_qa_export.py -v`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add app/controllers/project_controller.py tests/test_project_qa_export.py
  git commit -m "feat(qa): add overloaded exportSrt slot with non-blocking QA error confirmation hook"
  ```

---

### Task 4: UI/UX Integration (QML)

**Files:**
- Modify: `ui/qml/components/SubtitleListView.qml`
- Modify: `ui/qml/components/TranslationWorkspace.qml`
- Modify: `ui/qml/Main.qml`

- [ ] **Step 1: Update `SubtitleListView.qml`**
  - In delegate: Add visual QA badge next to status:
    ```qml
    Text {
        visible: qaSeverity !== ""
        text: qaSeverity === "ERROR" ? "🛑" : "⚠️"
        font.pixelSize: 11
        ToolTip.visible: qaMouseArea.containsMouse
        ToolTip.text: qaTooltip
        MouseArea {
            id: qaMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
    ```

- [ ] **Step 2: Update `TranslationWorkspace.qml`**
  - Add live QA issue indicator in the translation header area showing current subtitle's QA status.

- [ ] **Step 3: Update `Main.qml` for Export Confirmation Dialog**
  - Connect to `projectController.qaExportWarningRequired(filePath, errorCount)` to open confirmation dialog.
  - On confirm ("Vẫn xuất"): call `projectController.exportSrt(targetFilePath, true)`.

- [ ] **Step 4: Verify QML syntax & bindings**
  Run pytest suite to verify no regressions in harness.

- [ ] **Step 5: Commit**
  ```bash
  git add ui/qml/components/SubtitleListView.qml ui/qml/components/TranslationWorkspace.qml ui/qml/Main.qml
  git commit -m "feat(ui): display QA warning/error badges and wire export confirmation dialog"
  ```

---

### Task 5: Full Regression Testing & Verification

**Files:**
- Test: All tests across the test suite

- [ ] **Step 1: Run complete test suite**
  Run: `pytest -v`
  Expected: All existing 242+ tests + new QA tests PASS.

- [ ] **Step 2: Commit and verify clean working tree**
  ```bash
  git status
  ```
