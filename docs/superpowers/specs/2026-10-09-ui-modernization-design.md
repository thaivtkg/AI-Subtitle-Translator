# Feature 1.2: UI/UX Modernization — Design Spec v1

**Status:** Approved
**Date:** 2026-10-09
**Scope:** Giao diện người dùng hiện đại, tối ưu không gian hiển thị, hỗ trợ kéo thả và bản địa hóa 100% tiếng Việt
**Target:** Phase 1.2 (UI/UX Refinement)

---

## 1. Intent and Success Criteria

Nâng cấp toàn diện trải nghiệm người dùng (UX) và giao diện trực quan (UI) của ứng dụng **AI Subtitle Translator** theo các tiêu chuẩn phần mềm máy tính hiện đại:
- **Tối ưu không gian làm việc:** Thu hồi 48px chiều dọc từ thanh điều khiển dịch hàng loạt cũ (`BatchControlBar`), tích hợp gọn vào thanh tiêu đề (`AppHeader`).
- **Thao tác nhanh chóng (Drag-and-Drop):** Cho phép người dùng kéo thả trực tiếp tệp `.srt` và `.aisrt` vào vùng làm việc trống để bắt đầu dịch mà không cần mở hộp thoại duyệt file.
- **Bản địa hóa 100% Tiếng Việt:** Xóa bỏ hoàn toàn tình trạng pha trộn Anh - Việt trên các thành phần giao diện chính.
- **Tối ưu hóa trạng thái trống (Context Inspector Collapse):** Giảm tải thị giác khi chưa chọn câu phụ đề, hiển thị chỉ dẫn tập trung thay vì các khung nội dung trống lặp lại.
- **Cải thiện độ tương phản:** Tăng khả năng nhận diện hình khối và trạng thái vô hiệu hóa (disabled) của các nút bấm trên nền tối.

### Success Criteria:
- Mọi định danh kiểm thử `objectName` phục vụ E2E (`btnBatchStart`, `btnBatchPause`, `btnBatchResume`, `btnBatchCancel`, `btnBatchRetryFailed`, `batchControlBar`, `batchStatusText`, `batchProgressText`, `btnOpenSrt`, `btnOpenProject`, `btnSave`, `btnExport`, `btnTranslate`, `btnAccept`, `btnRetry`, `searchInput`, `statusFilterCombo`, `storySummaryInput`, `statusProgressText`) được bảo toàn tuyệt đối.
- Toàn bộ bộ kiểm thử hồi quy (255+ tests) vượt qua (GREEN) mà không phát sinh bất kỳ lỗi tương thích nào.
- 0 phụ thuộc thư viện bên ngoài (Zero external dependencies) theo triết lý Ponytail.

---

## 2. Chi tiết 5 can thiệp thiết kế (Design Interventions)

### 2.1 Can thiệp 1: Vùng Kéo - Thả Tệp Tin (`EmptyWorkspace.qml`)
- **Cơ chế:** Tích hợp thành phần native `DropArea` trong `EmptyWorkspace.qml` khi ở chế độ `no_project`.
- **Bộ lọc định dạng (Format Guard):**
  - Sự kiện `onEntered(drag)` kiểm tra `drag.urls`. Chỉ chấp nhận các file có phần mở rộng `.srt` hoặc `.aisrt` (không phân biệt chữ hoa/thường).
  - Từ chối kéo thả (`drag.accepted = false`) nếu file không đúng định dạng.
- **Bảo vệ đường dẫn Windows:**
  - Chuỗi URL dạng `file:///C:/...` được xử lý an toàn qua `projectController.importSrt` và `projectController.loadProject`.
- **Hiệu ứng thị giác:**
  - Khi `containsDrag === true`, khung viền chuyển sang màu `Theme.accentCyan` (nét đứt/đậm 2px), nền phủ sáng nhẹ `Qt.rgba(cyan, 0.08)`.
  - Icon chuyển sang `📥` biểu thị trạng thái sẵn sàng tiếp nhận tệp tin.

### 2.2 Can thiệp 2: Thu hồi không gian dọc — Header Batch Control (`AppHeader.qml` & `HeaderBatchControl.qml`)
- **Tái cấu trúc bố cục:**
  - Loại bỏ hàng `BatchControlBar` độc lập (cao 48px) khỏi `Main.qml`.
  - Tạo component `HeaderBatchControl.qml` (giữ `objectName: "batchControlBar"`) và nhúng trực tiếp vào thanh tiêu đề `AppHeader.qml`.
- **Hành vi linh hoạt theo trạng thái:**
  - **Trạng thái IDLE / Chưa chạy:** Chỉ hiển thị nút bấm `[Dịch tự động]` (`btnBatchStart`) cạnh các nút thao tác file. Không chiếm diện tích hiển thị tiến trình.
  - **Trạng thái RUNNING / PAUSED / FAILED:** Hiển thị nhãn trạng thái (`batchStatusText`), thông số tiến độ (`batchProgressText`) và các nút điều khiển (`btnBatchPause`, `btnBatchResume`, `btnBatchCancel`, `btnBatchRetryFailed`).
- **Độ tương thích E2E:**
  - Giữ nguyên toàn bộ `objectName` của các button và text bên trong để bộ test E2E `test_batch_ui.py` tìm thấy và tương tác chính xác.

