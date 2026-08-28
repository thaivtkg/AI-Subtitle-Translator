from typing import Optional, Dict, Any, Generator
from app.core.backends.base_backend import BaseInferenceBackend
from app.core.backends.ollama_backend import OllamaBackend

class ModelManager:
    def __init__(self, backend_type: str = "ollama"):
        self.backend: BaseInferenceBackend
        if backend_type == "ollama":
            self.backend = OllamaBackend()
        else:
            raise ValueError(f"Backend không hỗ trợ: {backend_type}")

        self.current_model_name: str = ""

    def load_model(self, model_name: str, **kwargs) -> bool:
        success = self.backend.load_model(model_name, **kwargs)
        if success:
            self.current_model_name = model_name
        return success

    def unload_model(self) -> None:
        self.backend.unload_model()
        self.current_model_name = ""

    def generate(self, prompt: str, system_prompt: str = "", **kwargs) -> str:
        return self.backend.generate(prompt, system_prompt=system_prompt, **kwargs)

    def stream(self, prompt: str, system_prompt: str = "", **kwargs) -> Generator[str, None, None]:
        return self.backend.stream(prompt, system_prompt=system_prompt, **kwargs)

    def cancel(self) -> None:
        self.backend.cancel()

    def get_status(self) -> Dict[str, Any]:
        return self.backend.get_runtime_info()