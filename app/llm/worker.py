import os
import time
from PySide6.QtCore import QThread, Signal
from app.llm.model_manager import ModelManager

class TranslationWorker(QThread):
    progress = Signal(str)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, prompt, model_path="models/qwen3.gguf"):
        super().__init__()
        self.prompt = prompt
        self.model_path = model_path
        self._is_cancelled = False # Cờ hủy an toàn

    def cancel(self):
        """Kích hoạt cờ hủy để luồng tự thoát sạch sẽ"""
        self._is_cancelled = True

    def run(self):
        try:
            # --- MOCK CHẾ ĐỘ NẾU KHÔNG THẤY FILE ---
            if not os.path.exists(self.model_path):
                time.sleep(0.5)
                mock_text = "Đây là bản dịch giả lập. Model Manager đã được kích hoạt."
                current_text = ""
                for char in mock_text:
                    if self._is_cancelled:
                        return # Thoát an toàn
                    current_text += char
                    self.progress.emit(current_text)
                    time.sleep(0.02)
                self.finished.emit(mock_text)
                return

            # --- SỬ DỤNG MODEL MANAGER (LOAD 1 LẦN DUY NHẤT) ---
            manager = ModelManager.get_instance()
            # Note: n_gpu_layers sẽ được điều khiển bởi HardwareDetector sau
            manager.load_model(self.model_path, n_ctx=2048, n_gpu_layers=-1)

            stream = manager.generate_stream(self.prompt, max_tokens=256)
            
            result_text = ""
            for output in stream:
                if self._is_cancelled:
                    return # Thoát an toàn khỏi generator Llama
                chunk = output["choices"][0]["text"]
                result_text += chunk
                self.progress.emit(result_text)
                
            self.finished.emit(result_text)
        except Exception as e:
            self.error.emit(str(e))