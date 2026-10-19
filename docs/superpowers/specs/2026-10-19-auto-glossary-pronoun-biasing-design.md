# Tài Liệu Thiết Kế Kỹ Thuật (Design Specification)
# Tính Năng: Auto-Glossary & Pronoun Biasing Offline (v1.0)
**Mã tài liệu:** `SPEC-2026-10-19-AUTO-GLOSSARY-PRONOUN-BIASING`  
**Nhánh git:** `feat/auto-glossary-pronoun-biasing`  
**Tác giả:** Lead Solution Architect & BA  
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
* Không thay đổi kiến trúc lưu trữ tệp `.aisrt` (chỉ mở rộng schema JSON nhẹ nhàng).

### 2.3 Anti-Goals (Tuyệt đối không làm)
* **Không làm tràn prompt (No Prompt Bloat):** Giới hạn tối đa 25-30 thuật ngữ và 1 cặp đại từ chủ đạo để tránh gây hiện tượng sao nhãng (Attention Drift) ở LLM 3B/7B.
* **Không cưỡng bức đại từ sai bối cảnh:** Nếu người dùng đã tự tay ghi rõ đại từ trong Summary (ví dụ: *"xưng anh - em"*), hệ thống tự động suy luận không được cãi lời người dùng.
* **Không block UI thread:** Mọi thao tác Regex và bóc tách chạy qua Signal/Slot hoặc Worker thread an toàn.

---

## 3. Kiến Trúc Kỹ Thuật Chi Tiết (Architecture & Component Design)

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
│  └── TranslationController & ProjectController                                        │
│       ├── auto_extract_context(summary_text, source_lang, target_lang)                │
│       └── set_selected_archetype(archetype_id) / override_pronouns(pair)              │
└────────────────────────────────────────┬───────────────────────────────────────────────┘
                                         │
┌────────────────────────────────────────▼───────────────────────────────────────────────┐
│ Core Domain Engine (100% Offline)                                                      │
│  ├── ContextAnalyzer (app/core/context_analyzer.py):                                   │
│  │    ├── Entity Extractor: Quotes ("..."), CJK Brackets (「...」), Katakana, Names   │
│  │    └── Archetype Classifier: Keyword matching & pronoun mapping                     │
│  │          - Cổ trang / Tiên hiệp  ➔ Ta - Ngươi, Huynh - Đệ, Bổn tọa                 │
│  │          - Nữ sinh / Học đường   ➔ Tớ - Cậu, Mình - Bạn                             │
│  │          - Đô thị / Hành động    ➔ Tôi - Bạn, Chúng tôi                             │
│  │          - Gia đình / Thân mật   ➔ Anh - Em, Chị - Em, Bố - Con                     │
│  ├── ContextEngine (app/core/context_engine.py):                                        │
│  │    └── Nạp bản dịch của câu trước (TRANSLATED / EDITED / ACCEPTED) vào prev_ctx    │
│  └── PromptBuilder (app/core/prompt_builder.py):                                       │
│       └── Bơm chỉ thị đại từ & ép đồng bộ mạch đối thoại vào System Prompt             │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Bóc tách thực thể & Nhận diện thể loại (`app/core/context_analyzer.py`)
1. **Trích xuất tên riêng & trích dẫn:**
   * Ngoặc kép phương Tây: `"([^"]+)"`, `'([^']+)'`.
   * Ngoặc Á Đông: `「([^」]+)」`, `『([^』]+)』`, `【([^】]+)】`, `《([^》]+)》`.
   * Katakana tiếng Nhật: `[\u30A0-\u30FF]{2,}`.
   * Tên riêng tiếng Việt viết hoa: `([A-ZÀ-Ỹ][a-zà-ỹ]+(?:\s+[A-ZÀ-Ỹ][a-zà-ỹ]+)+)`.
2. **Bảng phân loại thể loại & Đại từ (Archetypes):**
   * `ARCHETYPE_ANIME_SCHOOL`: Keywords (`học sinh`, `trường`, `nữ sinh`, `ma thuật`, `lớp học`) ➔ `Tớ - Cậu`.
   * `ARCHETYPE_ANCIENT_FANTASY`: Keywords (`cổ trang`, `tiên hiệp`, `kiếm hiệp`, `hoàng đế`, `ma vương`, `dũng giả`, `tu tiên`) ➔ `Ta - Ngươi`.
   * `ARCHETYPE_MODERN_ACTION`: Keywords (`thám tử`, `cảnh sát`, `đặc vụ`, `bác sĩ`, `luật sư`, `tội phạm`) ➔ `Tôi - Anh/Chị` hoặc `Tôi - Bạn`.
   * `ARCHETYPE_ROMANCE_FAMILY`: Keywords (`tình yêu`, `hẹn hò`, `vợ chồng`, `gia đình`, `anh em`) ➔ `Anh - Em`.
   * **Bộ lọc chống va chạm ngữ cảnh (Anti-Collision Filter):** Nếu xuất hiện từ khóa công nghệ (`lập trình`, `code`, `bug`, `máy tính`), vô hiệu hóa nhận diện kiếm hiệp/tiên hiệp.

