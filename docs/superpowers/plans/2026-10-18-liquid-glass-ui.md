# Kế Hoạch Triển Khai: Giao Diện Liquid Glass & Đảo Nổi (Floating Islands)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai ngôn ngữ thiết kế Ultra-Gloss Liquid Glass (kính lỏng siêu bóng, nhìn xuyên thấu desktop, 3 đảo kính nổi, thấu kính giọt nước chuyển dòng phụ đề bảo toàn thể tích, văn bản tương phản cao) lên ứng dụng PySide6/QML mà vẫn bảo toàn 100% chức năng và vượt qua toàn bộ 268+ automated tests.

**Architecture:** Sử dụng `QQuickWindow.setDefaultAlphaBuffer(True)` để kích hoạt kênh trong suốt phần cứng trên Windows; phân tách cửa sổ chính thành 3 đảo kính nổi độc lập thông qua `SplitView` có khoảng hở 12px trong suốt; cập nhật hệ thống token màu kính lỏng trong `Theme.qml`; áp dụng cơ chế thấu kính lỏng đàn hồi cho danh sách phụ đề `SubtitleListView.qml` và hiệu ứng trượt mượt mà cho `TranslationWorkspace.qml`.

**Tech Stack:** Python 3.11, PySide6 6.11.2 (Qt Quick / QML 2.15, QtQuick.Controls 2.15), pytest-qt.

**Spec:** `docs/superpowers/specs/2026-10-18-liquid-glass-ui-design.md`

## Global Constraints

- **Window Transparency:** Kích hoạt `QQuickWindow.setDefaultAlphaBuffer(True)` trong `main.py` trước khi nạp QML; nền `ApplicationWindow` đặt `color: "transparent"`.
- **Test Integrity:** Tuyệt đối giữ nguyên toàn bộ bộ định danh `objectName` (`btnOpenSrt`, `searchInput`, `btnTranslate`, `subtitleList`, `subtitleRow_0`, `batchControlBar`, `btnBatchStart`, `btnBatchPause`, `translationInput`, `sourceLangCombo`, `contextTabs`, `storySummaryInput`, `statusFilterCombo`, `chunkFilterCombo`, `paginationBar`, `timeFilterCheck`, `startMinInput`, `endMinInput`) để 100% bài kiểm thử e2e tiếp tục pass.
- **Text Readability Invariant:** Văn bản trên thẻ phụ đề và hộp câu dịch khi chưa chọn (Inactive) phải dùng chữ đen tuyền Obsidian `#0F172A` và mã thời gian xanh navy `#0369A1` trên nền kính mờ trắng sáng; khi được chọn (Active) phải dùng chữ trắng tinh `#FFFFFF` và mã thời gian trắng băng `#E0F2FE` trên nền sapphire `#0066FF`.
- **Zero Horizontal Overflow:** Tuyệt đối không để xảy ra thanh cuộn ngang trong danh sách phụ đề; thấu kính lỏng chuyển động dãn dọc `scaleY(1.06)` và co nhẹ bề ngang `scaleX(0.99)` bảo toàn thể tích chất lỏng, kết hợp `overflow-x: hidden !important` / `clip: true`.
- **Card Collision Prevention:** Chiều cao cố định thẻ phụ đề chuẩn 84px với bố cục cột linh hoạt (`display: flex; flex-direction: column; justify-content: space-between`), căn lề chuẩn 12px 14px và giới hạn tối đa 2 dòng văn bản với `text-overflow: ellipsis`.

## Review Focus

1. **Khả năng xuyên thấu trên Windows:** Kiểm tra cờ `flags: Qt.FramelessWindowHint | Qt.Window` và `QQuickWindow.setDefaultAlphaBuffer(True)` không làm cửa sổ bị đen xì (black artifact) hay crash bộ đệm DirectX/OpenGL.
2. **Kéo giãn cột mượt mà:** Kiểm tra kéo thanh ngăn cách giữa 3 cột trong `SplitView` vẫn giữ nguyên khe hở trong suốt 12px mà không làm vỡ bố cục các đảo kính.
3. **Độ tương phản và không tràn văn bản:** Kiểm tra các câu phụ đề dài 2 dòng hoặc nhiều ký tự không bị đè lấn sang hàng bên cạnh hay mất chữ.
4. **Phím tắt và điều khiển cửa sổ:** Kiểm tra cụm 3 nút macOS góc trái (Đóng, Thu nhỏ, Phóng to) hoạt động chuẩn xác và các phím tắt `Ctrl+O`, `Ctrl+S`, `Ctrl+Enter` vẫn nhận bình thường.
5. **Hiệu năng GPU:** Đảm bảo hiệu ứng chuyển động chuyển dòng phụ đề chạy mượt mà 60-120fps không giật lag trên card đồ họa onboard.

