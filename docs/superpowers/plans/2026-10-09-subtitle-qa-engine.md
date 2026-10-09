# Subtitle QA Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a real-time, non-blocking Subtitle Quality Assurance (QA) engine (CPS, CPL, line count, tag integrity, timing checks) with dynamic UI indicators and an advisory SRT export confirmation prompt.

**Architecture:** Pure deterministic Python domain engine in `app/core/qa_engine.py` calculating reading metrics and tag consistency; dynamically bound to `SubtitleModel` through custom roles (`qaSeverity`, `qaTooltip`); surfaced non-blockingly in QML views (`SubtitleListView`, `TranslationWorkspace`, `Main.qml`).

**Tech Stack:** Python 3.11, PySide6 (QAbstractListModel, Qt Quick/QML), pytest, pytest-qt.

**Spec:** `docs/superpowers/specs/2026-10-09-subtitle-qa-engine-design.md`

## Global Constraints

- **Python Version:** Python 3.11+
- **Zero Third-party Dependencies:** QA Engine must rely solely on Python stdlib (`re`, `dataclasses`, `typing`).
- **In-Memory Volatile State:** QA issues are computed dynamically in-memory; no changes or migrations to `.aisrt` file persistence.
- **Language & Conventions:** Python identifiers and functions in English; docstrings and user-facing messages in natural Vietnamese.
- **Advisory UX:** QA checks never block accepting edits (`Non-blocking`). Exporting with red errors prompts for user confirmation with an override option.

## Review Focus

1. **Nested & Malformed HTML Tags:** Inputs like `<b><i>text</i></b>`, `<font color="red">text</font>`, or unclosed tags `<i>text` must be parsed safely without regex catastrophic backtracking.
2. **Timing Edge Cases:** Subtitles with `start_time >= end_time`, `end_time - start_time == 0`, or corrupted timestamp strings must return `TIME_ERROR` without throwing `ZeroDivisionError` or crashing.
3. **Multiline & Whitespace Edge Cases:** Trailing newlines, blank middle lines (e.g. `"Line 1\n\nLine 2"`), or leading/trailing whitespace must not skew line count or CPL calculations.
4. **Empty or Whitespace-only Translations:** Untranslated items (`""` or `"   "`) must return `()` and have severity `""` without falsely triggering CPS/tag errors.
5. **Dynamic Model Role Reactivity:** Editing a translation or updating timestamps in `SubtitleModel` must immediately update `qaSeverity` and `qaTooltip` roles for the affected rows.

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
  Cover TC-QA-01 (Sanitization & True Length), TC-QA-02 (Timing Resilience), TC-QA-03 (Boundary Correctness), TC-QA-04 (Line Overflow), TC-QA-05 (Tag Integrity), and TC-QA-06 (Empty Subtitle Handling).

```python
import pytest
from app.core.qa_engine import QAIssue, analyze_subtitle, strip_html_tags, time_to_ms

def test_tc_qa_01_sanitization_and_true_length():
    # "<i>Xin chào các bạn</i>" raw length is 22, clean length is 16.
    # Duration: 1000ms -> clean CPS is 16.0 (Pass <= 17.0). If tags weren't stripped, CPS would be 22.0 (Error).
    issues = analyze_subtitle(0, 1000, "Hello friends", "<i>Xin chào các bạn</i>")
    assert not any(i.code == "CPS_HIGH" for i in issues)

def test_tc_qa_02_timing_resilience_zero_or_negative():
    issues_zero = analyze_subtitle(1000, 1000, "Hi", "Chào")
    assert any(i.code == "TIME_ERROR" and i.severity == "ERROR" for i in issues_zero)

    issues_negative = analyze_subtitle(2000, 1000, "Hi", "Chào")
    assert any(i.code == "TIME_ERROR" and i.severity == "ERROR" for i in issues_negative)

    # Malformed timestamp string
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

def test_tc_qa_04_line_overflow():
    text_2_lines = "Dòng 1\nDòng 2"
    issues = analyze_subtitle(0, 3000, "Source", text_2_lines)
    assert not any(i.code == "LINE_OVERFLOW" for i in issues)

    text_3_lines = "Dòng 1\nDòng 2\nDòng 3"
    issues = analyze_subtitle(0, 3000, "Source", text_3_lines)
    line_issues = [i for i in issues if i.code == "LINE_OVERFLOW"]
    assert len(line_issues) == 1 and line_issues[0].severity == "ERROR"

def test_tc_qa_05_tag_integrity():
    # Unclosed tag in translation
    issues = analyze_subtitle(0, 2000, "<i>Hello</i>", "<i>Xin chào")
    assert any(i.code == "TAG_MISMATCH" and i.severity == "ERROR" for i in issues)

    # Missing tag that source had
    issues = analyze_subtitle(0, 2000, "<i>Hello</i>", "Xin chào")
    assert any(i.code == "TAG_MISMATCH" and i.severity == "ERROR" for i in issues)

    # Matching tags
    issues = analyze_subtitle(0, 2000, "<i>Hello</i>", "<i>Xin chào</i>")
    assert not any(i.code == "TAG_MISMATCH" for i in issues)

def test_tc_qa_06_empty_or_whitespace_translation():
    assert analyze_subtitle(0, 2000, "Hello", "") == ()
    assert analyze_subtitle(0, 2000, "Hello", "   \n  ") == ()
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_qa_engine.py -v`
  Expected: FAIL with `ModuleNotFoundError: No module named 'app.core.qa_engine'`

