import os
import sys

# Ensure UTF-8 output on Windows consoles to prevent UnicodeEncodeError
if sys.platform == "win32":
    if sys.stdout and hasattr(sys.stdout, "reconfigure"):
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
    if sys.stderr and hasattr(sys.stderr, "reconfigure"):
        try:
            sys.stderr.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from app.core.runtime_check import verify_environment

# Pre-flight check before importing any C-extensions / PySide6 / llama_cpp
if not verify_environment(interactive="--smoke-test" not in sys.argv):
    print("[FATAL] VC++ Redistributable check failed.", file=sys.stderr)
    sys.exit(1)

# Configure llama.cpp library path for PyInstaller frozen environment
if getattr(sys, "frozen", False):
    base_dir = getattr(sys, "_MEIPASS", os.path.dirname(sys.executable))
    exe_dir = os.path.dirname(sys.executable)
    for candidate in [
        os.path.join(base_dir, "llama_cpp", "lib"),
        os.path.join(base_dir, "_internal", "llama_cpp", "lib"),
        os.path.join(exe_dir, "llama_cpp", "lib"),
        os.path.join(exe_dir, "_internal", "llama_cpp", "lib"),
    ]:
        if os.path.isdir(candidate):
            os.environ["LLAMA_CPP_LIB_PATH"] = candidate
            if sys.platform == "win32":
                try:
                    os.add_dll_directory(candidate)
                except Exception:
                    pass
                os.environ["PATH"] = candidate + os.pathsep + os.environ.get("PATH", "")
            break

from uuid import uuid4
from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtQuickControls2 import QQuickStyle

# Bật kênh trong suốt phần cứng cho cửa sổ không viền trên Windows
QQuickWindow.setDefaultAlphaBuffer(True)

from app.models.subtitle import SubtitleModel, FilteredSubtitleModel
from app.core.srt_parser import SRTParser
from app.controllers.translation_controller import TranslationController
from app.controllers.project_controller import ProjectController
from app.controllers.batch_controller import BatchController
from app.controllers.batch_runtime_bridge import BatchRuntimeBridge
from app.controllers.model_controller import ModelController
from app.core.hardware_detector import HardwareDetector
from app.core.app_settings import AppSettings

def main():
    QQuickStyle.setStyle("Basic")
    QQuickWindow.setDefaultAlphaBuffer(True)
    app = QGuiApplication(sys.argv)

    
    engine = QQmlApplicationEngine()

    profile = HardwareDetector.get_recommended_profile()
    gpu_info = profile['gpu_info']
    print("\n" + "="*55)
    print(" [*] AI SUBTITLE TRANSLATOR - RUNTIME VERIFICATION")
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

    batch_runtime = BatchRuntimeBridge(translation_controller)
    batch_controller = BatchController(
        subtitle_model,
        batch_runtime,
        project_id=f"runtime-{uuid4()}",
    )
    engine.rootContext().setContextProperty("batchController", batch_controller)
    
    project_controller = ProjectController(subtitle_model)
    engine.rootContext().setContextProperty("projectController", project_controller)

    # Gắn (bind) dữ liệu ngữ cảnh vào luồng dịch thuật
    translation_controller.bind_intelligence(
        glossary=project_controller.glossary,
        entities=project_controller.entity_dictionary,
        translation_memory=project_controller.translation_memory,
        project_controller=project_controller,
    )
    project_controller.bind_translation_controller(translation_controller)

    if getattr(sys, "frozen", False):
        base_dir = getattr(sys, "_MEIPASS", os.path.dirname(sys.executable))
        exe_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        exe_dir = base_dir

    models_dir = os.path.join(exe_dir, "models")
    os.makedirs(models_dir, exist_ok=True)

    settings_file = os.path.join(exe_dir, "app_settings.json")
    if not os.path.exists(settings_file) and getattr(sys, "frozen", False):
        bundled_settings = os.path.join(base_dir, "app_settings.json")
        if os.path.exists(bundled_settings):
            import shutil
            try:
                shutil.copy2(bundled_settings, settings_file)
            except Exception:
                pass

    model_controller = ModelController(
        models_dir=models_dir,
        translation_controller=translation_controller,
        batch_controller=batch_controller,
        settings=AppSettings(file_path=settings_file),
    )
    engine.rootContext().setContextProperty("modelController", model_controller)
    
    filtered_subtitle_model = FilteredSubtitleModel(subtitle_model)
    engine.rootContext().setContextProperty("filteredSubtitleModel", filtered_subtitle_model)
    engine.rootContext().setContextProperty("subtitleModel", subtitle_model)

    qml_file = os.path.join(base_dir, "ui", "qml", "Main.qml")
    if not os.path.exists(qml_file):
        alt_qml = os.path.join(exe_dir, "ui", "qml", "Main.qml")
        if os.path.exists(alt_qml):
            qml_file = alt_qml
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        print("[FATAL] QML Engine failed to load root objects.", file=sys.stderr)
        sys.exit(-1)

    if "--smoke-test" in sys.argv:
        print("[SMOKE TEST] Application initialized successfully. Root objects verified.")
        sys.exit(0)

    # Đưa cửa sổ lên trên cùng để người dùng thấy ngay lập tức
    root_window = engine.rootObjects()[0]
    root_window.show()
    root_window.raise_()
    root_window.requestActivate()

    # Flush stdout để không bị nghẽn log
    sys.stdout.flush()

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