---

### Task 1: Kích Hoạt Kênh Trong Suốt Phần Cứng Cho Cửa Sổ Desktop Trong `main.py`

**Files:**
- Modify: `main.py:1-25`
- Test: `tests/e2e/test_driver_smoke.py`

**Interfaces:**
- Consumes: `PySide6.QtQuick.QQuickWindow.setDefaultAlphaBuffer(True)`
- Produces: Runtime Qt Quick engine hỗ trợ background trong suốt cho cửa sổ không viền

- [ ] **Step 1: Viết test kiểm tra cờ alpha buffer của QQuickWindow**

Tạo hàm test trong `tests/e2e/test_driver_smoke.py`:
```python
def test_alpha_buffer_enabled():
    from PySide6.QtQuick import QQuickWindow
    from PySide6.QtGui import QGuiApplication
    assert QQuickWindow.hasDefaultAlphaBuffer() is True
```

- [ ] **Step 2: Chạy test để xác nhận FAIL trước khi sửa code**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_alpha_buffer_enabled -v`
Expected: FAIL với assertion `hasDefaultAlphaBuffer() is False`

- [ ] **Step 3: Cập nhật `main.py` thêm `QQuickWindow.setDefaultAlphaBuffer(True)`**

Trong `main.py`, import `QQuickWindow` từ `PySide6.QtQuick` và gọi `QQuickWindow.setDefaultAlphaBuffer(True)` ngay trước `QQuickStyle.setStyle("Basic")`.

- [ ] **Step 4: Chạy lại test để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_alpha_buffer_enabled -v`
Expected: PASS

- [ ] **Step 5: Commit thay đổi Task 1**

```bash
git add main.py tests/e2e/test_driver_smoke.py
git commit -m "feat(window): enable default alpha buffer for frameless desktop transparency"
```

---

### Task 2: Bổ Sung Hệ Thống Token Màu Liquid Glass & Specular Bevel Trong `Theme.qml`

**Files:**
- Modify: `ui/qml/theme/Theme.qml:1-44`
- Test: `tests/test_theme_tokens.py` (tạo mới)

**Interfaces:**
- Consumes: Bộ thông số thiết kế từ spec mục 3 (`Theme.qml`)
- Produces: Các biến token màu kính lỏng (`glassBackground`, `glassIslandSurface`, `glassPodLuminous`, `glassBorderSpecularUpper`, `accentSapphire`, `textOnLightPod`, `radiusIsland`, `radiusPill`)

- [ ] **Step 1: Viết test kiểm tra sự tồn tại của các token Liquid Glass mới trong `Theme.qml`**

Tạo file `tests/test_theme_tokens.py`:
```python
import pytest
from pathlib import Path

def test_theme_contains_liquid_glass_tokens():
    theme_file = Path("ui/qml/theme/Theme.qml")
    content = theme_file.read_text(encoding="utf-8")
    for token in [
        "glassBackground",
        "glassIslandSurface",
        "glassPodLuminous",
        "glassPodRaised",
        "glassBorderSpecularUpper",
        "accentSapphire",
        "textOnLightPod",
        "radiusIsland",
        "radiusPill"
    ]:
        assert token in content, f"Missing token {token} in Theme.qml"
```

- [ ] **Step 2: Chạy test để xác nhận FAIL**

Run: `.\.venv\Scripts\python.exe -m pytest tests/test_theme_tokens.py -v`
Expected: FAIL với missing token

- [ ] **Step 3: Cập nhật `ui/qml/theme/Theme.qml` bổ sung đầy đủ các token theo đúng đặc tả**

