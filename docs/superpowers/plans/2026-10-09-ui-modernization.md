# UI/UX Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement UI/UX Modernization (v1.2) for AI Subtitle Translator: 100% Vietnamese localization, interactive Drag-and-Drop workspace, reclaimed 48px vertical space via integrated Header Batch Control, collapsed empty Context Inspector, and enhanced disabled button contrast.

**Architecture:** Pure Qt Quick / QML modular components (`HeaderBatchControl.qml`, `AppHeader.qml`, `EmptyWorkspace.qml`, `ContextInspector.qml`, `SubtitleListView.qml`, `TranslationWorkspace.qml`, `AppButton.qml`, `Theme.qml`); URL scheme sanitization in `ProjectController`; zero backend schema alterations.

**Tech Stack:** Python 3.11, PySide6 (Qt Quick 2.15, Qt Quick Controls 2.15, Qt Quick Layouts 1.15), pytest, pytest-qt.

**Spec:** `docs/superpowers/specs/2026-10-09-ui-modernization-design.md`

## Global Constraints

- **Zero Invariant Violations:** All automated test object names (`objectName`) must remain identical.
- **Zero Third-party Dependencies:** Use native Qt Quick features (`DropArea`, `ToolTip`, `ColorAnimation`).
- **Responsive Layout Integrity:** Application must adapt gracefully across target resolutions (1024x600, 1280x720, 1366x768).
- **Test Baseline:** All 255 existing automated tests must pass.

---

### Task 1: Theme & Disabled Button Contrast

**Files:**
- Modify: `ui/qml/theme/Theme.qml`
- Modify: `ui/qml/components/AppButton.qml`

- [ ] **Step 1: Update `Theme.qml` with refined disabled tokens**
  Ensure clear contrast between disabled elements and dark surfaces.
- [ ] **Step 2: Update `AppButton.qml` border and opacity styling**
  Render visible border `Theme.border` when disabled (instead of transparent) and maintain distinct disabled typography.
- [ ] **Step 3: Verify button rendering via automated/smoke test**
  Run `python -m pytest tests/e2e/test_driver_smoke.py -v`.

---

### Task 2: 100% Vietnamese Localization

**Files:**
- Modify: `ui/qml/components/SubtitleListView.qml`
- Modify: `ui/qml/components/TranslationWorkspace.qml`
- Modify: `ui/qml/components/AppStatusBar.qml`

- [ ] **Step 1: Localize `SubtitleListView.qml`**
  - Header: `"DANH SÁCH CÂU"`
  - Counter: `subListView.filteredCount + " / " + subListView.count + " câu"`
  - Search placeholder: `"Tìm kiếm nội dung..."`
  - Filter combo display: `"Tất cả trạng thái"` (preserving underlying filter enum model `["ALL", "PENDING", ...]`).
- [ ] **Step 2: Localize `TranslationWorkspace.qml`**
  - Section headers: `"CÂU GỐC"`, `"BẢN DỊCH TIẾNG VIỆT"`
  - Status label: `"Trạng thái:"`
  - Status badges: `"Đang dịch…"`, `"LỖI ✕"`, `"[ ĐÃ DUYỆT ]"`, `"ĐÃ SỬA ●"`, `"ĐÃ DỊCH ✦"`, `"CHỜ DỊCH"`
  - Action buttons: `btnRetry` ("Thử lại"), `btnTranslate` ("Dịch câu" / "◌ Đang dịch..."), `btnAccept` ("Chấp nhận")
  - Error and placeholder messages.
- [ ] **Step 3: Localize `AppStatusBar.qml`**
  - Empty status: `"Chưa mở dự án"`
  - Counter format: `"✓ " + acceptedCount + " / " + totalCount + " Đã duyệt · " + progressPercent + "%"`
- [ ] **Step 4: Verify localization with smoke tests**
  Run `python -m pytest tests/e2e/test_driver_smoke.py tests/e2e/test_final_regression.py -v`.

---

### Task 3: Context Inspector Optimization

**Files:**
- Modify: `ui/qml/components/ContextInspector.qml`

