# Tài Liệu Thiết Kế Kỹ Thuật (Design Specification) - Đã Qua Thẩm Định
# Tính Năng: Auto-Glossary & Pronoun Biasing Offline (v1.0)
**Mã tài liệu:** `SPEC-2026-10-19-AUTO-GLOSSARY-PRONOUN-BIASING`  
**Nhánh git:** `feat/auto-glossary-pronoun-biasing`  
**Tác giả:** Lead Solution Architect & BA  
**Reviewer:** Sub-agent `Design Spec Reviewer` (Approved with Resolved Edge Cases)  
**Ngày lập:** 19/10/2026  

---

## 1. Bối Cảnh & Mục Tiêu Nghiệp Vụ (Intent & Why)

### 1.1 Vấn đề thực tế (Pain Points)
1. **Loạn vai vế xưng hô (Pronoun Inconsistency):** Khi dịch phụ đề từ tiếng Anh/Nhật/Hàn sang tiếng Việt, mô hình AI cục bộ (Qwen 2.5 3B/7B) thường dịch đại từ theo nghĩa đen vô hồn (*"tôi - bạn"*, *"anh ấy - cô ấy"*), hoặc câu trước xưng *"ta - ngươi"*, câu sau tự ý nhảy sang *"tôi - bạn"*, làm đứt gãy hoàn toàn trải nghiệm xem phim.
2. **Nhận diện sai tên riêng & thuật ngữ:** Tên nhân vật, danh từ riêng hoặc từ mượn Katakana thường bị AI dịch sang nghĩa tiếng Việt ngô nghê hoặc viết sai chính tả.
3. **Rào cản thiết lập thủ công:** Người dùng ngại phải tự tạo bảng Glossary từng từ một. Trong khi đó, họ thường đã nhập một đoạn tóm tắt nội dung ngắn (Story Summary) trong ứng dụng nhưng dữ liệu này chưa được khai thác tối đa.

### 1.2 Giải pháp cốt lõi
Xây dựng module **Auto-Glossary & Pronoun Biasing Offline**:
* Tự động quét nội dung Story Summary sau **2 giây dừng gõ (Debounce 2000ms)**.
* **100% Offline (Zero-dependency):** Trích xuất danh từ riêng, từ trong ngoặc, từ mượn Katakana và phân loại thể loại phim (Cổ trang/Tiên hiệp, Học đường, Đô thị/Hành động...) để suy ra cặp đại từ xưng hô tương ứng.
* Đổ các thuật ngữ vào **Tab 2 (Intelligence & Glossary)** trên `ContextInspector.qml`.
* Hiển thị viên thuốc trực quan **`[ 🎭 Cổ Trang • Ta - Ngươi ▾ ]`** ngay trên thanh tiêu đề `TranslationWorkspace.qml` cho phép người dùng kiểm tra và đổi nhanh bằng 1-click.
* Mở rộng `ContextEngine` và `PromptBuilder` để đồng bộ ngữ cảnh các câu thoại liền kề (**Rolling Dialogue Continuity**), đảm bảo AI bám sát cặp xưng hô của câu thoại trước đó.

---

## 2. Mục Tiêu, Phi Mục Tiêu & Chống Mục Tiêu (Goals, Non-Goals, Anti-Goals)

### 2.1 Goals (Mục tiêu bắt buộc)
* **Offline 100%:** Hoạt động hoàn toàn trên máy cục bộ, không gọi API ngoài, xử lý dưới 20ms bằng Regex + Rule-based Engine.
* **Debounce 2000ms:** Chỉ kích hoạt phân tích khi người dùng dừng gõ 2 giây, không giật lag giao diện gõ chữ.
* **Bảo vệ dữ liệu người dùng:** Phân tách `is_auto: True` và `is_auto: False`. Không bao giờ xóa hay ghi đè thuật ngữ do người dùng nhập tay.
* **Đồng bộ thoại liền kề (Rolling Subtitle Continuity):** Truyền cả bản dịch tiếng Việt của các câu vừa dịch (`TRANSLATED`, `EDITED`, `ACCEPTED`) vào `prev_context` để AI giữ đúng cặp đại từ vừa nói.
* **Chiến lược kiểm thử A/B bắt buộc (Comparative Testing):** Có bài test tự động đối chiếu Trước khi có Summary/Glossary vs Sau khi có Summary/Glossary. Nếu không có sự thay đổi rõ rệt trong kết quả prompt/dịch, bài test **bắt buộc phải FAIL**.

### 2.2 Non-Goals (Không thuộc phạm vi)
* Không tích hợp các thư viện NLP nặng hàng trăm MB (như spaCy, HuggingFace Transformers, Stanza).
* Không thay đổi cấu trúc cơ bản của tệp `.aisrt` (chỉ mở rộng trường metadata).

### 2.3 Anti-Goals (Tuyệt đối không làm)
* **Không làm tràn prompt (No Prompt Bloat):** Giới hạn tối đa 25-30 thuật ngữ và 1 cặp đại từ chủ đạo để tránh gây hiện tượng sao nhãng (Attention Drift) ở LLM 3B/7B.
* **Không cưỡng bức đại từ sai bối cảnh:** Nếu người dùng đã tự tay ghi rõ đại từ trong Summary (ví dụ: *"xưng anh - em"*), hệ thống tự động suy luận không được cãi lời người dùng.
* **Không block UI thread:** Mọi thao tác Regex và bóc tách chạy qua Signal/Slot an toàn.