### 2.3 Can thiệp 3: Bản địa hóa 100% Tiếng Việt (Vietnamese Localization)
Chuyển đổi toàn diện các chuỗi hiển thị sang tiếng Việt chuẩn dịch thuật:
1. **Header & Actions:**
   - `Open SRT` → `Mở SRT`
   - `Open Project` → `Mở dự án`
   - `Save` → `Lưu`
   - `Export SRT` → `Xuất SRT`
   - `✓ Saved` → `✓ Đã lưu` / `● Unsaved` → `● Chưa lưu`
2. **Subtitle List Navigator:**
   - `SUBTITLES` → `DANH SÁCH CÂU`
   - `items` → `câu`
   - `Search text...` → `Tìm kiếm nội dung...`
   - `All statuses` → `Tất cả trạng thái`
3. **Workspace Editor:**
   - `ORIGINAL` → `CÂU GỐC`
   - `VIETNAMESE` → `BẢN DỊCH TIẾNG VIỆT`
   - `Status:` → `Trạng thái:`
   - `Translate` → `Dịch câu` / `◌ Translating...` → `◌ Đang dịch...`
   - `Retry` → `Thử lại`
   - `Accept` → `Chấp nhận`
   - `Translation failed...` → `Dịch thất bại. Lỗi xử lý mô hình AI.`
4. **Context Inspector:**
   - `STORY SUMMARY` → `BỐI CẢNH & QUY TẮC`
   - `PREVIOUS` → `CÂU TRƯỚC`
   - `◆ CURRENT` → `◆ CÂU HIỆN TẠI`
   - `NEXT` → `CÂU KẾ TIẾP`
5. **Batch Controller:**
   - `Start Batch` → `Dịch tự động`
   - `Pause` → `Tạm dừng`
   - `Resume` → `Tiếp tục`
   - `Cancel` / `Cancelling…` → `Hủy` / `Đang hủy…`
   - `Retry Failed` → `Thử lại lỗi`
   - Status: `Batch running` → `Đang dịch hàng loạt…`, `Paused` → `Đã tạm dừng`, `Cancelled` → `Đã hủy`, `Failed` → `Thất bại`, `Complete` → `Hoàn tất`.

### 2.4 Can thiệp 4: Tối ưu trạng thái rỗng Inspector (`ContextInspector.qml`)
- Khi người dùng chưa chọn câu phụ đề (`!translationController.currentOriginal` hoặc `currentIndex < 0`):
  - Phần `BỐI CẢNH & QUY TẮC` (Story Summary) vẫn duy trì hiển thị để cho phép nhập/chỉnh sửa quy tắc dịch thuật bất kỳ lúc nào.
  - Ba khung câu Trước / Hiện tại / Kế tiếp được ẩn đi và thay thế bằng một thẻ chỉ dẫn duy nhất:
    *"Ngữ cảnh trước/sau sẽ hiển thị khi bạn chọn một câu phụ đề"* với độ mờ nhẹ (opacity `0.45`), loại bỏ cảm giác rối mắt với 3 hộp đen trống rỗng.

### 2.5 Can thiệp 5: Tăng cường độ tương phản nút bấm vô hiệu hóa (`AppButton.qml` & `Theme.qml`)
- Giữ đường viền `Theme.border` (1px) ngay cả khi nút ở trạng thái `disabled` (thay vì làm trong suốt hoàn toàn).
- Điều chỉnh nền `Theme.bgSurfaceSoft` và màu chữ `Theme.textDisabled` để nút bấm có hình khối rõ nét, phân biệt rõ giữa vùng có thể bấm và vùng bị khóa mà không làm chìm vào màu nền ứng dụng.

---

## 3. Bản đồ tệp tin & Kế hoạch kiểm thử

| Tệp tin | Thay đổi |
|---|---|
| `ui/qml/theme/Theme.qml` | Bổ sung/tinh chỉnh token màu đường viền và tương phản disabled |
| `ui/qml/components/AppButton.qml` | Cập nhật style viền và độ tương phản disabled |
| `ui/qml/components/EmptyWorkspace.qml` | Tích hợp `DropArea`, hiệu ứng kéo thả, tiếng Việt |
| `ui/qml/components/HeaderBatchControl.qml` | Component mới tinh gọn nhúng vào Header, giữ trọn bộ `objectName` |
| `ui/qml/components/AppHeader.qml` | Tích hợp `HeaderBatchControl`, Việt hóa nhãn nút và badge |
| `ui/qml/Main.qml` | Gỡ bỏ thanh `BatchControlBar` độc lập, nối tín hiệu từ Header |
| `ui/qml/components/SubtitleListView.qml` | Việt hóa tiêu đề, placeholder, nhãn lọc |
| `ui/qml/components/TranslationWorkspace.qml` | Việt hóa nhãn vùng dịch, trạng thái, nút thao tác |
| `ui/qml/components/ContextInspector.qml` | Việt hóa tiêu đề, hiển thị placeholder card khi chưa chọn câu |
| `ui/qml/components/AppStatusBar.qml` | Việt hóa trạng thái tiến độ |
| `tests/e2e/test_batch_ui.py` | Cập nhật assertion hỗ trợ text trạng thái tiếng Việt |
| `tests/e2e/test_final_regression.py` | Cập nhật assertion trạng thái tiến độ tiếng Việt |
