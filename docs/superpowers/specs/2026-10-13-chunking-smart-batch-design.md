# P1.3 Chunking & Smart Batch — Design Spec v1.3

- **Tác giả:** Antigravity (Ponytail & Superpowers Pair-Programming)
- **Ngày lập:** 2026-10-13
- **Trạng thái:** DRAFT / PENDING REVIEW
- **Nhánh triển khai:** `feat-chunking-smart-batch` (dựa trên `feat-ui-modernization`)

---

## 1. Mục tiêu & Bối cảnh (Objective & Context)

### 1.1. Bối cảnh
Khi biên tập và dịch các tập phim, video dài (90 phút ~ 1.200 - 1.500 câu phụ đề), người dùng đối mặt với 2 rào cản nghiêm trọng:
1. **Quá tải nhận thức (Cognitive Overload):** Danh sách hàng ngàn câu gây áp lực thị giác lớn; người dịch không có cảm giác hoàn thành từng chặng (milestone progress).
2. **Quá nhiệt phần cứng & Mất kiểm soát tiến độ (Hardware Thermal Throttling):** Chạy batch toàn bộ 1.500 câu liên tục khiến GPU/CPU duy trì công suất tối đa trong thời gian dài (30-45 phút), làm tụt xung nhịp do quá nhiệt và không cho phép người dùng kiểm tra văn phong (sanity check) trước khi dịch tiếp.

### 1.2. Mục tiêu kỹ thuật
* **Tính năng 1 (Custom Batch Limit & Anti-Context Drift):** Cho phép người dùng chạy dịch tự động theo lô có giới hạn (10 câu, 50 câu, Toàn bộ). Bắt đầu từ câu đang chọn (`currentIndex`) và tự động nạp ngữ cảnh mới nhất từ các câu vừa sửa trước đó.
* **Tính năng 2 (O(1) View Chunking Selector):** Cung cấp bộ lọc phân đoạn theo block 50 câu trên cột trái (`SubtitleListView`), lọc thuần túy trên Scene Graph của QML mà không cắt xén Python model, bảo toàn 100% tính năng Search toàn cục và Context Inspector xuyên ranh giới.

---

## 2. Phân tích & Quyết định Kiến trúc (Architectural Decisions)

| Hạng mục | Phương án loại bỏ | Phương án lựa chọn | Lý do kiến trúc (Ponytail Senior Dev) |
| :--- | :--- | :--- | :--- |
| **Tiêu chí phân đoạn** | Cách A: Chia theo thời gian (0-5p, 5-10p) | **Cách B: Chia theo số câu (1-50, 51-100)** | Mật độ thoại không tuyến tính (đoạn hành động 3 câu, đoạn hội thoại 140 câu). Chia theo số câu đảm bảo khối lượng công việc và tải nhận thức đồng đều tuyệt đối. |
| **Cơ chế phân trang** | Hard Pagination (Cắt SubtitleModel thành từng trang) | **O(1) QML View Filter** | Cắt model sẽ làm chết tính năng Search toàn cục và gây đứt đoạn Context Inspector ở ranh giới trang. View Filter giữ nguyên model, chỉ ẩn hiện delegate bằng phép so sánh số nguyên `index >= min && index <= max`. |
| **Kích thước phân đoạn** | 100 câu hoặc Tùy biến tự do | **Cố định 50 câu (Khuyên dùng)** | 50 câu tương đương 3-5 phút thoại; tối ưu cho sự tập trung của não bộ người dịch và là khoảng thời gian lý tưởng để GPU xả nhiệt. Tránh UI modal nhập số phức tạp (YAGNI). |
| **Khởi tạo Batch Limit** | Luôn chạy từ câu 1 | **Chạy từ `currentIndex` hiện tại** | Cho phép người dùng tiếp tục dịch từ vị trí họ đang duyệt, không ép phải dịch lại từ đầu. |
| **Logic nạp Batch Item** | Viết lại Batch Runner mới | **Tái sử dụng 100% `BatchJob` & `BatchItem`** | Chỉ cần lọc subset `target_indices` hợp lệ (PENDING / ERROR) đưa vào `BatchJob.create()`. `BatchTranslationService` tự động chạy hết subset và kích hoạt `COMPLETED` tự nhiên. |

