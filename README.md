# AI Subtitle Translator 🎬🤖

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB.svg?logo=python&logoColor=white)](https://www.python.org/)
[![PySide6](https://img.shields.io/badge/GUI-PySide6%20%2F%20Qt%20Quick-41CD52.svg?logo=qt&logoColor=white)](https://www.qt.io/)
[![Llama.cpp](https://img.shields.io/badge/Inference-llama--cpp--python-FF6F00.svg)](https://github.com/abetlen/llama-cpp-python)
[![CUDA](https://img.shields.io/badge/Acceleration-NVIDIA%20CUDA-76B900.svg?logo=nvidia&logoColor=white)](https://developer.nvidia.com/cuda-toolkit)
[![Tests](https://img.shields.io/badge/Tests-385%20Passed-brightgreen.svg)](tests/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**AI Subtitle Translator** là phần mềm dịch và biên tập phụ đề chuyên nghiệp (CAT Tool) thế hệ mới, hoạt động **100% Ngoại tuyến (Offline)** trên máy tính cá nhân. Ứng dụng khai thác tối đa sức mạnh của các mô hình ngôn ngữ lớn cục bộ (Local LLM qua định dạng GGUF như **Qwen 2.5**, **DeepSeek**) để mang lại bản dịch tiếng Việt tự nhiên, chuẩn văn phong điện ảnh, bảo mật tuyệt đối dữ liệu và không yêu cầu bất kỳ API Key hay kết nối Internet nào.

---

## ✨ Tính năng nổi bật

### 🎨 1. Studio Workspace 2.0 — Giao diện Biên tập Chuyên nghiệp
* **Bố cục 3 cột chuẩn Studio:** Phân tách tối ưu giữa Danh sách phụ đề (Trái) — Bàn làm việc dịch thuật (Giữa) — Bảng thanh tra ngữ cảnh đa năng (Phải).
* **Native Dark Mode:** Bảng màu Deep Navy & Cyan Cyber (`#0B0F19`, `#00A3FF`) hiện đại, hạn chế mỏi mắt tối đa khi làm việc trong thời gian dài.
* **Thẻ phụ đề giàu thông tin (Data-Dense Cards):** Hiển thị số thứ tự, mốc thời gian, thời lượng (`duration`), xem trước song ngữ và huy hiệu trạng thái (`PENDING`, `TRANSLATING`, `TRANSLATED`, `EDITED`, `ACCEPTED`, `ERROR`).
* **Hiệu ứng AI Neural Scramble Matrix:** Hiệu ứng giải mã chữ ngẫu nhiên ma trận chuyển động theo thời gian thực (40ms/frame) trong lúc chờ mô hình AI xử lý token đầu tiên.
* **Live Streaming HUD:** Theo dõi trực tiếp tiến độ khi AI đang dịch với bộ đếm:
  * 📝 **Số từ (Word Count)** nhảy số tức thời.
  * 🔤 **Số ký tự (Character Count)**.
  * 🟢/🛑 **Số dòng (Line Count)** phát hiện sớm vi phạm phụ đề.
  * ◌ **Con trỏ Braille động** hiển thị trạng thái sinh từ của mạng nơ-ron.

### 🛡️ 2. Subtitle QA Engine v1.1 — Kiểm định Chất lượng Tiêu chuẩn Quốc tế
* **Đo lường thời gian thực (In-Memory Volatile State):** Phân tích trực tiếp trên bộ nhớ mà không làm phình to cấu trúc file `.aisrt`.
* **Cảnh báo tốc độ đọc (CPS - Characters Per Second):**
  * Ngưỡng tối ưu: `CPS ≤ 17` (🟢 Xanh an toàn).
  * Ngưỡng cảnh báo: `17 < CPS ≤ 20` (🟡 Cảnh báo ⚠️).
  * Ngưỡng vượt chuẩn: `CPS > 20` (🛑 Lỗi nghiêm trọng).
* **Cảnh báo độ dài dòng (CPL - Characters Per Line):**
  * Tối ưu: `CPL ≤ 40` ký tự/dòng.
  * Cảnh báo: `40 < CPL ≤ 42`.
  * Vi phạm: `CPL > 42` ký tự/dòng.
* **Cảnh báo số dòng:** Tối đa 2 dòng cho mỗi câu phụ đề.
* **Export Guard:** Tự động chặn và hiển thị hộp thoại cảnh báo nếu người dùng xuất file SRT chứa các câu phụ đề vi phạm QA nghiêm trọng.

### 🧠 3. Bộ ba Trí tuệ Bản địa hóa (Translation Intelligence)
* **Translation Memory (TM):** Tự động ghi nhớ các cặp câu gốc - câu dịch theo nguyên lý *Last-Write-Wins (LWW)*. Tái sử dụng câu dịch với độ chính xác 100% mà không cần gọi lại LLM.
* **Glossary & Forbidden Words:** Quản lý bảng thuật ngữ chuyên ngành; áp đặt quy tắc dịch và danh sách từ cấm kỵ để triệt tiêu hiện tượng ảo giác (hallucination).
* **Bóc tách Thuật ngữ Tự động & Ghim / Bỏ ghim Hai chiều (Auto Term Alignment & Bi-directional Pinning):**
  * Tự động trích xuất các cặp từ gốc - nghĩa dịch đồng thời trong cùng một lượt suy luận dịch thuật mà không tốn thêm request.
  * Hỗ trợ truy vấn bóc tách thuật ngữ theo yêu cầu (*On-Demand Query* ~0.5s) cho các file phụ đề đã có bản dịch sẵn.
  * Ghim thuật ngữ trực tiếp vào Glossary chỉ với 1-click để đồng bộ vĩnh viễn cho toàn bộ các câu dịch tiếp theo.
  * Cơ chế Bỏ ghim hai chiều (*Bi-directional Unpin*): Cho phép gỡ bỏ thuật ngữ bất kỳ lúc nào trực tiếp từ luồng dịch hoặc từ Bảng ngữ cảnh dự án (Intelligence Tab), dữ liệu được đồng bộ hóa tức thì giữa các bộ điều khiển.
* **Lá chắn Chống Rò rỉ Token (Rogue Vocab Shield):** Bộ lọc regex đa tiền tố thời gian thực cắt bỏ triệt để các token suy luận nội bộ và cấu trúc phụ trợ (`[TỪ GỐC]`, `-Tu goc->`, `从根源->`...) ngay trong lúc stream, đảm bảo ô bản dịch chỉ nhận câu phụ đề đích thuần khiết.
* **Entity Dictionary:** Quản lý danh xưng nhân vật, đại từ, địa danh đồng bộ xuyên suốt toàn bộ mùa phim / series.
* **Story Summary:** Khu vực ghi chú cốt truyện tổng quát để định hướng phong cách dịch của AI.

### ⚙️ 4. Động cơ Dịch thuật Tự động (Batch Processing Engine)
* Đưa toàn bộ file phụ đề vào hàng đợi xử lý nền qua `QThread` độc lập, giao diện không bao giờ bị đơ (Zero-blocking UI).
* **Kiến trúc Cách ly Tín hiệu (Signal Isolation):** Phân tách độc lập tín hiệu cập nhật câu gốc (`originalUpdated`) và dòng dữ liệu stream bản dịch (`translationUpdated`), triệt tiêu xung đột trạng thái khi truyền token ở tốc độ cao.
* Hỗ trợ Tạm dừng (`Pause`), Tiếp tục (`Resume`), Hủy an toàn (`Cancel`) và Dịch lại các câu lỗi (`Retry Failed`).
* **Checkpoint an toàn:** Tự động lưu tiến độ vào file dự án `.aisrt`. Bạn có thể tắt máy và tiếp tục bất kỳ lúc nào mà không bị mất dữ liệu.

### 📦 5. Quản lý Mô hình Thông minh & Cài đặt (Smart Model & Settings Manager)
* **Hardware-Aware Scanning:** Tự động quét phần cứng (GPU VRAM, System RAM, CUDA driver) và gắn nhãn đề xuất mô hình phù hợp (`RECOMMENDED`, `COMPATIBLE`).
* **Cơ chế Singleton & Hợp nhất Cài đặt An toàn (Safe Disk-Merge):** Quản lý cấu hình `AppSettings` theo cơ chế Singleton per-path kết hợp tự động nạp và hợp nhất dữ liệu từ đĩa trước khi lưu; loại bỏ hoàn toàn xung đột ghi đè chéo (Race Condition & Split-Brain Cache) giữa các controller, đảm bảo bảo toàn cấu hình mô hình đã chọn và danh sách tệp gần đây khi ứng dụng tắt và mở lại.
* Hỗ trợ tải mô hình ngầm với cơ chế **Atomic Promotion** (tải qua file tạm `.part`, chỉ đổi tên thành `.gguf` khi SHA256 và kích thước hợp lệ 100%).
* Danh mục mô hình tối ưu cho tiếng Việt:
  * **Qwen 2.5 3B / 7B / 14B Instruct (GGUF)**
  * **DeepSeek-R1-Distill-Qwen 7B / 14B (GGUF)**

---

## ⌨️ Bảng Phím tắt Thao tác Nhanh

| Phím tắt | Chức năng |
| :--- | :--- |
| `Ctrl + T` | Bắt đầu dịch câu hiện tại bằng AI |
| `Ctrl + Enter` | Duyệt bản dịch (`ACCEPT`) và tự động chuyển sang câu tiếp theo |
| `↑` / `↓` | Di chuyển lên / xuống giữa các câu phụ đề trong danh sách |
| `Ctrl + S` | Lưu dự án hiện tại (`.aisrt`) |
| `Ctrl + O` | Mở tệp phụ đề SRT hoặc dự án đã lưu |

---

## 💻 Yêu cầu hệ thống

| Thành phần | Cấu hình Tối thiểu (CPU Mode) | Cấu hình Đề xuất (GPU CUDA Acceleration) |
| :--- | :--- | :--- |
| **Hệ điều hành** | Windows 10 / 11 (64-bit) | Windows 10 / 11 (64-bit) |
| **Bộ nhớ RAM** | 8 GB | 16 GB — 32 GB |
| **Card đồ họa (GPU)** | Đồ họa tích hợp (Intel / AMD) | NVIDIA GeForce RTX 3060 / 4060 trở lên |
| **Dung lượng VRAM** | Không áp dụng | 6.0 GB — 12.0 GB+ VRAM |
| **Lưu trữ** | 5 GB SSD trống | 15 GB+ SSD (dùng lưu các mô hình GGUF) |

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### Bước 1: Chuẩn bị môi trường
Yêu cầu máy tính đã cài đặt [Python 3.11+](https://www.python.org/downloads/) và Git. Mở Terminal (PowerShell trên Windows):

```powershell
# 1. Clone kho mã nguồn về máy
git clone https://github.com/thaivtkg/AI-Subtitle-Translator.git
cd AI-Subtitle-Translator

# 2. Tạo môi trường ảo (Virtual Environment)
python -m venv venv

# 3. Kích hoạt môi trường ảo
.\venv\Scripts\activate
```

### Bước 2: Cài đặt các thư viện phụ thuộc

```powershell
pip install -r requirements.txt
```

### Bước 3: Kích hoạt tăng tốc GPU NVIDIA (Khuyên dùng)
Để đạt tốc độ dịch cao nhất (hàng chục token/giây), hãy cài đặt bản `llama-cpp-python` được biên dịch sẵn với CUDA:

```powershell
# Gỡ bỏ bản CPU mặc định (nếu có)
pip uninstall llama-cpp-python -y

# Cài đặt bản CUDA (Yêu cầu máy đã cài NVIDIA CUDA Toolkit 12.x+)
$env:CMAKE_ARGS="-DGGML_CUDA=on"
pip install llama-cpp-python --upgrade --force-reinstall --no-cache-dir
```

> **Mẹo:** Nếu không có card rời NVIDIA, ứng dụng vẫn sẽ tự động nhận diện và chạy mượt mà ở chế độ CPU đa luồng.

### Bước 4: Khởi chạy ứng dụng

```powershell
python main.py
```

Khi mở ứng dụng lần đầu, hãy bấm vào nút **Quản lý Mô hình** trên thanh tiêu đề để hệ thống tự động kiểm tra phần cứng và gợi ý tải mô hình phù hợp nhất.

---

## 🧪 Kiểm định chất lượng (Testing)

Dự án được bảo vệ toàn diện với **385 bài kiểm thử tự động** bao gồm Unit Tests, E2E UI Harness (PySide6 QTest), Deterministic Worker Tests, QA Rules và Round-trip Serialization:

```powershell
# Chạy toàn bộ test suite
pytest -v

# Chạy riêng các bài kiểm thử E2E giao diện
pytest tests/e2e/ -v
```

---

## 📁 Cấu trúc thư mục

```text
AI-Subtitle-Translator/
├── app/
│   ├── controllers/      # Bộ điều khiển trung gian: Translation, Project, Batch, Model
│   ├── core/             # Lõi nghiệp vụ: SRT Parser, QA Engine, TM, Glossary, Entities
│   ├── llm/              # Giao tiếp Local LLM: Worker, PromptBuilder, ModelManager
│   └── models/           # Qt Models: SubtitleModel (bảng phụ đề động)
├── ui/
│   ├── qml/              # Giao diện Qt Quick QML: Main, Studio Workspace, Theme
│   │   ├── components/   # SubtitleListView, TranslationWorkspace, ContextInspector...
│   │   ├── dialogs/      # ModelManagerDialog, ExportGuardDialog...
│   │   └── theme/        # Theme.qml (Bảng màu, typography, khoảng cách)
├── tests/                # 385+ bài kiểm thử tự động (E2E, Core, Controllers)
├── main.py               # Điểm khởi chạy ứng dụng chính
├── pytest.ini            # Cấu hình kiểm thử tự động
└── requirements.txt      # Danh sách thư viện phụ thuộc
```

---

## 📜 Giấy phép

Dự án được phát hành mã nguồn mở theo giấy phép [MIT License](LICENSE).
Mọi đóng góp (Pull Request, Báo cáo lỗi) đều được hoan nghênh!