Thêm các property:
- Nền kính: `glassBackground`, `glassIslandSurface`, `glassIslandActive`, `glassPodLuminous`, `glassPodRaised`
- Viền phản chiếu specular: `glassBorderSpecularUpper`, `glassBorderSpecularLower`, `glassBorderSubtle`, `glassGleamWhite`
- Màu xanh Sapphire: `accentSapphire: "#0066FF"`, `accentSapphireHover: "#1A75FF"`, `accentSapphireGradientEnd: "#0284C7"`
- Màu chữ tương phản cao: `textOnLightPod: "#0F172A"`, `textOnLightPodMuted: "#334155"`, `textPrimaryGlass: "#FFFFFF"`
- Huy hiệu & bo góc: `badgeEmeraldBg`, `badgeEmeraldText`, `badgeAmberBg`, `badgeAmberText`, `radiusIsland: 26`, `radiusPill: 22`, `islandSpacing: 12`.

- [ ] **Step 4: Chạy lại test để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/test_theme_tokens.py -v`
Expected: PASS

- [ ] **Step 5: Commit thay đổi Task 2**

```bash
git add ui/qml/theme/Theme.qml tests/test_theme_tokens.py
git commit -m "feat(theme): add ultra-gloss liquid glass color tokens and spacing metrics"
```

---

### Task 3: Tái Cấu Trúc Khung Cửa Sổ & 3 Đảo Kính Nổi Trong `ui/qml/Main.qml`

**Files:**
- Modify: `ui/qml/Main.qml:1-170`
- Test: `tests/e2e/test_driver_smoke.py`

**Interfaces:**
- Consumes: Token `Theme.glassBackground`, `Theme.glassIslandSurface`, `Theme.radiusIsland`, `Theme.islandSpacing`
- Produces: Cửa sổ chính trong suốt với container bo góc 26px, `SplitView` có thanh ngăn cách trong suốt 12px chia 3 đảo kính nổi

- [ ] **Step 1: Viết test kiểm tra màu nền cửa sổ chính trong suốt và container đảo kính**

Thêm test vào `tests/e2e/test_driver_smoke.py`:
```python
def test_main_window_transparency_and_islands(harness):
    window = harness.window
    assert window.property("color").name() == "#00000000" or window.property("color").alpha() < 0.1
    split_view = harness.driver.find("mainSplitView")
    assert split_view is not None
```

- [ ] **Step 2: Chạy test để xác nhận FAIL**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_main_window_transparency_and_islands -v`
Expected: FAIL vì `color` hiện tại là `Theme.bgApp` (`#090d16`)

- [ ] **Step 3: Cập nhật `ui/qml/Main.qml`**
  - Đặt `color: "transparent"` cho `ApplicationWindow`.
  - Bọc nội dung trong lớp container chính với lề 14px, nền `Theme.glassBackground` với bo góc `Theme.radiusIsland` (tự động về 0px khi maximize) và viền specular phản chiếu ánh sáng.
  - Cập nhật `mainSplitView`:
    - `handle: Item { implicitWidth: Theme.islandSpacing }` (khe hở trong suốt 12px giữa 3 đảo).
    - Cột 1, Cột 2, Cột 3 được bọc bằng các thẻ đảo kính độc lập (`Rectangle { radius: Theme.radiusIsland; color: Theme.glassIslandSurface; border.color: Theme.glassBorderSpecularUpper; ... }`).
    - Giữ nguyên toàn bộ ID (`subListView`, `transWorkspace`, `contextInspector`) và liên kết signal/slot.

- [ ] **Step 4: Chạy lại test để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_main_window_transparency_and_islands -v`
Expected: PASS

- [ ] **Step 5: Commit thay đổi Task 3**

```bash
git add ui/qml/Main.qml tests/e2e/test_driver_smoke.py
git commit -m "feat(ui): redesign main window into 3 floating glass islands with transparent backdrop"
```

---

### Task 4: Tái Thiết Kế Thanh Tiêu Đề Viên Thuốc Kính Lỏng Trong `ui/qml/components/AppHeader.qml`

**Files:**
- Modify: `ui/qml/components/AppHeader.qml:1-120`
- Test: `tests/e2e/test_driver_smoke.py`

**Interfaces:**
- Consumes: Cụm điều khiển cửa sổ macOS (3 nút tròn màu đỏ/vàng/xanh), viên thuốc hiển thị ngôn ngữ `English ➔ Vietnamese`, nút thao tác sapphire
- Produces: Thanh header đảo kính nổi dạng viên thuốc bo tròn 18px với đầy đủ các `objectName` cũ

- [ ] **Step 1: Viết test kiểm tra các nút điều khiển cửa sổ kiểu macOS và nút chức năng header**

Thêm test vào `tests/e2e/test_driver_smoke.py`:
```python
def test_header_macos_controls_and_pills(harness):
    assert harness.driver.find("btnClose") is not None
    assert harness.driver.find("btnMinimize") is not None
    assert harness.driver.find("btnMaximize") is not None
    assert harness.driver.find("btnOpenSrt") is not None