---

## 3. Đặc tả Chi tiết Kỹ thuật (Technical Specification)

### 3.1. Backend (`app/controllers/batch_controller.py`)

#### Mở rộng phương thức `startBatch`:
```python
@Slot(str, str, str)
@Slot(str, str, str, int)
@Slot(str, str, str, int, int)
def startBatch(
    self,
    source_lang: str,
    target_lang: str,
    story_summary: str,
    start_index: int = 0,
    limit: int = 0,
) -> None:
    ...
```

#### Thuật toán thu thập Batch Items:
1. Xác định `start_pos = max(0, min(start_index, total_len - 1))`.
2. Duyệt từ `start_pos` đến `total_len - 1`:
   - Nếu trạng thái của câu là `PENDING` hoặc `ERROR`: thêm vào danh sách `target_indices`.
   - Nếu `limit > 0` và `len(target_indices) >= limit`: dừng duyệt.
3. Nếu `target_indices` rỗng (do `start_pos` nằm sau tất cả các câu chưa dịch): tự động tìm kiếm từ đầu file (`index = 0`) để đảm bảo trải nghiệm người dùng không bị lỗi giả.
4. Đóng gói `items = {idx: BatchItem(target_index=idx, source_hash=...) for idx in target_indices}`.
5. Gọi `self._job = BatchJob.create(self._project_id, items)` và khởi động `self._service.start(self._job)`.

#### Đảm bảo Anti-Context Drift:
`BatchTranslationService` thông qua `TranslationPipelineAdapter` luôn gọi `TranslationController.translate_target(index)` tại thời điểm xử lý từng câu. Do `TranslationController` đọc trực tiếp `contextPrev` từ `SubtitleModel`, mọi chỉnh sửa thủ công của người dùng ở câu trước đó đều được phản ánh tức thì vào prompt của câu tiếp theo.

---

### 3.2. Frontend: Cụm điều khiển Batch (`HeaderBatchControl.qml`)

1. **Thuộc tính cấu hình:**
   * `property int selectedLimit: 50` (Mặc định 50 câu).
   * `property int currentSubtitleIndex: 0` (Được bind từ `subtitleListView.currentIndex`).

2. **Split-Action Button Design:**
   * **Nút bấm chính (`btnBatchStart`):**
     * Nhãn nút: 
       - Nếu `selectedLimit === 0`: `"⚡ Dịch toàn bộ"`
       - Ngược lại: `"⚡ Dịch " + selectedLimit + " câu"`
     * Hành vi `onClicked`:
       ```qml
       root.controller.startBatch(
           root.sourceLanguage,
           root.targetLanguage,
           root.storySummary,
           root.currentSubtitleIndex >= 0 ? root.currentSubtitleIndex : 0,
           root.selectedLimit
       )
       ```
   * **Nút mở rộng Preset (`btnBatchPresetMenu`):**
     * Nút nhỏ có icon `▾`, nằm liền kề bên phải nút chính.
     * Mở menu Dark Mode gồm 3 tùy chọn:
       * `⚡ 10 câu (Thử AI)` ➔ đặt `selectedLimit = 10`
       * `⚡ 50 câu (Khuyên dùng)` ➔ đặt `selectedLimit = 50`
       * `⚡ Toàn bộ tệp` ➔ đặt `selectedLimit = 0`

3. **Hiển thị tiến độ khi chạy:**
   * Text trạng thái hiển thị rõ: `Đang dịch lô (8/50) · 16%`.
   * Khi hoàn tất 50 câu: hiển thị `Hoàn tất lô (50/50)` và dừng chạy, cho phép người dùng bấm phím duyệt hoặc tiếp tục lô sau.

