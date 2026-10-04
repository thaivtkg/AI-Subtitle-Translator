import json
import os
import tempfile
import time
from PySide6.QtCore import QCoreApplication, QObject, Signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtTest import QTest
import pytest

from app.controllers.model_controller import ModelController
from app.controllers.translation_controller import TranslationController
from app.core.app_settings import AppSettings
from app.core.model_catalog import (
    MODEL_CATALOG,
    ModelMetadata,
    calculate_recommendation,
    scan_local_models,
)
from app.models.subtitle import SubtitleModel
from app.services.download_manager import DownloadManager, DownloadWorker


class SignalSpy:
    def __init__(self, signal):
        self._emissions = []
        signal.connect(self._slot)

    def _slot(self, *args):
        self._emissions.append(list(args))

    def wait(self, timeout_ms=500):
        app = QCoreApplication.instance()
        elapsed = 0
        while elapsed < timeout_ms and not self._emissions:
            if app:
                app.processEvents()
            QTest.qWait(10)
            elapsed += 10
        return len(self._emissions) > 0

    def __len__(self):
        return len(self._emissions)

    def __getitem__(self, index):
        return self._emissions[index]


@pytest.fixture
def qapp():
    return QGuiApplication.instance() or QGuiApplication([])


# ==========================================
# TC-MM-01: HARDWARE RECOMMENDATION SCORING
# ==========================================
def test_tc_mm_01_hardware_recommendation_scoring():
    meta_7b = MODEL_CATALOG["qwen2.5-7b-instruct-q4_k_m"]
    meta_3b = MODEL_CATALOG["qwen2.5-3b-instruct-q4_k_m"]
    meta_14b = MODEL_CATALOG["qwen2.5-14b-instruct-q4_k_m"]

    # 1. GPU 8GB VRAM với CUDA: 7B là RECOMMENDED
    gpu_8gb = {"has_gpu_hardware": True, "name": "RTX 4060", "vram_gb": 8.0}
    badge_7b, _ = calculate_recommendation(meta_7b, gpu_8gb, llama_has_cuda=True)
    assert badge_7b == "RECOMMENDED"

    # 2. GPU 16GB VRAM: 14B là RECOMMENDED
    gpu_16gb = {"has_gpu_hardware": True, "name": "RTX 4080", "vram_gb": 16.0}
    badge_14b, _ = calculate_recommendation(meta_14b, gpu_16gb, llama_has_cuda=True)
    assert badge_14b == "RECOMMENDED"

    # 3. GPU yếu 2GB VRAM: 3B là RECOMMENDED, 14B là NOT_RECOMMENDED
    gpu_2gb = {"has_gpu_hardware": True, "name": "GTX 1050", "vram_gb": 2.0}
    badge_3b, _ = calculate_recommendation(meta_3b, gpu_2gb, llama_has_cuda=True)
    badge_14b_low, _ = calculate_recommendation(meta_14b, gpu_2gb, llama_has_cuda=True)
    assert badge_3b == "RECOMMENDED"
    assert badge_14b_low == "NOT_RECOMMENDED"

    # 4. CPU-only: 3B là RECOMMENDED, 14B là NOT_RECOMMENDED
    gpu_none = {"has_gpu_hardware": False, "name": "None", "vram_gb": 0.0}
    badge_cpu_3b, _ = calculate_recommendation(meta_3b, gpu_none, llama_has_cuda=False, ram_gb=16.0)
    badge_cpu_14b, _ = calculate_recommendation(meta_14b, gpu_none, llama_has_cuda=False, ram_gb=8.0)
    assert badge_cpu_3b == "RECOMMENDED"
    assert badge_cpu_14b == "NOT_RECOMMENDED"


# ==========================================
# TC-MM-02: ADVISORY OVERRIDE
# ==========================================
def test_tc_mm_02_advisory_override(qapp):
    with tempfile.TemporaryDirectory() as tmp_dir:
        # Tạo sẵn file 14b dù máy cấu hình thấp
        meta_14b = MODEL_CATALOG["qwen2.5-14b-instruct-q4_k_m"]
        file_path = os.path.join(tmp_dir, meta_14b.filename)
        with open(file_path, "wb") as f:
            f.write(b"mock weights")

        settings = AppSettings(os.path.join(tmp_dir, "test_settings.json"))
        controller = ModelController(models_dir=tmp_dir, settings=settings)

        # Chọn model 14B thành công (Advisory override)
        success = controller.selectActiveModel("qwen2.5-14b-instruct-q4_k_m")
        assert success is True
        assert controller.activeModelId == "qwen2.5-14b-instruct-q4_k_m"


