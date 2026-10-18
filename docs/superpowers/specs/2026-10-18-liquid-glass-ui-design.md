# Bản Đặc Tả Thiết Kế: Giao Diện Liquid Glass & Đảo Nổi (Floating Islands)

- **Ngày lập:** 18/10/2026
- **Trạng thái:** Chờ phê duyệt (Awaiting Human Approval)
- **Chủ đề:** Tái thiết kế toàn diện giao diện bo góc & kính mờ lỏng (Liquid Glass) cho AI Subtitle Translator

---

## 1. Mục Đích & Bối Cảnh

Nâng cấp giao diện của **AI Subtitle Translator** từ phong cách khối hộp phẳng tối màu truyền thống sang ngôn ngữ thiết kế **Ultra-Liquid Crystal** hiện đại, lấy cảm hứng từ visionOS và macOS mới nhất.

Thiết kế mới mang lại:
- Cửa sổ ứng dụng nhìn xuyên thấu ra màn hình desktop với độ trong suốt vừa phải (~45%–50% opacity).
- Ba khu vực làm việc chính tách biệt thành **3 Đảo Kính Nổi (Floating Glass Islands)** độc lập với góc bo tròn lớn (24px–26px).
- Viền phản chiếu ánh sáng specular 1px (viền sáng bóng như mép kính mài).
- Tông màu xanh dương Sapphire (`#0066FF` / `#0284c7`) cùng các nút bấm điều khiển dạng viên thuốc (Pill-shaped buttons) chuẩn theo mẫu tham khảo.
- Đảm bảo 100% không làm giảm tính dễ đọc của văn bản, giữ nguyên toàn bộ phím tắt và logic xử lý phụ đề.

---

## 2. Mục Tiêu, Phạm Vi & Giới Hạn

### Mục tiêu chính
1. **Xuyên thấu Desktop:** Cửa sổ không viền (frameless) với nền trong suốt (`color: "transparent"` trong QML và `Qt.FramelessWindowHint | Qt.Window`), hiển thị nền desktop mờ ảo phía sau.
2. **Cấu trúc Đảo Nổi:** Tách 3 cột thành 3 khối card kính nổi với khe hở 12px để lộ nền desktop giữa các khối.
3. **Hiệu ứng Kính Mờ Lỏng (Liquid Glass):**
   - Bán kính bo góc 24px–26px cho các đảo chính; bo tròn hoàn toàn (`height / 2`) cho nút bấm và chip trạng thái.
   - Viền highlight phản chiếu ánh sáng trắng (`rgba(255, 255, 255, 0.45)`) và đổ bóng nhẹ (soft drop shadow).
   - Nút lựa chọn active phát sáng sắc xanh Sapphire nổi bật.
4. **Cụm điều khiển cửa sổ kiểu macOS:** Ba nút tròn màu sắc (Đỏ: Đóng, Vàng: Thu nhỏ, Xanh: Phóng to) đặt ở góc trái trên của thanh tiêu đề.
5. **Bảo đảm độ tương phản văn bản:** Khu vực chứa câu gốc và câu dịch luôn có độ cản quang thực tế > 75% cùng hiệu ứng đổ bóng chữ nhẹ, giúp phụ đề luôn đọc rõ trên mọi loại hình nền.
6. **Bảo toàn chức năng & Kiểm thử:** Toàn bộ 268+ automated tests hiện có phải tiếp tục vượt qua (pass), không làm hỏng bộ định danh `objectName`.

### Không thuộc phạm vi (Non-Goals)
- Không can thiệp vào tầng backend Python (bộ phân tích SRT, engine LLM, tiến trình dịch hàng loạt).
- Không bổ sung thư viện C++ ngoài hay các can thiệp phức tạp vào nhân Windows để tránh rủi ro crash.

### Điều tối kỵ (Anti-Goals)
- Không làm trong suốt quá mức gây mờ/khó đọc chữ phụ đề.
- Không lạm dụng nhiều lớp shader blur nặng làm nóng máy hay tụt FPS khi cuộn danh sách phụ đề dài.

---

## 3. Hệ Thống Màu & Biến Theme (`Theme.qml`)

