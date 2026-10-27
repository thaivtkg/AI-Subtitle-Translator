import json
import os
from typing import Any, Dict, List, Optional


class AppSettings:
    DEFAULT_SETTINGS = {
        "active_model_id": "qwen2.5-7b-instruct-q4_k_m",
        "custom_n_ctx": 4096,
        "custom_n_gpu_layers": -1,
        "recent_files": [],
    }

    def __init__(self, file_path: Optional[str] = None):
        self.file_path = file_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "app_settings.json",
        )
        self._data: Dict[str, Any] = dict(self.DEFAULT_SETTINGS)
        self.load()

    def load(self) -> None:
        if not os.path.exists(self.file_path):
            return
        try:
            with open(self.file_path, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                if isinstance(loaded, dict):
                    self._data.update(loaded)
        except Exception as e:
            print(f"[Settings Warning] Không thể đọc {self.file_path}: {e}")

    def save(self) -> bool:
        try:
            parent_dir = os.path.dirname(self.file_path)
            if parent_dir and not os.path.exists(parent_dir):
                os.makedirs(parent_dir, exist_ok=True)
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"[Settings Error] Không thể lưu {self.file_path}: {e}")
            return False

    def get(self, key: str, default: Any = None) -> Any:
        return self._data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self._data[key] = value
        self.save()

    @property
    def active_model_id(self) -> str:
        return self.get("active_model_id", self.DEFAULT_SETTINGS["active_model_id"])

    @active_model_id.setter
    def active_model_id(self, value: str) -> None:
        self.set("active_model_id", value)

    @property
    def recent_files(self) -> List[str]:
        val = self.get("recent_files", [])
        return val if isinstance(val, list) else []

    def add_recent_file(self, file_path: str, max_items: int = 5) -> None:
        if not file_path:
            return
        norm_path = os.path.normpath(file_path)
        current = [f for f in self.recent_files if os.path.normpath(f) != norm_path]
        current.insert(0, norm_path)
        self.set("recent_files", current[:max_items])
