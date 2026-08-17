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
    print("\n" + "="*55)
    print(" 🖥️  AI SUBTITLE TRANSLATOR - RUNTIME VERIFICATION")
    print("="*55)
    print(f"[*] Hardware Detected : {gpu_info['name']} ({gpu_info['vram_gb']:.1f} GB VRAM)")
    print(f"[*] Llama.cpp Backend : {profile['backend_status']}")
    print(f"[*] Target Model File : {profile['model_name']}")
    print(f"[*] Context (n_ctx)   : {profile['n_ctx']}")
    print(f"[*] GPU Layers        : {profile['n_gpu_layers']}")
    print("="*55 + "\n")

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