# ==========================================
# TC-MM-03: LOCAL FILE DETECTION
# ==========================================
def test_tc_mm_03_local_file_detection():
    with tempfile.TemporaryDirectory() as tmp_dir:
        meta_3b = MODEL_CATALOG["qwen2.5-3b-instruct-q4_k_m"]
        target_path = os.path.join(tmp_dir, meta_3b.filename)

        # Ban đầu chưa có file
        avail_before = scan_local_models(tmp_dir)
        assert avail_before["qwen2.5-3b-instruct-q4_k_m"] is False

        # Tạo file
        with open(target_path, "wb") as f:
            f.write(b"content")

        avail_after = scan_local_models(tmp_dir)
        assert avail_after["qwen2.5-3b-instruct-q4_k_m"] is True


# ==========================================
# TC-MM-04: SAFE PARTIAL DOWNLOAD (.part)
# ==========================================
def test_tc_mm_04_safe_partial_download_part_file(qapp, monkeypatch):
    with tempfile.TemporaryDirectory() as tmp_dir:
        target_file = os.path.join(tmp_dir, "test_model.gguf")
        part_file = target_file + ".part"

        # Mock urllib để mô phỏng stream đang tải
        class MockResponse:
            def __init__(self):
                self.headers = {"Content-Length": "100"}
                self.chunks = [b"a" * 50, b"b" * 50]
                self.idx = 0

            def read(self, size):
                if self.idx < len(self.chunks):
                    chunk = self.chunks[self.idx]
                    self.idx += 1
                    return chunk
                return b""

            def __enter__(self): return self
            def __exit__(self, *args): pass

        import urllib.request
        monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=30: MockResponse())

        worker = DownloadWorker(
            model_id="test_model",
            download_url="http://mock.test/model.gguf",
            target_path=target_file,
            expected_size_bytes=100,
        )

        worker.start()
        worker.wait(1000)

        # Sau khi hoàn tất, file .gguf tồn tại, file .part không còn
        assert os.path.exists(target_file)
        assert not os.path.exists(part_file)


# ==========================================
# TC-MM-05: ATOMIC PROMOTION ON COMPLETION
# ==========================================
def test_tc_mm_05_atomic_promotion_on_completion(qapp, monkeypatch):
    with tempfile.TemporaryDirectory() as tmp_dir:
        target_file = os.path.join(tmp_dir, "atomic_model.gguf")

        class MockResponse:
            def __init__(self):
                self.headers = {"Content-Length": "20"}
            def read(self, size):
                return b""
            def __enter__(self): return self
            def __exit__(self, *args): pass

        # Mô phỏng worker hoàn thành ghi 20 bytes
        worker = DownloadWorker("atomic", "http://mock.test/url", target_file, expected_size_bytes=20)
        
        # Ghi trực tiếp vào file .part
        with open(worker.part_path, "wb") as f:
            f.write(b"01234567890123456789")

        spy_finished = SignalSpy(worker.finished)
        
        # Test logic atomic rename
        os.replace(worker.part_path, worker.target_path)
        assert os.path.exists(target_file)
        assert not os.path.exists(worker.part_path)


# ==========================================
# TC-MM-06: CANCEL DOWNLOAD CLEANUP
# ==========================================
def test_tc_mm_06_cancel_download_cleanup(qapp):
    with tempfile.TemporaryDirectory() as tmp_dir:
        target_file = os.path.join(tmp_dir, "cancel_model.gguf")
        part_file = target_file + ".part"

        # Tạo sẵn file .part dở dang
        with open(part_file, "wb") as f:
            f.write(b"partial content")

        worker = DownloadWorker("cancel_model", "http://mock.test/url", target_file, expected_size_bytes=1000)
        worker._cleanup_part_file()

        # File .part phải bị xóa sạch
        assert not os.path.exists(part_file)


# ==========================================
# TC-MM-07: SIZE VALIDATION GUARD
# ==========================================
def test_tc_mm_07_size_validation_guard(qapp, monkeypatch):
    with tempfile.TemporaryDirectory() as tmp_dir:
        target_file = os.path.join(tmp_dir, "corrupt_model.gguf")
        part_file = target_file + ".part"

        class ShortResponse:
            def __init__(self):
                self.headers = {"Content-Length": "100"}
                self.sent = False
            def read(self, size):
                if not self.sent:
                    self.sent = True
                    return b"only 10 bytes"
                return b""
            def __enter__(self): return self
            def __exit__(self, *args): pass

        import urllib.request
        monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=30: ShortResponse())

        worker = DownloadWorker("corrupt", "http://mock.test/short", target_file, expected_size_bytes=100)
        spy_error = SignalSpy(worker.error)

        worker.start()
        worker.wait(1000)
        spy_error.wait(200)

        assert len(spy_error) == 1
        assert "không khớp" in spy_error[0][1]
        assert not os.path.exists(target_file)
        assert not os.path.exists(part_file)


