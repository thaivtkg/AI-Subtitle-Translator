import os
from PySide6.QtCore import QThread, Signal
from app.llm.model_manager import ModelManager

class TranslationWorker(QThread):
    progress = Signal(int, str)
    finished = Signal(int, str)
    error = Signal(int, str)

    def __init__(self, target_index, prompt, profile):
        super().__init__()
        self.target_index = target_index
        self.prompt = prompt
        self.profile = profile
        self.model_path = os.path.join("models", profile.get("model_name", "qwen3-8b-q4_k_m.gguf"))
        self._is_cancelled = False

    def cancel(self):
        self._is_cancelled = True

    @staticmethod
    def _visible_translation(raw_text):
        """Return only translated text; keep model reasoning out of the UI."""
        think_start = raw_text.find("<think>")
        if think_start >= 0:
            think_end = raw_text.find("</think>", think_start + len("<think>"))
            if think_end < 0:
                return ""
            raw_text = raw_text[think_end + len("</think>"):]
        else:
            for size in range(len("<think>") - 1, 0, -1):
                if raw_text.endswith("<think>"[:size]):
                    return raw_text[:-size].strip()

        return raw_text.strip()

    def run(self):
        try:
            # --- 1. KIỂM TRA TỒN TẠI MODEL THẬT (CHẶN HOÀN TOÀN MOCK) ---
            if not os.path.exists(self.model_path):
                self.error.emit(self.target_index, f"Lỗi: Không tìm thấy file model tại '{self.model_path}'. Vui lòng đặt file GGUF vào thư mục models/.")
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
                
                # --- 3. ẨN THINK, CHỈ STREAM PHẦN DỊCH ---
                display_text = self._visible_translation(raw_text)
                
                if display_text:
                    self.progress.emit(self.target_index, display_text)
                
            final_clean = self._visible_translation(raw_text)
            print(
                f"[TRANSLATION_FINISH] target={self.target_index} "
                f"raw_len={len(raw_text)} clean_len={len(final_clean)} "
                f"clean_text={final_clean!r}",
                flush=True,
            )
            self.finished.emit(self.target_index, final_clean)
            
        except Exception as e:
            self.error.emit(self.target_index, str(e))