---

## 3. Kiến Trúc Kỹ Thuật Chi Tiết & Giải Quyết Toàn Bộ Điểm Biên

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ UI Layer (QML)                                                                         │
│  ├── ContextInspector.qml: summaryInput (Debounce 2000ms) ➔ onSummaryDebounced         │
│  │    └── Tab 2: Hiển thị Flow tags kính mờ (Liquid Glass Chips: Auto vs Manual)      │
│  └── TranslationWorkspace.qml: Header Capsule [ 🎭 Cổ Trang • Ta - Ngươi ▾ ] (Dropdown)│
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │ Qt Signals / Slots
┌────────────────────────────────────────▼───────────────────────────────────────────────┐
│ Controller Layer (Python)                                                              │
│  ├── ProjectController (Single Source of Truth for Archetype & Persistence):          │
│  │    ├── active_archetype: str, active_pronoun_pair: str, is_archetype_locked: bool   │
│  │    ├── dismissed_auto_terms: set[str] (Chống phục sinh chip đã bị bấm xóa)         │
│  │    └── Lưu/Đọc trường metadata.archetype vào file dự án .aisrt                     │
│  └── TranslationController: Nhận active_pronoun_pair truyền vào PromptBuilder          │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │
┌────────────────────────────────────────▼───────────────────────────────────────────────┐
│ Core Domain Engine (100% Offline)                                                      │
│  ├── ContextAnalyzer (app/core/context_analyzer.py):                                   │
│  │    ├── Entity Extractor:                                                           │
│  │    │   - Cặp thuật ngữ có định dạng 'Source: Target' hoặc 'Source -> Target'         │
│  │    │   - Ngoặc kép phương Tây "...", ngoặc Á Đông 「...」, 『...』, Katakana         │
│  │    │   - Danh từ riêng / Tên nhân vật tiếng Việt ➔ Đưa vào Canonical Names         │
│  │    └── Archetype Classifier:                                                       │
│  │        - Cổ trang / Tiên hiệp  ➔ Ta - Ngươi                                        │
│  │        - Nữ sinh / Học đường   ➔ Tớ - Cậu                                          │
│  │        - Đô thị / Hành động    ➔ Tôi - Bạn (Default)                               │
│  │        - Gia đình / Thân mật   ➔ Anh - Em                                          │
│  │        - Mặc định / Tự do      ➔ Theo văn cảnh thoại                              │
│  ├── ContextEngine (app/core/context_engine.py):                                        │
│  │    └── Nạp bản dịch tiếng Việt của câu trước (TRANSLATED / EDITED / ACCEPTED)       │
│  │        vào prev_ctx mà KHÔNG chèn tiền tố [Line X] để chống LLM nhại format        │
│  └── PromptBuilder (app/core/prompt_builder.py):                                       │
│       └── Chỉ áp dụng luật xưng hô khi target_lang == "Vietnamese"                     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Quy Tắc Khớp Thuật Ngữ & Khóa Thực Thể (Rank 1 Resolution)
1. **Thuật ngữ có cặp nguồn - đích:**
   * Nếu trong Summary người dùng viết: `Naruto: Na Ruto` hoặc `"Tanaka" -> "Anh Tanaka"`, hệ thống tự tách: `source_term = "Naruto"`, `preferred_translation = "Na Ruto"` ➔ nạp vào `Glossary`.
2. **Từ đơn trong ngoặc & Từ Katakana:**
   * Ví dụ: `"Cyberpunk"`, `「ナルト」`. Hệ thống coi đây là thuật ngữ/tên riêng cần bảo toàn nguyên dạng: `preferred_translation = source_term` ➔ nạp vào `Glossary` hoặc `EntityDictionary`.
3. **Tên riêng tiếng Việt (VD: *Tiêu Viêm, Dược Lão, Thanh Vân Tông*):**
   * Được đưa vào mục chỉ dẫn tên nhân vật chuẩn trong prompt:
     `CANONICAL CHARACTER NAMES: When referring to main characters, preserve names: Tiêu Viêm, Dược Lão.`

### 3.2 Thứ Bậc Ưu Tiên & Chống Tái Sinh Thuật Ngữ (Rank 4 Resolution)
1. **Thứ bậc ưu tiên thể loại & đại từ:**
   * **Mức 1 (Tối thượng):** Người dùng chọn thủ công trên Header Capsule (`is_archetype_locked = True`). Khi đã chọn thủ công, việc gõ Summary sẽ KHÔNG bao giờ tự ý đổi thể loại nữa. (Chỉ đổi lại khi chọn menu "Tự động nhận diện").
   * **Mức 2:** Chỉ thị trực tiếp trong Summary (VD người dùng viết: *"xưng anh - em"*).
   * **Mức 3:** AI Regex phân loại tự động.
   * **Mức 4 (Fallback mặc định):** `ARCHETYPE_CUSTOM` / `Tự do (Theo ngữ cảnh thoại)`.