```qml
// Bộ thông số màu kính lỏng siêu bóng (Ultra-Gloss Liquid Glass)
readonly property color glassBackground: Qt.rgba(0.06, 0.10, 0.18, 0.50)   // Lớp nền kính khói xuyên thấu
readonly property color glassIslandSurface: Qt.rgba(0.12, 0.18, 0.28, 0.45) // Bề mặt đảo kính nổi xuyên thấu
readonly property color glassIslandActive: Qt.rgba(0.0, 0.40, 1.0, 0.35)    // Vùng chọn nổi bật
readonly property color glassPodLuminous: Qt.rgba(1.0, 1.0, 1.0, 0.70)     // Hộp thẻ kính mờ trắng sáng
readonly property color glassPodRaised: Qt.rgba(1.0, 1.0, 1.0, 0.80)       // Hộp nổi bật câu dịch
readonly property color glassBorderSpecularUpper: Qt.rgba(1.0, 1.0, 1.0, 0.95) // Viền bóng mép kính trên (Double Specular Rim)
readonly property color glassBorderSpecularLower: Qt.rgba(1.0, 1.0, 1.0, 0.45) // Viền mép dưới
readonly property color glassBorderSubtle: Qt.rgba(1.0, 1.0, 1.0, 0.25)     // Viền mờ phụ
readonly property color glassBevelInner: Qt.rgba(0.0, 0.0, 0.0, 0.15)       // Đổ bóng lồi mép kính 3D
readonly property color glassGleamWhite: Qt.rgba(1.0, 1.0, 1.0, 0.25)       // Vệt sáng lóa bề mặt (Specular Gleam)

// Tông màu chủ đạo xanh Sapphire (theo ảnh mẫu)
readonly property color accentSapphire: "#0066FF"
readonly property color accentSapphireHover: "#1A75FF"
readonly property color accentSapphireGradientEnd: "#0284c7"
readonly property color textPrimaryGlass: "#FFFFFF"
readonly property color textSecondaryGlass: "#94A3B8"
readonly property color textMutedGlass: "#64748B"

// Typography trên nền kính sáng (Đảm bảo độ tương phản tuyệt đối)
readonly property color textOnLightPod: "#0F172A"       // Đen tuyền Obsidian cho câu gốc và câu dịch
readonly property color textOnLightPodMuted: "#334155"  // Đen Slate cho thông số phụ

// Bảng màu trạng thái & huy hiệu phong phú (Vibrant Badges & Accents)
readonly property color badgeEmeraldBg: "#DCFCE7"
readonly property color badgeEmeraldText: "#15803D"
readonly property color badgeAmberBg: "#FEF3C7"
readonly property color badgeAmberText: "#B45309"
readonly property color badgePurpleGradientStart: "#8B5CF6"
readonly property color badgePurpleGradientEnd: "#EC4899"
readonly property color accentOrangeKeyword: "#EA580C"

// Thông số kích thước & bo góc
readonly property int radiusIsland: 26
readonly property int radiusPill: 22
readonly property int islandSpacing: 12
readonly property int windowPadding: 16
```

---

## 4. Kiến Trúc Bố Cục Chi Tiết

### 4.1 Khung Cửa Sổ Ứng Dụng (`Main.qml`)
- Bật `QQuickWindow.setDefaultAlphaBuffer(True)` trong `main.py` để DirectX/OpenGL trên Windows kích hoạt kênh trong suốt.
- Nền cửa sổ `color: "transparent"`, lớp container chính bo góc 26px với viền phản chiếu ánh sáng.
- Giữ nguyên `FramelessResizeOverlay.qml` để người dùng rê chuột vào 4 cạnh/góc cửa sổ để co giãn kích thước bình thường.

### 4.2 Thanh Tiêu Đề Đảo Kính (`AppHeader.qml`)
- Thanh đảo nổi trên cùng (bo góc 18px).
- **Góc trái:** Ba nút tròn kiểu macOS (Đóng, Thu nhỏ, Phóng to) thay thế cụm nút Windows cũ.
- **Ở giữa:** Logo Studio cùng nhãn ngôn ngữ thông tin (`English → Vietnamese`).
- **Góc phải:** Cụm nút thao tác dạng viên thuốc gồm nạp file ("Mở SRT", "Mở dự án"), cụm dịch tự động (`HeaderBatchControl` màu xanh Sapphire), "Lưu", "Xuất SRT" và "Quản lý Model", hỗ trợ tự động co gọn nhãn trên màn hình nhỏ.

