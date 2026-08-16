import os
import time
import re
from PySide6.QtCore import QThread, Signal
from app.llm.model_manager import ModelManager

class TranslationWorker(QThread):
    progress = Signal(str)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, prompt, profile):
        super().__init__()
        self.prompt = prompt
        self.profile = profile
        self.model_path = os.path.join("models", profile.get("model_name", "qwen3-4b.gguf"))
        self._is_cancelled = False

    def cancel(self):
        self._is_cancelled = True

    def run(self):
        try:
            if not os.path.exists(self.model_path):
                time.sleep(0.5)
                mock_text = f"Bản dịch giả lập.\nModel: {self.profile.get('model_name')}\nVRAM: {self.profile.get('gpu_info', {}).get('vram_gb', 0)}GB"
                current_text = ""
                for char in mock_text:
                    if self._is_cancelled: return
                    current_text += char
                    self.progress.emit(current_text)
                    time.sleep(0.01)
                self.finished.emit(mock_text)
                return

            manager = ModelManager.get_instance()
            n_ctx = self.profile.get("n_ctx", 2048)
            n_gpu_layers = self.profile.get("n_gpu_layers", -1)
            
            manager.load_model(self.model_path, n_ctx=n_ctx, n_gpu_layers=n_gpu_layers)
            
            # TĂNG MAX_TOKENS LÊN 1024 ĐỂ AI KHÔNG BỊ HẾT HƠI KHI ĐANG "THINK"
            stream = manager.generate_stream(self.prompt, max_tokens=1024)
            
            raw_text = ""
            for output in stream:
                if self._is_cancelled: return
                chunk = output["choices"][0]["text"]
                raw_text += chunk
                
                # --- LOGIC LỌC & HIỂN THỊ THÔNG MINH MỚI ---
                # Nếu thẻ <think> đang mở và chưa đóng
                if '<think>' in raw_text and '</think>' not in raw_text:
                    self.progress.emit("🤔 AI đang suy nghĩ văn cảnh...")
                    continue # Bỏ qua việc in text rác ra màn hình
                
                # Khi thẻ <think> đã đóng, tiến hành xóa nó đi và in phần text thật
                clean_text = re.sub(r'<think>.*?</think>', '', raw_text, flags=re.DOTALL)
                display_text = clean_text.strip()
                
                if display_text:
                    self.progress.emit(display_text)
                
            # Đảm bảo kết quả cuối cùng sạch sẽ
            final_clean = re.sub(r'<think>.*?</think>', '', raw_text, flags=re.DOTALL).strip()
            self.finished.emit(final_clean)
            
        except Exception as e:
            self.error.emit(str(e))