```

- [ ] **Step 2: Chạy test để xác nhận trạng thái ban đầu**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_header_macos_controls_and_pills -v`
Expected: PASS (các nút đã có objectName sẵn)

- [ ] **Step 3: Cập nhật giao diện `AppHeader.qml` theo chuẩn Ultra-Gloss Liquid Glass**
  - Chuyển nền thành viên thuốc kính lỏng: bo góc 18px, nền `Theme.glassIslandSurface`, viền phản chiếu ánh sáng specular kép.
  - Góc trái: Thay cụm nút vuông Windows bằng 3 nút tròn màu sắc kiểu macOS (Đỏ: `#FF453A`, Vàng: `#FF9F0A`, Xanh: `#30D158`) giữ nguyên `objectName: "btnClose"`, `"btnMinimize"`, `"btnMaximize"`.
  - Ở giữa: Bổ sung viên thuốc thông tin ngôn ngữ `English ➔ Vietnamese` nổi bật.
  - Các nút hành động: Định dạng viên thuốc kính (`radius: height / 2`), nút "Dịch tự động" dùng gradient Sapphire `#0066FF` kèm hiệu ứng hover nảy nhẹ `translateY(-2px)`.

- [ ] **Step 4: Chạy lại toàn bộ test e2e liên quan đến header để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_batch_ui.py -v`
Expected: ALL PASS

- [ ] **Step 5: Commit thay đổi Task 4**

```bash
git add ui/qml/components/AppHeader.qml
git commit -m "feat(ui): style AppHeader as glossy liquid capsule with macOS window gems and pill buttons"
```

---

### Task 5: Triển Khai Thấu Kính Giọt Nước & Thẻ Phụ Đề Chống Đè Chữ Trong `ui/qml/components/SubtitleListView.qml`

**Files:**
- Modify: `ui/qml/components/SubtitleListView.qml:480-580`
- Test: `tests/e2e/test_driver_smoke.py`

**Interfaces:**
- Consumes: Cấu trúc delegate danh sách phụ đề `subtitleRow_`
- Produces: Thấu kính giọt nước chuyển động nảy đàn hồi (spring damping), thẻ phụ đề chuẩn 84px với độ tương phản cao, triệt tiêu hoàn toàn tràn chữ và thanh cuộn ngang

- [ ] **Step 1: Viết test kiểm tra kích thước thẻ phụ đề và không có thanh cuộn ngang**

Thêm test vào `tests/e2e/test_driver_smoke.py`:
```python
def test_subtitle_row_dimensions_and_selection(harness):
    sub_list = harness.driver.find("subtitleList")
    row0 = harness.driver.find("subtitleRow_0")
    assert row0.property("height") == 84
    harness.driver.click("subtitleRow_1")
    assert sub_list.property("currentIndex") == 1
```

- [ ] **Step 2: Chạy test để xác nhận FAIL**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_subtitle_row_dimensions_and_selection -v`
Expected: FAIL vì chiều cao hiện tại là 62 hoặc 82 tùy hasTranslation

- [ ] **Step 3: Cập nhật `ui/qml/components/SubtitleListView.qml`**
  - Khóa chặt `clip: true` trên `subListView` và container để triệt tiêu hoàn toàn tràn chiều ngang.
  - Bổ sung `Item` thấu kính giọt nước `subDropletLens` phía sau item đang chọn:
    - Bo góc 18px, nền sapphire gradient `#0066FF ➔ #0284C7`, viền specular kép với quầng tán sắc lăng kính (cyan `#38BDF8` + hồng tím `#EC4899`).
    - Hiệu ứng trượt đàn hồi bảo toàn thể tích: `Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }`, co giãn dãn dọc `scale: 1.0` khi dừng, `scaleY: 1.06, scaleX: 0.99` khi đang trượt.
  - Cập nhật delegate `subtitleRow_`:
    - Chiều cao cố định chuẩn: `height: 84px` cho mọi trạng thái.
    - Bố cục flexbox cột với 2 dòng: hàng trên hiển thị mã thời gian và huy hiệu trạng thái; hàng dưới hiển thị văn bản phụ đề (tối đa 2 dòng kèm `Text.ElideRight`).
    - Màu sắc tương phản tuyệt đối:
      - Khi Active: timecode `#E0F2FE`, chữ trắng `#FFFFFF` kèm đổ bóng nhẹ, huy hiệu vàng `#FEF08A` chữ `#854D0E`.
      - Khi Inactive: nền kính mờ trắng `rgba(255, 255, 255, 0.78)`, timecode xanh navy `#0369A1`, chữ đen tuyền Obsidian `#0F172A`, huy hiệu trạng thái xanh lục `#15803D` hoặc hổ phách `#B45309`.