### 4.3 Ba Khối Đảo Kính Nổi Trung Tâm
- Ba cột được giữ bên trong `SplitView` với `SplitView.handle: Item { implicitWidth: 12 }` (khe trong suốt 12px). Điều này tạo hiệu ứng 3 đảo nổi tách biệt hoàn toàn nhưng người dùng vẫn kéo chuột co giãn chiều rộng từng cột được.
- **Đảo 1 — Danh sách phụ đề (`SubtitleListView.qml`):**
  - Thẻ đảo kính nổi (bo góc 26px).
  - Ô tìm kiếm và lọc dạng viên thuốc với chữ đen `#0F172A` trên nền kính mờ trắng sáng.
  - Các dòng phụ đề: Dòng đang chọn dùng gradient Sapphire `#0066FF` với huy hiệu vàng `⭐ ĐANG XEM`. Các dòng khác dùng nền kính mờ trắng với chữ đen `#0F172A`, mã thời gian màu xanh cyan `#0284C7`, và chip trạng thái màu sắc (`✓ ĐÃ DỊCH` màu xanh lá, `⏳ CHỜ DUYỆT` màu hổ phách).
- **Đảo 2 — Không gian dịch thuật (`TranslationWorkspace.qml`):**
  - Thẻ đảo kính nổi trung tâm (bo góc 26px).
  - Giữ nguyên dropdown chọn ngôn ngữ tương tác (`sourceLangCombo`) để tương thích 100% với test tự động.
  - Hộp câu gốc: Nền kính mờ trắng sáng lỏng (`rgba(255,255,255,0.75)`), huy hiệu `🌐 CÂU GỐC` xanh Sapphire rực rỡ, chữ đen tuyền Obsidian `#0F172A` đậm (font-weight 800) siêu nét.
  - Hộp câu dịch: Nền kính sáng lỏng đa tầng (`rgba(255,255,255,0.82)`), huy hiệu `✨ BẢN DỊCH AI` gradient tím-xanh kèm chip độ tin cậy `⚡ 98%` xanh lá, văn bản dịch màu đen Obsidian `#0F172A` với từ khóa nổi bật sắc nét.
  - Nút bấm dưới cùng: Nút "Dịch lại" viền kính mờ và nút "Duyệt / Accept" màu xanh Sapphire nổi bật.
- **Đảo 3 — Bảng Ngữ Cảnh & QA (`ContextInspector.qml`):**
  - Thẻ đảo kính nổi bên phải (bo góc 26px).
  - Thẻ QA: Nền kính sáng với chữ đen `#0F172A`, chip xanh lục `✓ TỐI ƯU`, chỉ số ký tự và tốc độ đọc CPS hiển thị màu sắc tương phản cao.
  - Thẻ Bảng thuật ngữ: Huy hiệu gradient tím hồng (`#8B5CF6` - `#EC4899`), chữ đen `#0F172A` và cặp từ khóa đối chiếu màu sắc phong phú (cam rực rỡ `#EA580C` ➔ xanh Sapphire `#0066FF`).
- **Thanh Đáy (`AppStatusBar.qml`):**
  - Thanh viên thuốc nổi hiển thị trạng thái engine, VRAM và tiến độ dịch.