---

### 3.3. Frontend: Bộ lọc Phân đoạn (`SubtitleListView.qml`)

1. **Tính toán dải phân đoạn động (Dynamic Chunking):**
   * Hằng số: `readonly property int chunkSize: 50`
   * Thuộc tính:
     ```qml
     property int selectedChunkStart: -1
     property int selectedChunkEnd: -1
     ```
   * Danh sách model của `chunkCombo`:
     - Luôn có mục đầu tiên: `"Tất cả phân đoạn"` (hoặc `"Tất cả"`).
     - Khi `subListView.count > 0`: tự động sinh các mục:
       `"Câu 1 - 50"`, `"Câu 51 - 100"`, `"Câu 101 - 150"`...

2. **Giao diện ComboBox Phân đoạn (`chunkFilterCombo`):**
   * Đặt tại thanh điều khiển header của cột trái (cạnh ô Tìm kiếm và Lọc trạng thái).
   * Tương tự `statusFilterCombo`, có style Dark Mode chuẩn mực với bo góc, popup tối màu và mũi tên `▾` / `▴`.

3. **Logic lọc trong Delegate:**
   ```qml
   property bool matchChunk: root.selectedChunkStart < 0 || (index >= root.selectedChunkStart && index <= root.selectedChunkEnd)
   visible: matchSearch && matchFilter && matchChunk
   ```
   * Độ phức tạp: `O(1)` phép so sánh số nguyên.
   * `filteredCount` tự động cập nhật số câu đang hiển thị tương ứng.

---

## 4. Kế hoạch Kiểm thử & Xác minh (Verification Plan)

### 4.1. Unit & Controller Tests (`tests/test_batch_controller.py`)
1. `test_batch_start_with_limit_50`: Khởi động batch với 100 câu PENDING và `limit=50`. Xác minh `job.totalCount == 50`.
2. `test_batch_start_from_cursor_index`: Khởi động batch từ index 30 với `limit=10`. Xác minh chỉ các câu từ 30 trở đi được nạp vào job.
3. `test_batch_skips_non_pending`: File có xen kẽ các câu `TRANSLATED` và `ACCEPTED`. Xác minh batch chỉ chọn đúng các câu `PENDING` hoặc `ERROR` mà không đếm trùng câu đã dịch.
4. `test_batch_backward_compatibility`: Gọi `startBatch(src, tgt, summary)` không tham số limit. Xác minh chạy toàn bộ như cũ.

### 4.2. E2E UI Tests (`tests/e2e/test_batch_chunking_ui.py`)
1. `test_chunk_combo_renders_and_filters`: Nạp file 75 câu. Xác minh ComboBox có 2 chunk (`1 - 50` và `51 - 75`). Chọn chunk 1 chỉ hiển thị 50 câu đầu.
2. `test_search_persists_across_chunks`: Tìm kiếm từ khóa xuất hiện ở câu 60 khi đang chọn chunk `1 - 50`. Xác minh trải nghiệm tìm kiếm.
3. `test_split_batch_runs_custom_limit`: Chọn preset `10 câu` trên Header, bấm chạy và xác minh batch dừng chính xác ở câu thứ 10.

---

## 5. Tiêu chuẩn Hoàn thành (Definition of Done)
- [ ] Backend `BatchController` hỗ trợ `start_index` và `limit` với overload slot tương thích ngược 100%.
- [ ] Giao diện `HeaderBatchControl` có Split Button và menu chọn preset `10 / 50 / Toàn bộ`.
- [ ] Giao diện `SubtitleListView` có `chunkFilterCombo` chia lô 50 câu mượt mà O(1).
- [ ] Toàn bộ 255+ test cũ tiếp tục vượt qua (Zero regression).
- [ ] Các test case mới cho Chunking & Batch Limit đạt độ phủ 100%.