- [ ] **Step 4: Chạy lại test để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_subtitle_row_dimensions_and_selection -v`
Expected: PASS

- [ ] **Step 5: Commit thay đổi Task 5**

```bash
git add ui/qml/components/SubtitleListView.qml
git commit -m "feat(ui): add liquid droplet lens transition and anti-collision subtitle pods to SubtitleListView"
```

---

### Task 6: Tái Thiết Kế Không Gian Dịch Thuật Với Hộp Kính Sáng & Hiệu Ứng Trượt Trong `ui/qml/components/TranslationWorkspace.qml`

**Files:**
- Modify: `ui/qml/components/TranslationWorkspace.qml:20-260`
- Test: `tests/e2e/test_final_regression.py`

**Interfaces:**
- Consumes: Dữ liệu câu gốc, câu dịch, selector ngôn ngữ tương tác
- Produces: Không gian dịch đảo nổi với hộp câu gốc & câu dịch kính sáng mờ, hiệu ứng trượt mượt mà khi đổi câu

- [ ] **Step 1: Viết test kiểm tra các thành phần input câu dịch và dropdown ngôn ngữ**

Thêm test vào `tests/e2e/test_final_regression.py`:
```python
def test_workspace_pods_and_interaction(harness):
    assert harness.driver.find("translationInput") is not None
    assert harness.driver.find("sourceLangCombo") is not None
    assert harness.driver.find("btnTranslate") is not None
```

- [ ] **Step 2: Chạy test để xác nhận PASS trạng thái ban đầu**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_final_regression.py -k "test_workspace_pods_and_interaction" -v`
Expected: PASS

- [ ] **Step 3: Cập nhật `ui/qml/components/TranslationWorkspace.qml`**
  - Bọc toàn bộ vùng hiển thị câu dịch trong container có hiệu ứng chuyển cảnh `liquidGlideIn`:
    - Khi đổi `currentSubtitleIndex`, dịch chuyển nhẹ vị trí `y: 8 ➔ 0` và `opacity: 0.3 ➔ 1.0` trong 220ms.
  - Hộp câu gốc: Nền kính mờ trắng sáng lỏng (`rgba(255,255,255,0.75)`), huy hiệu `🌐 CÂU GỐC` xanh Sapphire rực rỡ, chữ đen tuyền Obsidian `#0F172A` đậm (font-weight 800) siêu nét.
  - Hộp câu dịch: Nền kính sáng lỏng đa tầng (`rgba(255,255,255,0.82)`), huy hiệu `✨ BẢN DỊCH AI` gradient tím-xanh kèm chip độ tin cậy `⚡ 98%` xanh lá, văn bản dịch màu đen Obsidian `#0F172A` bên trong `translationInput`.
  - Cụm nút hành động dưới đáy: Nút "Dịch lại" viền kính mờ và nút "Duyệt / Accept" màu xanh Sapphire nổi bật dạng viên thuốc bo tròn hoàn toàn.

- [ ] **Step 4: Chạy lại test hồi quy để xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_batch_ui.py -v`
Expected: ALL PASS

- [ ] **Step 5: Commit thay đổi Task 6**

```bash
git add ui/qml/components/TranslationWorkspace.qml
git commit -m "feat(ui): redesign TranslationWorkspace with luminous glass pods and fluid glide transition"
```

---

### Task 7: Tái Thiết Kế Bảng Ngữ Cảnh & QA Đảo Nổi Trong `ui/qml/components/ContextInspector.qml`

**Files:**
- Modify: `ui/qml/components/ContextInspector.qml:1-120`
- Test: `tests/e2e/test_final_regression.py`

**Interfaces:**
- Consumes: Tab bar `contextTabs`, thẻ QA và thẻ Thuật ngữ
- Produces: Đảo kính thứ 3 với các thẻ kính mờ sáng, chữ đen Obsidian và chip trạng thái màu sắc rực rỡ

- [ ] **Step 1: Viết test kiểm tra tab bar ngữ cảnh**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_final_regression.py -k "test_final_regression_s2_t8_context_tab_order" -v`
Expected: PASS