### 4.4 Hiệu Ứng Chuyển Động & Tương Tác Vật Lý (Theo Video Mẫu D:\Tiktok.mp4)
1. **Thấu Kính Kính Lỏng Chuyển Dòng Phụ Đề (HarmonyOS Liquid Droplet Lens):**
   - Áp dụng trực tiếp vào quá trình chuyển chọn phụ đề ở danh sách bên trái (không render thanh điều hướng TikTok thừa trên giao diện).
   - Thấu kính trượt là một **khoang kính lỏng trong suốt nổi** có viền sáng bóng kép cùng quầng tán sắc lăng kính (Chromatic Iridescence: viền ánh xanh cyan `#38bdf8` và hồng tím `#ec4899`).
   - **Độ dãn & nén đàn hồi bảo toàn thể tích (Volume Conservation Stretch):** Khi chuyển câu phụ đề, thấu kính dãn dài theo trục dọc `scaleY(1.06)` và co nhẹ theo trục ngang `scaleX(0.99)` như chất lỏng thật; tuyệt đối không co giãn quá chiều ngang 100% kết hợp `overflow-x: hidden !important` để triệt tiêu hoàn toàn thanh cuộn ngang không mong muốn.
   - **Cấu trúc thẻ phụ đề chống lấn chữ:** Chiều cao cố định chuẩn 84px với bố cục cột linh hoạt (`display: flex; flex-direction: column; justify-content: space-between`), căn lề chuẩn 12px 14px và giới hạn tối đa 2 dòng văn bản với `text-overflow: ellipsis`, bảo đảm chữ không bao giờ bị đè hay lấn sang ô phụ đề khác.
   - **Quy tắc tương phản màu sắc tuyệt đối:**
     - *Dòng đang chọn (Active):* Nền sapphire xanh dương, mã thời gian màu trắng băng `#E0F2FE`, chữ phụ đề màu trắng tinh `#FFFFFF` với bóng đổ nhẹ, huy hiệu vàng `#FEF08A` chữ nâu đậm `#854D0E`.
     - *Dòng chưa chọn (Inactive):* Nền kính mờ trắng sáng `rgba(255, 255, 255, 0.78)`, mã thời gian màu xanh sapphire đậm `#0369A1` (luôn sắc nét và dễ đọc trên nền sáng), chữ phụ đề đen tuyền Obsidian `#0F172A`, chip trạng thái xanh lá `#15803D` hoặc hổ phách `#B45309`.
   - **Nảy đàn hồi khi dừng (Elastic Snap & Settle):** Khi chạm đích, thấu kính nảy đàn hồi (spring damping `cubic-bezier(0.34, 1.56, 0.64, 1)`) rồi ôm sát vào câu phụ đề được chọn.
2. **Hiệu ứng chuyển cảnh không gian dịch (Workspace Liquid Glide):**
   - Khi chuyển dòng phụ đề, nội dung trong `TranslationWorkspace.qml` trượt nhẹ (`y: 10 ➔ 0`) và chuyển mượt từ mờ sang nét (`filter: blur(4px) ➔ blur(0px)` trong 250ms), đồng bộ nhịp nhàng với giọt nước trượt ở danh sách bên trái.
3. **Hiệu ứng Hover & Nén Đàn Hồi (Hover & Liquid Press):**
   - Rê chuột (Hover): Nút bấm và thẻ phụ đề nổi nhẹ (`translateY(-2px)`), viền specular sáng rực.
   - Nhấn giữ (Press/Hold): Co nén đàn hồi 0.96x (`scale: 0.96`) kèm đổ bóng chìm, khi nhả tay tự động nảy lại vị trí cũ nhờ đường cong đàn hồi vật lý.


---

## 5. Quyết Định Kỹ Thuật Đã Thống Nhất Qua Rà Soát (Builder Check)

1. **Khả năng xuyên thấu trên Windows:** Dùng API chuẩn `QQuickWindow.setDefaultAlphaBuffer(True)` trong `main.py` thay vì can thiệp `ctypes` DWM để bảo đảm tuyệt đối không crash.
2. **Kéo giãn cột:** Giữ nguyên `SplitView` với thanh ngăn cách trong suốt 12px.
3. **Cụm Dịch Tự Động:** Duy trì đầy đủ các nút Start / Pause / Resume / Cancel trong Header Island dạng viên thuốc.
4. **Bộ chọn ngôn ngữ:** Giữ `sourceLangCombo` tương tác trong `TranslationWorkspace.qml` cho kiểm thử và bổ sung nhãn hiển thị trực quan trên Header.
5. **Chế độ Maximize:** Khi cửa sổ phóng to tối đa, góc bo ngoài tự động phẳng về 0px để khớp sát viền màn hình.
6. **Tối ưu FPS cho hiệu ứng chuyển động:** Dùng `Behavior on y` và `Behavior on scale` với các phép biến đổi phần cứng GPU của QML (`layer.enabled: false` để tránh tốn thêm VRAM texture), giữ FPS ổn định 60-120fps trên cả laptop tiết kiệm điện.

