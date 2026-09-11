from typing import Generator, Dict, Any

from .base_backend import BaseInferenceBackend


class LlamaCppBackend(BaseInferenceBackend):
    def __init__(self):
        self._llm = None
        self._current_model = ""
        self._is_cancelled = False

    def load_model(self, model_identifier: str, **kwargs) -> bool:
        if self._llm is not None and self._current_model == model_identifier:
            return True

        from llama_cpp import Llama

        self._llm = Llama(
            model_path=model_identifier,
            n_ctx=kwargs.get("n_ctx", 4096),
            n_gpu_layers=kwargs.get("n_gpu_layers", -1),
            verbose=False,
        )
        self._current_model = model_identifier
        return True

    def unload_model(self) -> None:
        self._llm = None
        self._current_model = ""

    def generate(self, prompt: str, system_prompt: str = "", **kwargs) -> str:
        if self._llm is None:
            raise RuntimeError("Model chưa được load.")
        result = self._llm(
            prompt,
            max_tokens=kwargs.get("max_tokens", 256),
            stop=["<|im_end|>", "</current_subtitle_to_translate>"],
            stream=False,
        )
        return result["choices"][0]["text"]

    def stream(self, prompt: str, system_prompt: str = "", **kwargs) -> Generator[Dict[str, Any], None, None]:
        if self._llm is None:
            raise RuntimeError("Model chưa được load.")
        self._is_cancelled = False
        yield from self._llm(
            prompt,
            max_tokens=kwargs.get("max_tokens", 256),
            stop=["<|im_end|>", "</current_subtitle_to_translate>"],
            stream=True,
        )

    def cancel(self) -> None:
        self._is_cancelled = True

    def get_runtime_info(self) -> Dict[str, Any]:
        return {
            "backend": "llama.cpp",
            "model": self._current_model,
            "status": "Ready" if self._llm is not None else "No Model Loaded",
        }
