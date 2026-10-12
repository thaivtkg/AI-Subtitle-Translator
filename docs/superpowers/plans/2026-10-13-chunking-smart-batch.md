# P1.3 Chunking & Smart Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai tính năng dịch Batch giới hạn (10, 50, Toàn bộ) với cơ chế xoay vòng quota (Circular Roll-over) tính từ con trỏ chuột, kết hợp Bộ lọc phân đoạn 50 câu O(1) trên giao diện Studio Workspace 2.0.

**Architecture:** Mở rộng `BatchController.startBatch` với slot overload nhận `start_index` và `limit`, thu thập các target index hợp lệ theo thứ tự `range(start, total) + range(0, start)` mà không sửa đổi `BatchTranslationService` hay cấu trúc `BatchJob`. Trên giao diện QML, tích hợp Split Action Button với menu presets trên `HeaderBatchControl.qml` và bổ sung `chunkFilterCombo` O(1) trên `SubtitleListView.qml`.

**Tech Stack:** Python 3.11, PySide6 (QtCore, QtQuick Controls 2, QML), Pytest, Pytest-Qt.

**Spec:** `docs/superpowers/specs/2026-10-13-chunking-smart-batch-design.md`

## Global Constraints
- **PySide6 Slot Overload:** Bắt buộc hỗ trợ gọi `startBatch(source, target, summary)` không tham số bổ sung để bảo toàn tương thích ngược 100% với 255 bài test hiện có.
- **O(1) QML View Filter:** Giữ nguyên `SubtitleModel` dữ liệu, chỉ ẩn/hiện delegate thông qua điều kiện số nguyên để bảo toàn khả năng Tìm kiếm toàn cục (`searchInput`) và Ngữ cảnh trước/sau (`ContextInspector`).
- **Zero Schema Pollution:** Không lưu cấu hình chunk hay limit vào file `.aisrt`.
- **Zero Regressions:** 255/255 test suite hiện tại phải duy trì 100% PASSED.

## Review Focus
- **Circular Roll-over Quota:** Khi `start_index` nằm gần cuối file (ví dụ câu 1480/1500) và yêu cầu `limit=50`, thuật toán phải lấy nốt 20 câu cuối và vòng lại đầu file lấy thêm 30 câu PENDING để đủ quota 50.
- **Quota Exhaustion:** Nếu toàn bộ file chỉ còn 7 câu PENDING nhưng người dùng chọn `limit=50`, batch job phải nhận 7 câu, hoàn tất đúng 7 câu và tự động kích hoạt `COMPLETED`.
- **Progress Projection:** Khi chạy lô có giới hạn (ví dụ 10 câu), progress text trên Header phải hiển thị theo lô `(completed / total)` (ví dụ: `4/10`) thay vì tổng số câu của toàn file.
- **Non-Pending Skipping:** Tuyệt đối không đếm các câu `TRANSLATED`, `EDITED`, `ACCEPTED` vào số lượng câu cần dịch của batch.
- **Empty Job Guard:** Nếu toàn file không còn câu nào ở trạng thái `PENDING` hoặc `ERROR`, `canStart` giữ nguyên `False` và không tạo job rỗng.

---

### Task 1: Backend `BatchController` Start Index, Circular Roll-over Quota & Overload Slot

**Files:**
- Modify: `app/controllers/batch_controller.py:123-144`
- Test: `tests/test_batch_controller.py`

**Interfaces:**
- Consumes: `SubtitleModel.get_all_data()`, `compute_source_hash`, `BatchJob.create()`, `self._service.start()`
- Produces: 
  - `@Slot(str, str, str)`
  - `@Slot(str, str, str, int)`
  - `@Slot(str, str, str, int, int)`
  - `startBatch(source_lang, target_lang, story_summary, start_index=0, limit=0) -> None`

- [ ] **Step 1: Viết failing tests cho `startBatch` với start_index, limit và circular roll-over**