- [ ] **Step 1: Refactor `ContextInspector.qml` structure**
  - Section header: `"BỐI CẢNH & QUY TẮC"` for Story Summary
  - When no subtitle is selected (`!translationController.currentOriginal`):
    - Hide the 3 separate empty context cards.
    - Display a single centered guide card with opacity `0.45`:
      *"Ngữ cảnh trước/sau sẽ hiển thị khi bạn chọn một câu phụ đề"*
  - When a subtitle is selected:
    - Display `"CÂU TRƯỚC"`, `"◆ CÂU HIỆN TẠI"`, `"CÂU KẾ TIẾP"` with Vietnamese labels.
- [ ] **Step 2: Ensure `storySummaryInput` remains intact and reachable via Tab**
  Verify `test_tc15_02_keyboard_navigation` passes.

---

### Task 4: EmptyWorkspace Drag-and-Drop (`DropArea`)

**Files:**
- Modify: `ui/qml/components/EmptyWorkspace.qml`
- Modify: `app/controllers/project_controller.py` (Windows URL safety guard)

- [ ] **Step 1: Add path format safety guard in `project_controller.py`**
  Ensure `importSrt` and `loadProject` safely accept both `file:///` URLs and plain native filesystem paths without breaking.
- [ ] **Step 2: Implement interactive `DropArea` in `EmptyWorkspace.qml`**
  - Add native `DropArea` accepting `.srt` and `.aisrt`.
  - Format guard in `onEntered`: validate extension and reject non-subtitles.
  - Action dispatch in `onDropped`: dispatch to `projectController.importSrt` or `projectController.loadProject`.
  - Dynamic visual card with border glow (`Theme.accentCyan`) and icon change (`📥`) on `containsDrag`.
  - Localized prompt text and buttons (`[Mở file SRT]`, `[Mở file dự án]`).
- [ ] **Step 3: Verify DropArea functionality and test compatibility**
  Run `python -m pytest tests/test_project_qa_export.py -v`.

---

### Task 5: Header Batch Control & Vertical Space Reclaim

**Files:**
- Create: `ui/qml/components/HeaderBatchControl.qml`
- Modify: `ui/qml/components/AppHeader.qml`
- Modify: `ui/qml/Main.qml`

- [ ] **Step 1: Create `HeaderBatchControl.qml`**
  - Retain `objectName: "batchControlBar"`
  - Include all sub-elements with exact `objectName`s:
    `batchStatusText`, `batchProgressText`, `btnBatchStart`, `btnBatchPause`, `btnBatchResume`, `btnBatchCancel`, `btnBatchRetryFailed`
  - Compact IDLE layout: only show `[Dịch tự động]` button.
  - Active layout: display status, progress, and control buttons inline.
- [ ] **Step 2: Embed `HeaderBatchControl` in `AppHeader.qml`**
  - Add `sourceLanguage`, `targetLanguage`, and `storySummary` properties to `AppHeader`.
  - Place `HeaderBatchControl` within the action toolbar row.
  - Localize header buttons (`Mở SRT`, `Mở dự án`, `Lưu`, `Xuất SRT`) and chip (`✓ Đã lưu`, `● Chưa lưu`).
- [ ] **Step 3: Update `Main.qml`**
  - Remove standalone `BatchControlBar` row.
  - Bind `AppHeader` batch properties (`sourceLanguage`, `targetLanguage`, `storySummary`).
  - Reclaim 48px vertical space for `SplitView`.
- [ ] **Step 4: Update test assertions for localized strings in `tests/e2e/test_batch_ui.py` & `test_final_regression.py`**
  Ensure both English fallback and Vietnamese localized strings satisfy E2E assertions.

---

### Task 6: Full Verification & Integration

- [ ] **Step 1: Run complete test suite**
  Run `python -m pytest tests/ -q` to verify all 255+ tests pass without error.
- [ ] **Step 2: Run responsive layout test**
  Verify `test_tc15_14_responsive_layout` passes across 1024x600, 1280x720, and 1366x768 resolutions.
- [ ] **Step 3: Commit changes to `feat-ui-modernization`**
  Stage and commit all changes cleanly.
