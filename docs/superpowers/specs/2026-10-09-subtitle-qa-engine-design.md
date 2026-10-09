# Feature 1.1: Subtitle QA Engine — Design Spec v1

**Status:** Approved
**Date:** 2026-10-09
**Scope:** Real-time, non-blocking Subtitle Quality Assurance (CPS, CPL, Lines, Tags, Timings)
**Depends on:**
- Phase 1 Core Domain Model (`SubtitleItem`, `Project`)
- Phase 2 UI/UX (`SubtitleModel`, `SubtitleTableView.qml`)
- Phase 3B Pipeline & Translation Intelligence

---

## 1. Intent and Success Criteria

Provide an automated, industry-standard (Netflix / BBC guidelines) Subtitle Quality Assurance engine running in real-time. The engine checks reading speeds, line lengths, line counts, and tag formatting to guide translators toward optimal readability and viewer comfort.

### Success Criteria:

- **Pure Logic & Zero Overhead:** The QA engine runs purely on deterministic math and string parsing (0 LLM tokens, 0ms I/O latency).
- **True Readable Length:** CPS and CPL are computed strictly against sanitized text with all HTML formatting tags stripped (`<i>`, `<b>`, `<font>`, etc.), accurately reflecting human eye reading load.
- **Robust Boundary Guards:** Timing anomalies such as zero duration or inverted timestamps (`end_ms <= start_ms`) are safely caught without throwing `ZeroDivisionError`.
- **In-Memory Volatility (Ponytail Architecture):** QA issues are computed on-the-fly and cached in memory. The `.aisrt` file schema remains unchanged and unbloated by transient QA state.
- **Advisory, Non-Blocking UX:** The system advises rather than restricts. Translators are never blocked from accepting edits. Non-intrusive visual badges (⚠️ Warning, 🛑 Error) and hover tooltips guide users in `SubtitleTableView`, with an optional gentle confirmation prompt during final SRT export if errors exist.

---

## 2. Core Domain Models (`app/core/qa_engine.py`)

The engine uses lightweight, immutable dataclasses:

```python
from dataclasses import dataclass
from typing import Tuple

@dataclass(frozen=True)
class QAIssue:
    code: str        # 'TIME_ERROR', 'CPS_HIGH', 'CPL_LONG', 'LINE_OVERFLOW', 'TAG_MISMATCH'
    severity: str    # 'WARNING' (Soft limit) or 'ERROR' (Hard limit)
    message: str     # Human-readable Vietnamese description
```

---

## 3. QA Rules & Thresholds

The core entry point is:
```python
def analyze_subtitle(start_ms: int, end_ms: int, original: str, translated: str) -> Tuple[QAIssue, ...]:
    ...
```

### 3.1 Pre-checks and Sanitization
1. **Empty Translation Guard:** If `not translated or not translated.strip()`, returns `()` immediately (untranslated lines are not flagged).
2. **Timing Validation:**
   - If `end_ms <= start_ms`: Flag `QAIssue(code='TIME_ERROR', severity='ERROR', message='Lỗi timestamp: Thời lượng kết thúc nhỏ hơn hoặc bằng thời lượng bắt đầu.')`.
   - Effective duration calculation: `duration_sec = max(0.1, (end_ms - start_ms) / 1000.0)`.
3. **HTML Stripping:**
   - `clean_text = re.sub(r'<[^>]+>', '', translated)`
   - Strips leading/trailing spaces for length evaluation.

### 3.2 Reading Speed (CPS - Characters Per Second)
- Computed as: `cps = len(clean_text) / duration_sec`
- Thresholds (Vietnamese standard):
  - `cps <= 17.0`: **Optimal (Pass)**
  - `17.0 < cps <= 20.0`: **WARNING** (`code='CPS_HIGH'`, message: `f"Tốc độ đọc hơi nhanh ({cps:.1f} ký tự/giây > 17)"`)
  - `cps > 20.0`: **ERROR** (`code='CPS_HIGH'`, message: `f"Tốc độ đọc quá nhanh ({cps:.1f} ký tự/giây > 20)"`)