Trong `tests/test_batch_controller.py`, thêm các test cases:
```python
def test_batch_start_with_limit_and_circular_rollover():
    # Model gồm 10 câu: câu 0..7 TRANSLATED, câu 8..9 PENDING, câu 0..1 PENDING lại
    ...
    # start_index = 8, limit = 4 -> lấy [8, 9] rồi vòng lại lấy [0, 1]
    controller.startBatch("en", "vi", "", start_index=8, limit=4)
    assert controller.totalCount == 4
    assert list(controller._job.items.keys()) == [8, 9, 0, 1]

def test_batch_start_backward_compatible_signature():
    # Gọi startBatch 3 tham số không có start_index, limit
    controller.startBatch("en", "vi", "")
    assert controller.state == "RUNNING"
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `pytest tests/test_batch_controller.py -k "rollover" -v`
Expected: FAIL (tham số không hỗ trợ hoặc kết quả không khớp).

- [ ] **Step 3: Cập nhật `startBatch` trong `app/controllers/batch_controller.py`**

Triển khai thuật toán circular order:
```python
    @Slot(str, str, str)
    @Slot(str, str, str, int)
    @Slot(str, str, str, int, int)
    def startBatch(self, source_lang, target_lang, story_summary, start_index=0, limit=0):
        if not self.canStart:
            raise RuntimeError("Cannot start batch")

        all_data = self._subtitle_model.get_all_data()
        total_len = len(all_data)
        if total_len == 0:
            return

        start_pos = max(0, min(start_index, total_len - 1))
        # Duyệt tuần hoàn từ start_pos đến hết rồi vòng lại từ 0 đến start_pos
        traversal_order = list(range(start_pos, total_len)) + list(range(0, start_pos))
        
        target_indices = []
        seen = set()
        for idx in traversal_order:
            if idx in seen:
                continue
            seen.add(idx)
            st = str(all_data[idx].get("status", "PENDING")).upper()
            if st in ("PENDING", "ERROR"):
                target_indices.append(idx)
                if limit > 0 and len(target_indices) >= limit:
                    break

        if not target_indices:
            return

        items = {
            index: BatchItem(
                target_index=index,
                source_hash=compute_source_hash(str(all_data[index].get("original", ""))),
            )
            for index in target_indices
        }
        self._config = (source_lang, target_lang, story_summary)
        self._job = BatchJob.create(self._project_id, items)
        self._cancel_pending = False
        configure = getattr(self._service, "configure", None)
        if configure is not None:
            configure(source_lang, target_lang, story_summary)
        self._service.start(self._job)
        self._refresh()
```

- [ ] **Step 4: Chạy test để xác nhận tất cả test trong `test_batch_controller.py` đều pass**

Run: `pytest tests/test_batch_controller.py -v`
Expected: PASS 100%.

- [ ] **Step 5: Commit thay đổi**

```bash
git add app/controllers/batch_controller.py tests/test_batch_controller.py
git commit -m "feat(batch): support start_index, limit and circular roll-over quota in startBatch"
```

---

### Task 2: Frontend `HeaderBatchControl.qml` Split Button & Preset Selection

**Files:**
- Modify: `ui/qml/components/HeaderBatchControl.qml`
- Test: `tests/e2e/test_batch_ui.py`

**Interfaces:**
- Consumes: `root.controller.startBatch(source, target, summary, start_index, limit)`
- Produces: 
  - `property int selectedLimit: 50`
  - `objectName: "btnBatchStart"`
  - `objectName: "btnBatchPresetMenu"`
  - Dark Theme `Menu` với 3 preset: `10`, `50`, `0 (Toàn bộ)`

- [ ] **Step 1: Viết failing test trong `tests/e2e/test_batch_ui.py` kiểm tra startBatch với custom limit**

Thêm test case kiểm tra batch chỉ chạy đúng số lượng câu của preset:
```python
def test_tc_p3a7_custom_batch_limit_execution():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("fast"))
    try:
        # Bắt đầu batch với limit = 2 câu
        harness.batch_controller.startBatch("English", "Vietnamese", "", 0, 2)
        wait_for(harness, lambda: harness.batch_controller.state == "COMPLETED")
        assert harness.batch_controller.totalCount == 2
        assert harness.batch_controller.completedCount == 2
    finally:
        harness.close()
```

- [ ] **Step 2: Chạy test để xác nhận test chạy đúng logic**

Run: `pytest tests/e2e/test_batch_ui.py -k "custom_batch_limit" -v`
Expected: PASS.

- [ ] **Step 3: Cập nhật giao diện `HeaderBatchControl.qml`**

- Thêm property:
  ```qml
  property int selectedLimit: 50
  property int currentSubtitleIndex: 0
  ```
- Nâng cấp nút Start thành Split-action component:
  - Nút chính `AppButton { objectName: "btnBatchStart" ... }`:
    - Text: `root.controller.state === "IDLE" || ["COMPLETED", "CANCELLED", "FAILED"].indexOf(root.controller.state) >= 0 ? (root.selectedLimit === 0 ? "⚡ Dịch toàn bộ" : "⚡ Dịch " + root.selectedLimit + " câu") : "⚡ Dịch tự động"`
    - OnClicked: gọi `root.controller.startBatch(root.sourceLanguage, root.targetLanguage, root.storySummary, root.currentSubtitleIndex >= 0 ? root.currentSubtitleIndex : 0, root.selectedLimit)`
  - Nút mũi tên `AppButton { objectName: "btnBatchPreset" text: "▾" ... }`:
    - OnClicked: mở `Menu` với 3 MenuItem: `⚡ 10 câu (Thử AI)`, `⚡ 50 câu (Khuyên dùng)`, `⚡ Toàn bộ tệp`.
    - Menu được style Dark theme chuẩn `Theme.bgSurface`.

- [ ] **Step 4: Chạy regression suite cho Batch UI**

Run: `pytest tests/e2e/test_batch_ui.py -v`
Expected: 10/10 PASS.

- [ ] **Step 5: Commit thay đổi**

```bash
git add ui/qml/components/HeaderBatchControl.qml tests/e2e/test_batch_ui.py
git commit -m "feat(ui): add split-action batch start button with presets to HeaderBatchControl"
```

---

### Task 3: Frontend `SubtitleListView.qml` Dynamic Chunk Selector & O(1) Delegate Filter

**Files:**
- Modify: `ui/qml/components/SubtitleListView.qml`
- Test: `tests/e2e/test_final_regression.py`

**Interfaces:**
- Consumes: `subListView.count`, `Theme`
- Produces:
  - `property int selectedChunkStart: -1`
  - `property int selectedChunkEnd: -1`
  - `objectName: "chunkFilterCombo"`
  - Delegate `matchChunk` boolean check

- [ ] **Step 1: Viết failing test cho Chunk Filter trong `tests/e2e/test_final_regression.py`**

Thêm test case:
```python
def test_tc15_16_chunk_filter():
    harness = AppHarness(FIXTURE)
    try:
        combo = harness.driver.find("chunkFilterCombo")
        assert combo is not None
        assert combo.property("count") >= 1
    finally:
        harness.close()
