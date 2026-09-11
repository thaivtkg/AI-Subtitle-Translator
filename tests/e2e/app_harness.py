from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from app.controllers.project_controller import ProjectController
from app.controllers.translation_controller import TranslationController
from app.core.hardware_detector import HardwareDetector
from app.core.srt_parser import SRTParser
from app.models.subtitle import SubtitleModel

from .user_driver import UserDriver


class AppHarness:
    def __init__(self, fixture_path):
        self.app = QGuiApplication.instance() or QGuiApplication([])
        QQuickStyle.setStyle("Basic")
        self.engine = QQmlApplicationEngine()
        self.model = SubtitleModel()
        self.model.load_data(SRTParser.parse(str(fixture_path)))

        original_profile = HardwareDetector.get_recommended_profile
        HardwareDetector.get_recommended_profile = staticmethod(lambda: {
            "gpu_info": {"name": "T15 test", "vram_gb": 0.0},
            "backend_status": "T15 test profile",
            "model_name": "missing-test-model.gguf",
            "n_ctx": 2048,
            "n_gpu_layers": 0,
        })
        try:
            self.translation_controller = TranslationController(self.model)
        finally:
            HardwareDetector.get_recommended_profile = original_profile

        self.project_controller = ProjectController(self.model)
        self.engine.rootContext().setContextProperty("translationController", self.translation_controller)
        self.engine.rootContext().setContextProperty("projectController", self.project_controller)
        self.engine.rootContext().setContextProperty("subtitleModel", self.model)

        qml_file = Path(__file__).parents[2] / "ui" / "qml" / "Main.qml"
        self.engine.load(QUrl.fromLocalFile(str(qml_file)))
        roots = self.engine.rootObjects()
        if not roots:
            raise RuntimeError(f"Could not load QML root: {qml_file}")
        self.window = roots[0]
        self.window.show()
        self.app.processEvents()
        self.driver = UserDriver(self.window)

    def close(self):
        if self.window is not None:
            self.window.close()
        self.app.processEvents()