### 3.3 Line Length (CPL - Characters Per Line)
- The sanitized text is split into lines via `clean_text.splitlines()`.
- Maximum line length: `max_cpl = max((len(line.strip()) for line in clean_text.splitlines()), default=0)`
- Thresholds:
  - `max_cpl <= 40`: **Optimal (Pass)**
  - `40 < max_cpl <= 42`: **WARNING** (`code='CPL_LONG'`, message: `f"Dòng hơi dài ({max_cpl} ký tự > 40)"`)
  - `max_cpl > 42`: **ERROR** (`code='CPL_LONG'`, message: `f"Dòng quá dài, nguy cơ tràn màn hình ({max_cpl} ký tự > 42)"`)

### 3.4 Line Count
- Number of lines: `line_count = len(clean_text.splitlines())`
- Thresholds:
  - `line_count <= 2`: **Pass**
  - `line_count >= 3`: **ERROR** (`code='LINE_OVERFLOW'`, message: `f"Số dòng vượt quá quy định ({line_count} dòng > 2 dòng)"`)

### 3.5 Tag Integrity
Checks consistency of HTML formatting tags:
1. **Tag Balance in Translation:**
   - Detect unclosed or malformed tags in `translated` (e.g. `<i>` without matching `</i>`, `<b>` without `</b>`).
   - If unbalanced: **ERROR** (`code='TAG_MISMATCH'`, message="Thẻ định dạng HTML không được đóng đúng cách.").
2. **Source-to-Target Parity:**
   - Extract unique tag types from `original` (e.g. `['i', 'b', 'font']`).
   - If `original` contains formatting tags not found in `translated`: **ERROR** (`code='TAG_MISMATCH'`, message="Bản dịch bị thiếu thẻ định dạng từ bản gốc.").

---

## 4. UI/UX Integration Architecture

### 4.1 SubtitleModel Extensions (`app/controllers/project_controller.py` or `SubtitleModel`)
- New custom roles exposed to QML:
  - `QaSeverityRole` (`Qt.UserRole + 20`): String enum (`""`, `"WARNING"`, `"ERROR"`).
  - `QaTooltipRole` (`Qt.UserRole + 21`): Formatted multiline string containing all active issue messages.
- Dynamic evaluation:
  - Computed on subtitle load or whenever `translated_text` / timestamps change.
  - No database migration or file format changes.

### 4.2 Table View Integration (`ui/qml/components/SubtitleTableView.qml`)
- A subtle indicator icon appears next to the translated text or in the Status column:
  - If `qaSeverity === "WARNING"`: Yellow icon `⚠️`
  - If `qaSeverity === "ERROR"`: Red icon `🛑`
  - If empty: No icon shown
- Hovering the indicator displays a native QML `ToolTip` detailing each message.

### 4.3 Export Confirmation Prompt
- When `export_srt` is triggered:
  - Project scans all items for `severity == 'ERROR'`.
  - If error items exist, UI displays a non-blocking confirmation dialog:
    *"Có {count} dòng phụ đề vi phạm quy tắc hiển thị (Lỗi đỏ). Bạn có chắc chắn muốn xuất file không?"*
    Buttons: `[Vẫn xuất (Continue)]` | `[Hủy (Cancel)]`.

---

## 5. Acceptance Contract & Verification

1. **TC-QA-01 (Sanitization & True Length):** Verifies HTML tags (`<i>`, `<b>`, `<font color="...">`) are completely stripped prior to length and CPS counting.
2. **TC-QA-02 (Timing Resilience):** Zero and negative durations return `TIME_ERROR` without throwing exceptions or division-by-zero errors.
3. **TC-QA-03 (Boundary Correctness):** Exactly 17.0 CPS and 40 CPL return zero issues.
4. **TC-QA-04 (Line Overflow):** 3-line subtitles trigger `LINE_OVERFLOW` with `ERROR` severity.
5. **TC-QA-05 (Tag Integrity):** Missing closing tag or lost italic tag produces `TAG_MISMATCH`.
6. **TC-QA-06 (Empty Subtitle Handling):** Blank or untranslated lines produce empty issues tuple `()`.
7. **TC-QA-07 (Model & Export Signaling):** `SubtitleModel` exposes correct severity roles, and export intercept signals prompt when errors exist.