```

- [ ] **Step 2: Chạy test để xác nhận test thất bại**

Run: `pytest tests/e2e/test_final_regression.py -k "chunk_filter" -v`
Expected: FAIL (không tìm thấy `chunkFilterCombo`).

- [ ] **Step 3: Cập nhật `SubtitleListView.qml`**

1. Khai báo thuộc tính phân đoạn:
   ```qml
   readonly property int chunkSize: 50
   property int selectedChunkStart: -1
   property int selectedChunkEnd: -1
   ```
2. Thêm hàm tạo model phân đoạn động:
   ```qml
   function getChunkModel() {
       var total = subListView.count;
       if (total <= 0) return ["Tất cả câu"];
       var list = ["Tất cả câu"];
       var chunks = Math.ceil(total / chunkSize);
       for (var i = 0; i < chunks; i++) {
           var start = (i * chunkSize) + 1;
           var end = Math.min((i + 1) * chunkSize, total);
           list.push("Câu " + start + " - " + end);
       }
       return list;
   }
   ```
3. Thêm `ComboBox` `chunkFilterCombo` (đặt trong thanh Header controls cạnh `filterCombo`):
   - Style Dark Mode chuẩn (popup, delegate, indicator mũi tên `▾`).
   - `model: getChunkModel()`
   - `onCurrentIndexChanged`:
     - Nếu `currentIndex <= 0`: `selectedChunkStart = -1`, `selectedChunkEnd = -1`.
     - Nếu `currentIndex > 0`: `selectedChunkStart = (currentIndex - 1) * chunkSize`, `selectedChunkEnd = Math.min(currentIndex * chunkSize - 1, subListView.count - 1)`.
     - Gọi `updateFilteredCount()`.
4. Cập nhật điều kiện hiển thị trong delegate của `subListView`:
   ```qml
   property bool matchChunk: root.selectedChunkStart < 0 || (index >= root.selectedChunkStart && index <= root.selectedChunkEnd)
   visible: matchSearch && matchFilter && matchChunk
   height: visible ? (hasTranslation ? 82 : 62) : 0
   ```

- [ ] **Step 4: Chạy test xác minh test case mới đã pass**

Run: `pytest tests/e2e/test_final_regression.py -k "chunk_filter" -v`
Expected: PASS.

- [ ] **Step 5: Commit thay đổi**

```bash
git add ui/qml/components/SubtitleListView.qml tests/e2e/test_final_regression.py
git commit -m "feat(ui): implement dynamic 50-chunk filter combobox in SubtitleListView"
```

---

### Task 4: Kết nối Binding giữa Workspace và Header & Kiểm định Toàn diện

**Files:**
- Modify: `ui/qml/Main.qml`
- Test: Toàn bộ test suite (`tests/`)

- [ ] **Step 1: Kết nối `currentSubtitleIndex` từ `SubtitleListView` lên `HeaderBatchControl` trong `Main.qml`**

Trong `Main.qml`, truyền `currentSubtitleIndex: subtitleList.currentIndex` vào `AppHeader` / `HeaderBatchControl`.

- [ ] **Step 2: Chạy kiểm tra cú pháp QML qua python dry-run**

Run:
```powershell
python -c "
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl
from PySide6.QtQuickControls2 import QQuickStyle
QQuickStyle.setStyle('Basic')
app = QGuiApplication([])
engine = QQmlApplicationEngine()
engine.load(QUrl.fromLocalFile('ui/qml/Main.qml'))
print('SUCCESS' if engine.rootObjects() else 'FAIL')
"
```
Expected: `SUCCESS`.

- [ ] **Step 3: Chạy toàn bộ 255+ bài test tự động**

Run: `pytest tests/ -v -m "not real_model"`
Expected: 100% PASSED (không có bất kỳ regression nào).

- [ ] **Step 4: Commit hoàn tất tính năng v1.3**

```bash
git add ui/qml/Main.qml
git commit -m "feat(ui): bind currentSubtitleIndex to HeaderBatchControl and finalize v1.3"
```