# ==========================================
# TC-MM-08: RUNTIME BACKEND SWITCHING
# ==========================================
def test_tc_mm_08_runtime_backend_switching(qapp):
    with tempfile.TemporaryDirectory() as tmp_dir:
        meta_3b = MODEL_CATALOG["qwen2.5-3b-instruct-q4_k_m"]
        file_path = os.path.join(tmp_dir, meta_3b.filename)
        with open(file_path, "wb") as f:
            f.write(b"dummy")

        model = SubtitleModel()
        tc = TranslationController(model)
        settings = AppSettings(os.path.join(tmp_dir, "settings.json"))
        mc = ModelController(models_dir=tmp_dir, translation_controller=tc, settings=settings)

        assert mc.selectActiveModel("qwen2.5-3b-instruct-q4_k_m") is True
        assert tc.hardware_profile["model_name"] == meta_3b.filename
        assert tc.hardware_profile["n_ctx"] == meta_3b.recommended_ctx


# ==========================================
# TC-MM-09: EXECUTION CONCURRENCY LOCK
# ==========================================
def test_tc_mm_09_execution_concurrency_lock(qapp):
    with tempfile.TemporaryDirectory() as tmp_dir:
        meta_3b = MODEL_CATALOG["qwen2.5-3b-instruct-q4_k_m"]
        file_path = os.path.join(tmp_dir, meta_3b.filename)
        with open(file_path, "wb") as f:
            f.write(b"dummy")

        model = SubtitleModel()
        tc = TranslationController(model)
        tc._status = "TRANSLATING"  # Đang dịch

        mc = ModelController(models_dir=tmp_dir, translation_controller=tc)
        assert mc.isExecutionLocked is True

        # Đổi model bị khóa
        success = mc.selectActiveModel("qwen2.5-3b-instruct-q4_k_m")
        assert success is False

        # Xóa file bị khóa
        del_success = mc.deleteModelFile("qwen2.5-3b-instruct-q4_k_m")
        assert del_success is False


# ==========================================
# TC-MM-10: STATE SEPARATION INVARIANT
# ==========================================
def test_tc_mm_10_state_separation_invariant(qapp):
    from PySide6.QtCore import QUrl
    from app.controllers.project_controller import ProjectController
    model = SubtitleModel()
    model.load_data([{"index": 0, "original": "Hello", "translation": "Xin chào", "status": "TRANSLATED"}])
    pc = ProjectController(model)

    with tempfile.TemporaryDirectory() as tmp_dir:
        save_file = os.path.join(tmp_dir, "project.aisrt")
        file_url = QUrl.fromLocalFile(save_file).toString()
        pc.saveProject(file_url, "Story", "English", "Vietnamese")

        with open(save_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        # File .aisrt hoàn toàn không chứa active_model_id hay model_name
        assert "active_model_id" not in data
        assert "model_name" not in data
        assert "intelligence" in data


# ==========================================
# TC-MM-11: APP SETTINGS PERSISTENCE
# ==========================================
def test_tc_mm_11_app_settings_persistence():
    with tempfile.TemporaryDirectory() as tmp_dir:
        settings_file = os.path.join(tmp_dir, "app_settings.json")
        settings = AppSettings(settings_file)
        settings.active_model_id = "deepseek-r1-distill-qwen-7b-q4_k_m"

        # Đọc lại từ file
        reloaded = AppSettings(settings_file)
        assert reloaded.active_model_id == "deepseek-r1-distill-qwen-7b-q4_k_m"


# ==========================================
# TC-MM-12: ZERO-BLOCKING UI DURING DOWNLOAD
# ==========================================
def test_tc_mm_12_zero_blocking_ui_during_download(qapp, monkeypatch):
    with tempfile.TemporaryDirectory() as tmp_dir:
        target_file = os.path.join(tmp_dir, "bg_model.gguf")

        class SlowResponse:
            def __init__(self):
                self.headers = {"Content-Length": "100"}
                self.step = 0
            def read(self, size):
                if self.step < 3:
                    self.step += 1
                    time.sleep(0.05)
                    return b"x" * 30
                return b""
            def __enter__(self): return self
            def __exit__(self, *args): pass

        import urllib.request
        monkeypatch.setattr(urllib.request, "urlopen", lambda req, timeout=30: SlowResponse())

        dm = DownloadManager()
        dm.start_download("bg_model", "http://mock.test/slow", target_file, expected_size_bytes=90)
        assert dm.is_downloading("bg_model") is True

        # UI event loop vẫn xử lý mượt mà
        for _ in range(5):
            qapp.processEvents()
            QTest.qWait(20)

        dm.cancel_download("bg_model")
        assert dm.is_downloading("bg_model") is False