- [ ] **Step 2: Cập nhật giao diện `ContextInspector.qml`**
  - Chuyển `TabBar` sang phong cách viên thuốc kính mờ bo góc 16px.
  - Thẻ QA Status: Nền kính sáng `rgba(255, 255, 255, 0.75)`, chữ đen `#0F172A`, chip xanh lục `✓ TỐI ƯU`, chỉ số ký tự màu xanh cyan và CPS màu xanh lá cây rực rỡ.
  - Thẻ Glossary / Thuật ngữ: Huy hiệu gradient tím hồng (`#8B5CF6 ➔ #EC4899`), chữ đen `#0F172A` và cặp chip từ khóa đối chiếu (cam `#EA580C` ➔ xanh Sapphire `#0066FF`).

- [ ] **Step 3: Chạy lại test kiểm tra ContextInspector**

Run: `.\.venv\Scripts\python.exe -m pytest tests/test_context_integration.py -v`
Expected: ALL PASS

- [ ] **Step 4: Commit thay đổi Task 7**

```bash
git add ui/qml/components/ContextInspector.qml
git commit -m "feat(ui): style ContextInspector with luminous glass cards and high-contrast QA metrics"
```

---

### Task 8: Tinh Chỉnh Thanh Trạng Thái Viên Thuốc Trong `ui/qml/components/AppStatusBar.qml`

**Files:**
- Modify: `ui/qml/components/AppStatusBar.qml:1-80`
- Test: `tests/e2e/test_driver_smoke.py`

**Interfaces:**
- Consumes: Thông số engine, VRAM, tiến độ dịch
- Produces: Thanh trạng thái dạng viên thuốc nổi kính mờ mỏng nhẹ dưới đáy

- [ ] **Step 1: Viết test kiểm tra sự hiện diện của AppStatusBar**

Thêm test vào `tests/e2e/test_driver_smoke.py`:
```python
def test_status_bar_exists(harness):
    assert harness.driver.find("appStatusBar") is not None
```

- [ ] **Step 2: Chạy test để xác nhận PASS ban đầu**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_status_bar_exists -v`
Expected: PASS

- [ ] **Step 3: Cập nhật giao diện `AppStatusBar.qml`**
  - Định dạng dạng viên thuốc nổi (`radius: 16px`), nền `Theme.glassIslandSurface`, viền mờ `Theme.glassBorderSubtle`.
  - Hiển thị chip VRAM và Engine dạng viên thuốc nhỏ với chữ tương phản cao.

- [ ] **Step 4: Chạy lại test xác nhận PASS**

Run: `.\.venv\Scripts\python.exe -m pytest tests/e2e/test_driver_smoke.py::test_status_bar_exists -v`
Expected: PASS

- [ ] **Step 5: Commit thay đổi Task 8**

```bash
git add ui/qml/components/AppStatusBar.qml
git commit -m "feat(ui): update AppStatusBar to floating translucent pill capsule"
```

---

### Task 9: Chạy Toàn Bộ Test Suite Kiểm Thử Hồi Quy & Xác Minh Trực Quan

**Files:**
- Test: Toàn bộ 269 bài test trong thư mục `tests/`

- [ ] **Step 1: Chạy toàn bộ test suite tự động**

Run: `.\.venv\Scripts\python.exe -m pytest -v`
Expected: 268+ passed, 0 failed

- [ ] **Step 2: Khởi chạy app và kiểm tra hiển thị thực tế**

Run: `.\.venv\Scripts\python.exe main.py`
Expected: Ứng dụng khởi động mượt mà, cửa sổ trong suốt nhìn xuyên thấu desktop với 3 đảo kính nổi, thấu kính lỏng nảy đàn hồi khi chuyển dòng phụ đề, chữ đen/trắng tương phản cao sắc nét.

- [ ] **Step 3: Commit hoàn tất toàn bộ nhánh phát triển**

```bash
git add -A
git commit -m "feat(ui): complete ultra-gloss liquid glass floating islands redesign"
```