- [ ] **Step 3: Implement `app/core/qa_engine.py`**
  Implement pure logic for:
  - `QAIssue` dataclass.
  - `time_to_ms`: handles integer milliseconds or SRT format `HH:MM:SS,mmm`.
  - `strip_html_tags`: regex substitution for HTML tags.
  - Tag balancing and parity validation between original and translated.
  - `analyze_subtitle`: integrates timing checks, duration calculation, CPS, CPL, line count, and tag checks.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_qa_engine.py -v`
  Expected: PASS (all 6 tests pass)

- [ ] **Step 5: Commit**
  ```bash
  git add app/core/qa_engine.py tests/test_qa_engine.py
  git commit -m "feat(qa): implement core Subtitle QA Engine with CPS, CPL, line count and tag integrity"
  ```

---

### Task 2: SubtitleModel Dynamic QA Roles (`app/models/subtitle.py`)

**Files:**
- Modify: `app/models/subtitle.py`
- Test: `tests/test_subtitle_model_qa.py`

**Interfaces:**
- Consumes: `app.core.qa_engine.analyze_subtitle`
- Produces:
  - `SubtitleModel.QaSeverityRole = Qt.UserRole + 7` (`qaSeverity` -> `""`, `"WARNING"`, `"ERROR"`)
  - `SubtitleModel.QaTooltipRole = Qt.UserRole + 8` (`qaTooltip` -> Multiline string of issue messages)
  - Helper `get_qa_summary() -> dict` returning `{'total_errors': int, 'total_warnings': int}`

- [ ] **Step 1: Write failing tests for SubtitleModel QA roles in `tests/test_subtitle_model_qa.py`**

```python
import pytest
from PySide6.QtCore import QModelIndex
from app.models.subtitle import SubtitleModel

def test_subtitle_model_qa_roles():
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

    # Fix it to a short translation
    model.update_translation(0, "Ngắn", "EDITED")
    assert model.data(idx, SubtitleModel.QaSeverityRole) == ""
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_subtitle_model_qa.py -v`
  Expected: FAIL with `AttributeError: type object 'SubtitleModel' has no attribute 'QaSeverityRole'`

- [ ] **Step 3: Modify `app/models/subtitle.py`**
  - Define `QaSeverityRole` and `QaTooltipRole`.
  - Add to `roleNames()`: `b"qaSeverity"` and `b"qaTooltip"`.
  - In `data()`: compute or cache QA issues on the item, return max severity and concatenated tooltip.
  - Implement `get_qa_summary()` to return overall project error and warning counts.
  - In `update_translation()`: emit `dataChanged` for roles including `QaSeverityRole` and `QaTooltipRole`.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_subtitle_model_qa.py -v`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add app/models/subtitle.py tests/test_subtitle_model_qa.py
  git commit -m "feat(qa): expose dynamic qaSeverity and qaTooltip roles in SubtitleModel"
  ```

---

### Task 3: Export Confirmation Prompt in ProjectController (`app/controllers/project_controller.py`)

**Files:**
- Modify: `app/controllers/project_controller.py`
- Test: `tests/test_project_qa_export.py`

**Interfaces:**
- Produces:
  - Signal: `qaExportWarningRequired(str, int)` with `(file_path, error_count)`
  - Parameter `force: bool = False` in `exportSrt(self, file_path, force=False)`

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

    # Attempt export without force
    controller.exportSrt(export_path, force=False)

    assert len(warning_emitted) == 1
    assert warning_emitted[0][0] == export_path
    assert warning_emitted[0][1] == 1  # 1 error item

    # Attempt export with force=True -> succeeds without intercept
    controller.exportSrt(export_path, force=True)
    assert len(warning_emitted) == 1  # No extra warning
```