### 3.2 Nâng cấp `ContextEngine` & `PromptBuilder`
* `ContextEngine.get_context(subtitles, index)`:
  ```python
  # Thay đổi dòng 14-17 cũ:
  if status in ["ACCEPTED", "TRANSLATED", "EDITED"] and sub.get("translation"):
      prev_ctx.append(f"[Line {i+1}]: {sub.get('translation')}")
  else:
      prev_ctx.append(f"[Line {i+1}]: {sub.get('original', '')}")
  ```
* `PromptBuilder.build(...)`:
  Thêm khối chỉ đạo:
  ```text
  CONTINUITY & PRONOUN ALIGNMENT:
  - If previous subtitle dialogue used specific pronouns (e.g. 'ta - ngươi' or 'tớ - cậu'), you MUST maintain the exact same pronoun hierarchy for continuing speakers in the current subtitle.
  - Active Pronoun Pair: {active_pronoun_pair}
  ```

### 3.3 Thiết kế Giao diện UI (QML)
1. **Header Capsule trong `TranslationWorkspace.qml`:**
   * Đặt tại vị trí khoảng đệm spacer, bên trái badge `⏳ CHỜ DUYỆT`.
   * Capsule kính mờ bo tròn `14px`, nền `Qt.rgba(1, 1, 1, 0.45)`, viền `Theme.glassBorderSpecularUpper`.
   * Nhãn text: `🎭 Cổ Trang • Ta - Ngươi ▾`.
   * Click mở `Menu` Liquid Glass với danh sách các phong cách để người dùng đổi lại tức thì.
2. **Tab 2 (Intelligence & Glossary) trong `ContextInspector.qml`:**
   * Thay thế dòng text trống cũ bằng danh sách các chip kính mờ:
     * Chip xanh Sapphire: Thuật ngữ / Thực thể tự động bóc tách (`is_auto: true`).
     * Chip tím/vàng: Thuật ngữ người dùng tự tạo (`is_auto: false`).
     * Mỗi chip có nút `✕` nhỏ để xóa nhanh từ thừa.
3. **Tab 3 (Summary) trong `ContextInspector.qml`:**
   * Bổ sung `Timer { id: summaryDebounceTimer; interval: 2000; repeat: false; onTriggered: controller.analyzeSummary(text) }`.

---

## 4. Chiến Lược Kiểm Thử (Mandatory Testing Strategy)

### 4.1 Bộ Test A/B Đối Chiếu Bắt Buộc (`test_comparative_translation.py`)
Khóa cứng yêu cầu nghiệm thu của người dùng:
* **Bước 1 (Baseline Test):** Chạy dịch câu mẫu khi `story_summary = ""` và `glossary = None`. Ghi nhận prompt và kết quả dịch mặc định.
* **Bước 2 (Enriched Test):** Cung cấp `story_summary = "Phim cổ trang tu tiên, hai nhân vật đối đầu sinh tử"`. Kích hoạt bộ phân tích sau 2 giây. Kiểm tra xem:
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
* `test_rolling_context_translated_status()`: Câu trước có trạng thái `TRANSLATED` được truyền bản dịch tiếng Việt vào `prev_context`.

---

## 5. Kế Hoạch Triển Khai (Milestones)

1. **Giai đoạn 1: Core Domain Engine**  
   Viết `app/core/context_analyzer.py` + Bộ unit test `tests/test_context_analyzer.py`.
2. **Giai đoạn 2: Context & Prompt Continuity**  
   Cập nhật `ContextEngine.py` và `PromptBuilder.py` + Bộ test đối chiếu A/B `tests/test_comparative_translation.py`.
3. **Giai đoạn 3: Controller & Data Preservation**  
   Cập nhật `TranslationController.py`, `ProjectController.py` (debounce signal, lưu schema project).
4. **Giai đoạn 4: Liquid Glass UI & Visual Controls**  
   Cập nhật `ContextInspector.qml` (Tab 2 chips & Tab 3 debounce), `TranslationWorkspace.qml` (Header Pill dropdown).
5. **Giai đoạn 5: Kiểm Thử Toàn Diện & Nghiệm Thu**  
   Chạy toàn bộ test suite (`pytest`) và smoke test CLI.
