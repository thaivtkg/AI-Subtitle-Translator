import os

class ModelManager:
    _instance = None
    _llm = None
    _current_model_path = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = ModelManager()
        return cls._instance

    def load_model(self, model_path: str, n_ctx: int = 4096, n_gpu_layers: int = -1):
        # Tránh load lại nếu cùng một model
        if self._llm is not None and self._current_model_path == model_path:
            return True
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")

        # Giải phóng VRAM model cũ nếu có
        if self._llm is not None:
            del self._llm
        
        from llama_cpp import Llama
        self._llm = Llama(
            model_path=model_path, 
            n_ctx=n_ctx, 
            n_gpu_layers=n_gpu_layers,
            verbose=False
        )
        self._current_model_path = model_path
        return True

    def generate_stream(self, prompt: str, max_tokens: int = 256):
        if self._llm is None:
            raise RuntimeError("Model chưa được load.")
        
        return self._llm(
            prompt,
            max_tokens=max_tokens,
            stop=["<|im_end|>", "</current_subtitle_to_translate>"],
            stream=True
        )