import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

from app.models.subtitle import SubtitleModel
from app.core.srt_parser import SRTParser
from app.controllers.translation_controller import TranslationController
from app.controllers.project_controller import ProjectController
from app.core.hardware_detector import HardwareDetector

def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    profile = HardwareDetector.get_recommended_profile()
    gpu_info = profile['gpu_info']
    print("\n" + "="*50)
    print(" 🖥️  AI SUBTITLE TRANSLATOR - HARDWARE PROFILE")
    print("="*50)
    print(f"[*] GPU Name      : {gpu_info['name']}")
    print(f"[*] VRAM Available: {gpu_info['vram_gb']:.1f} GB")
    print(f"[*] Target Model  : {profile['model_name']}")
    print(f"[*] GPU Layers    : {profile['n_gpu_layers']}")
    print("="*50 + "\n")

    subtitle_model = SubtitleModel()
    
    # ĐÃ XÓA DUMMY DATA. APP BẮT ĐẦU VỚI PROJECT TRỐNG.
    
    translation_controller = TranslationController(subtitle_model)
    engine.rootContext().setContextProperty("translationController", translation_controller)
    
    project_controller = ProjectController(subtitle_model)
    engine.rootContext().setContextProperty("projectController", project_controller)
    
    engine.rootContext().setContextProperty("subtitleModel", subtitle_model)

    qml_file = os.path.join(os.path.dirname(__file__), "ui/qml/Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()