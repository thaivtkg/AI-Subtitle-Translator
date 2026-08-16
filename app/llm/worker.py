import os
import time
from PySide6.QtCore import QThread, Signal

class TranslationWorker(QThread):
    progress = Signal(str)
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, prompt, model_path="models/qwen.gguf"):
        super().__init__()
        self.prompt = prompt
        self.model_path = model_path

    def run(self):
        try:
            # Nếu chưa có model thật -> Chạy giả lập để test UI
            if not os.path.exists(self.model_path):
                time.sleep(0.5) # Fake loading
                mock_text = "Đây là bản dịch giả lập vì chưa có file model (.gguf)."
                current_text = ""
                for char in mock_text:
                    current_text += char
                    self.progress.emit(current_text)
                    time.sleep(0.02) # Fake streaming speed
                self.finished.emit(mock_text)
                return

            # Nếu có model thật -> Chạy Llama.cpp
            from llama_cpp import Llama
            llm = Llama(model_path=self.model_path, n_ctx=2048, verbose=False)
            stream = llm(
                self.prompt,
                max_tokens=256,
                stop=["<|im_end|>", "</current_subtitle_to_translate>"],
                stream=True
            )
            
            result_text = ""
            for output in stream:
                chunk = output["choices"][0]["text"]
                result_text += chunk
                self.progress.emit(result_text)
                
            self.finished.emit(result_text)
        except Exception as e:
            self.error.emit(str(e))
