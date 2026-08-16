import os
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
        self.model_path = os.path.join("models", profile.get("model_name", "qwen3-8b-q4_k_m.gguf"))
        self._is_cancelled = False

    def cancel(self):
        self._is_cancelled = True

    def run(self):
        try:
            # --- 1. KIỂM TRA TỒN TẠI MODEL THẬT (CHẶN HOÀN TOÀN MOCK) ---
            if not os.path.exists(self.model_path):
                self.error.emit(f"Lỗi: Không tìm thấy file model tại '{self.model_path}'. Vui lòng đặt file GGUF vào thư mục models/.")
                return

            # --- 2. NẠP MODEL THẬT QUA MODEL MANAGER ---
            manager = ModelManager.get_instance()
            n_ctx = self.profile.get("n_ctx", 4096)
            n_gpu_layers = self.profile.get("n_gpu_layers", -1)
            
            manager.load_model(self.model_path, n_ctx=n_ctx, n_gpu_layers=n_gpu_layers)
            
            # Tăng max_tokens lên 1024 để model có đủ không gian suy luận và trả kết quả
            stream = manager.generate_stream(self.prompt, max_tokens=1024)
            
            raw_text = ""
            for output in stream:
                if self._is_cancelled: 
                    return
                chunk = output["choices"][0]["text"]
                raw_text += chunk
                
                # --- 3. BỘ LỌC THINK THÔNG MINH (TRÁNH NHẢY UI) ---
                if '<think>' in raw_text and '</think>' not in raw_text:
                    self.progress.emit("🤔 AI đang suy nghĩ văn cảnh...")
                    continue 
                
                clean_text = re.sub(r'<think>.*?</think>', '', raw_text, flags=re.DOTALL)
                display_text = clean_text.strip()
                
                if display_text:
                    self.progress.emit(display_text)
                
            final_clean = re.sub(r'<think>.*?</think>', '', raw_text, flags=re.DOTALL).strip()
            self.finished.emit(final_clean)
            
        except Exception as e:
            self.error.emit(str(e))