2. **Chống tái sinh chip đã xóa (Anti-Resurrection):**
   * Quản lý tập `dismissed_auto_terms = set()`. Khi người dùng click `✕` trên một chip tự động, từ đó được ghi vào tập này. Các vòng debounce 2000ms sau đó sẽ bỏ qua từ này.

### 3.3 Chống Nhại Định Dạng Trong `ContextEngine` (Rank 5 Resolution)
* Không dùng định dạng `[Line {i+1}]: ...` vì LLM 3B dễ nhại lại tiền tố này vào câu dịch.
* Thay vào đó, dùng cấu trúc hội thoại tự nhiên:
  ```text
  --- PREVIOUS DIALOGUE (FOR PRONOUN & FLOW CONTINUITY) ---
  Ngươi muốn gì ở ta?
  ```
* Bổ sung bộ lọc regex an toàn tại `TranslationController.on_finished` để tự động gọt sạch mọi tiền tố `[Line \d+]:` nếu chẳng may LLM sinh ra.

### 3.4 Phân Vùng Ngôn Ngữ (Rank 6 Resolution)
* Toàn bộ khối `PRONOUN BIASING & CONTINUITY` được đặt bên trong khối điều kiện:
  `if target_lang.lower() == "vietnamese":`
  đảm bảo không gây nhiễu cho các cặp ngôn ngữ khác.

---

## 4. Chiến Lược Kiểm Thử (Mandatory Testing Strategy)

### 4.1 Bộ Test A/B Đối Chiếu Bắt Buộc (`tests/test_comparative_translation.py`)
Khóa cứng yêu cầu nghiệm thu của người dùng (Chạy deterministic qua mock/prompt builder trong < 100ms, không phụ thuộc vào tải model GGUF nặng):
* **Bước 1 (Baseline Test):** Chạy sinh prompt khi `story_summary = ""` và `glossary = None`.
* **Bước 2 (Enriched Test):** Cung cấp `story_summary = "Phim cổ trang tu tiên, hai nhân vật đối đầu sinh tử"`. Kích hoạt bộ phân tích:
  * Thể loại `ARCHETYPE_ANCIENT_FANTASY` được nhận diện.
  * Cặp đại từ `Ta - Ngươi` được gán.
  * Prompt sinh ra chứa luật `Ta - Ngươi` và các câu thoại tiếng Việt câu trước.
* **Bước 3 (Assertion & Fail-Condition):**
  * `assert enriched_prompt != baseline_prompt`
  * `assert "Ta - Ngươi" in enriched_prompt or "ta" in enriched_prompt.lower()`
  * **Quy tắc nghiêm ngặt:** Nếu `enriched_prompt == baseline_prompt` hoặc không có sự thay đổi về đại từ ➔ Test **FAIL ngay lập tức** và yêu cầu Dev làm lại.

### 4.2 Bộ Test Đơn Vị & Tích Hợp (Unit & Integration Tests)
* `test_context_analyzer_quotes()`: Kiểm tra trích xuất chính xác ngoặc kép Tây và ngoặc Á Đông.
* `test_context_analyzer_katakana()`: Bóc tách chính xác từ mượn tiếng Nhật.
* `test_context_analyzer_anti_collision()`: Video công nghệ có từ "chiến đấu với bug" không bị nhận diện nhầm thành kiếm hiệp.
* `test_preserve_manual_glossary()`: Sửa summary không làm mất từ người dùng nhập tay.
* `test_dismissed_auto_terms_no_resurrect()`: Bấm xóa chip tự động không bị debounce hồi sinh.
* `test_rolling_context_translated_status()`: Câu trước có trạng thái `TRANSLATED` được truyền bản dịch tiếng Việt vào `prev_context`.

---

## 5. Kế Hoạch Triển Khai (Milestones)

1. **Giai đoạn 1: Core Domain Engine (`app/core/context_analyzer.py`)**  
   Triển khai bộ phân tích Regex offline siêu nhẹ + Bộ unit test `tests/test_context_analyzer.py`.
2. **Giai đoạn 2: Context & Prompt Continuity (`ContextEngine.py` & `PromptBuilder.py`)**  
   Cập nhật truyền ngữ cảnh câu trước đã dịch + Bộ test đối chiếu A/B `tests/test_comparative_translation.py`.
3. **Giai đoạn 3: Controller & Persistence (`ProjectController.py` & `TranslationController.py`)**  
   Quản lý state archetype, lưu vào `.aisrt`, debounce 2000ms, cơ chế chống hồi sinh chip bị xóa.
4. **Giai đoạn 4: Liquid Glass UI (`TranslationWorkspace.qml` & `ContextInspector.qml`)**  
   Header Capsule chọn thể loại kèm dropdown menu; Danh sách chip kính mờ trong Tab 2 Glossary; Debounce timer ở Tab 3 Summary.
5. **Giai đoạn 5: Kiểm Thử Toàn Diện & Nghiệm Thu**  
   Chạy toàn bộ test suite (`pytest`) và smoke test CLI.
