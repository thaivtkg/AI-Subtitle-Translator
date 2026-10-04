# AI Subtitle Translator 🎬🤖

![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)
![PySide6](https://img.shields.io/badge/Framework-PySide6-green.svg)
![Llama.cpp](https://img.shields.io/badge/Backend-Llama.cpp-orange.svg)
![CUDA](https://img.shields.io/badge/Acceleration-CUDA-76B900.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

**AI Subtitle Translator** là công cụ dịch phụ đề chuyên nghiệp, hoạt động hoàn toàn ngoại tuyến (Offline) trên máy tính cá nhân. Ứng dụng tận dụng sức mạnh của các Local LLM (như Qwen 2.5, DeepSeek) để mang lại chất lượng bản địa hóa ngôn ngữ vượt trội, bảo mật dữ liệu 100% và không yêu cầu bất kỳ API Key nào.

---

## ✨ Tính năng cốt lõi

### 🧠 Trí tuệ Bản địa hóa (Translation Intelligence)
* **Translation Memory (LWW):** Tự động ghi nhớ và tái sử dụng các câu đã dịch với độ chính xác 100% (Zero-overhead context injection).
* **Glossary & Forbidden Words:** Quản lý từ vựng chuyên ngành; ép buộc LLM tuân thủ hoặc tuyệt đối tránh sử dụng các từ cấm (ngăn chặn hallucination).
* **Entity Dictionary:** Quản lý danh tính nhân vật, địa danh (alias resolution) đảm bảo tính nhất quán trên toàn bộ series.

### ⚙️ Động cơ Dịch thuật (Batch Processing)
* **Dịch hàng loạt tự động:** Đưa toàn bộ file SRT vào hàng đợi xử lý.
* **Checkpoint an toàn:** Tự động lưu tiến độ. Bạn có thể tắt máy và Resume vào hôm sau mà không mất bất kỳ dòng dịch nào.

### 📦 Quản lý Mô hình Thông minh (Smart Model Management)
* **Hardware-Aware:** Tự động phân tích GPU, VRAM, RAM và Backend để dán nhãn khuyên dùng (RECOMMENDED / COMPATIBLE).
* **Safe Download Manager:** Tải mô hình trực tiếp từ server qua luồng ngầm (QThread) với cơ chế *Atomic Rename* an toàn tuyệt đối.
* Hỗ trợ chuyển đổi nhanh các mô hình tối ưu cho tiếng Việt: **Qwen 2.5 (3B, 7B, 14B)** và **DeepSeek-R1-Distill-Qwen**.

---

## 💻 Yêu cầu hệ thống

| Thành phần | Tối thiểu (CPU Mode) | Khuyên dùng (GPU Offload) |
| :--- | :--- | :--- |
| **OS** | Windows 10/11 (64-bit) | Windows 10/11 (64-bit) |
| **RAM** | 8 GB | 16 GB trở lên |
| **GPU** | Không yêu cầu | NVIDIA RTX 3060 / 4060 trở lên |
| **VRAM** | N/A | 6.0 GB - 8.0 GB+ |
| **Ổ cứng** | 5 GB (SSD) | 15 GB (SSD) |

---

## 🚀 Hướng dẫn cài đặt

### Bước 1: Chuẩn bị môi trường
Yêu cầu máy tính đã cài đặt [Python 3.11+](https://www.python.org/downloads/) và Git. Mở Terminal/PowerShell:

```bash
git clone https://github.com/thaivtkg/AI-Subtitle-Translator.git
cd AI-Subtitle-Translator

# Tạo và kích hoạt môi trường ảo (Virtual Environment)
python -m venv venv
.\venv\Scripts\activate
```

### Bước 2: Cài đặt thư viện cốt lõi

```bash
pip install -r requirements.txt
```

### Bước 3: Kích hoạt tăng tốc GPU NVIDIA (Quan trọng)

Để mô hình chạy mượt mà và tận dụng GPU rời, bạn cần cài đặt lại `llama-cpp-python` với tùy chọn hỗ trợ CUDA.
*(Yêu cầu đã cài đặt NVIDIA CUDA Toolkit trên máy)*

```bash
# Xóa bản thường (nếu có)
pip uninstall llama-cpp-python -y

# Cài đặt bản hỗ trợ CUDA
$env:CMAKE_ARGS="-DGGML_CUDA=on"
pip install llama-cpp-python --upgrade --force-reinstall --no-cache-dir
```

### Bước 4: Khởi chạy ứng dụng

```bash
python main.py
```

*Lần đầu tiên mở ứng dụng, hãy vào mục **Quản lý Mô hình**, hệ thống sẽ tự động quét cấu hình máy bạn và đề xuất mô hình phù hợp nhất để tải về.*

---

## 🧪 Dành cho lập trình viên (Testing)

Dự án được bảo vệ bởi hơn 240+ bài kiểm thử tự động (Unit Test, Integration Test, Batch Test). Để chạy kiểm thử:

```bash
pytest -v
```

---

## 📜 Giấy phép

Dự án được phân phối dưới giấy phép **MIT License**.