- [ ] **Step 2: Run test to verify failure**
  Run: `pytest tests/test_project_qa_export.py -v`
  Expected: FAIL with `AttributeError: 'ProjectController' object has no attribute 'qaExportWarningRequired'`

- [ ] **Step 3: Modify `app/controllers/project_controller.py`**
  - Add `qaExportWarningRequired = Signal(str, int)`.
  - In `exportSrt(self, file_path, force=False)`:
    - Before writing file, check for subtitles with `QaSeverityRole == "ERROR"`.
    - If `not force` and `error_count > 0`: emit `qaExportWarningRequired.emit(file_path, error_count)` and return.
    - Otherwise proceed to `SRTExporter.export()`.

- [ ] **Step 4: Run tests to verify pass**
  Run: `pytest tests/test_project_qa_export.py -v`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add app/controllers/project_controller.py tests/test_project_qa_export.py
  git commit -m "feat(qa): add non-blocking export intercept for severe QA errors"
  ```

---

### Task 4: UI/UX Integration (QML)

**Files:**
- Modify: `ui/qml/components/SubtitleListView.qml`
- Modify: `ui/qml/components/TranslationWorkspace.qml`
- Modify: `ui/qml/Main.qml`

**Interfaces:**
- Consumes:
  - `model.qaSeverity` and `model.qaTooltip` in `SubtitleListView`
  - `projectController.qaExportWarningRequired(filePath, errorCount)` in `Main.qml`

- [ ] **Step 1: Update `SubtitleListView.qml` to display QA badge & ToolTip**
  - In delegate: Add visual badge indicator:
    - If `qaSeverity === "ERROR"`: `🛑` (danger color).
    - If `qaSeverity === "WARNING"`: `⚠️` (warning yellow color).
    - Attach a native QML `ToolTip` to display `qaTooltip` when hovering over the indicator.

- [ ] **Step 2: Update `TranslationWorkspace.qml`**
  - Display QA indicator and message preview next to the translation character counter or header so translator immediately sees live feedback while editing.

- [ ] **Step 3: Update `Main.qml` for Export Confirmation Dialog**
  - Add connection:
    ```qml
    Connections {
        target: projectController
        function onQaExportWarningRequired(filePath, errorCount) {
            qaConfirmDialog.targetFilePath = filePath
            qaConfirmDialog.errorCount = errorCount
            qaConfirmDialog.open()
        }
    }
    ```
  - Define Dialog with message: `"Có " + errorCount + " dòng phụ đề vi phạm quy tắc hiển thị (Lỗi đỏ). Bạn có chắc chắn muốn xuất file không?"`
  - Action "Vẫn xuất": `projectController.exportSrt(targetFilePath, true)`.

- [ ] **Step 4: Verify QML syntax & bindings**
  Run: `python -c "from PySide6.QtQml import QQmlApplicationEngine; from PySide6.QtCore import QCoreApplication; app = QCoreApplication([]); engine = QQmlApplicationEngine(); ..."` or run full test suite.

- [ ] **Step 5: Commit**
  ```bash
  git add ui/qml/components/SubtitleListView.qml ui/qml/components/TranslationWorkspace.qml ui/qml/Main.qml
  git commit -m "feat(ui): add QA issue indicators, tooltips, and export confirmation dialog in QML"
  ```

---

### Task 5: Full Regression Testing & Verification

**Files:**
- Test: All tests in `tests/`

- [ ] **Step 1: Run complete test suite**
  Run: `pytest -v`
  Expected: All 242+ previous tests plus new QA tests PASS (approx 255+ tests total).

- [ ] **Step 2: Commit and verify clean working tree**
  ```bash
  git status
  ```
