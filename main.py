import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

from app.models.subtitle import SubtitleModel
from app.core.srt_parser import SRTParser
from app.controllers.translation_controller import TranslationController # THÊM DÒNG NÀY
from app.controllers.project_controller import ProjectController # THÊM DÒNG NÀY

def create_dummy_srt():
    """Tạo file SRT mẫu để test nếu chưa có"""
    if not os.path.exists("test.srt"):
        with open("test.srt", "w", encoding="utf-8") as f:
            f.write("1\n00:00:01,000 --> 00:00:03,000\nI finally came back.\n\n")
            f.write("2\n00:00:03,500 --> 00:00:05,500\nYou really took your time.\n\n")
            f.write("3\n00:00:06,000 --> 00:00:08,000\nYes, there were some complications.\n")

def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # 1. Khởi tạo Data Model
    subtitle_model = SubtitleModel()

    # 2. Tạo file mẫu và parse dữ liệu
    create_dummy_srt()
    parsed_data = SRTParser.parse("test.srt")
    
    # 3. Nạp dữ liệu vào Model
    subtitle_model.load_data(parsed_data)

    # TẠO CONTROLLER VÀ ĐẨY SANG QML
    translation_controller = TranslationController(subtitle_model)
    engine.rootContext().setContextProperty("translationController", translation_controller)
    
    # ---- THÊM 2 DÒNG NÀY ----
    project_controller = ProjectController(subtitle_model)
    engine.rootContext().setContextProperty("projectController", project_controller)
    # -------------------------

    # 4. Expose model sang QML
    engine.rootContext().setContextProperty("subtitleModel", subtitle_model)

    # 5. Load giao diện
    qml_file = os.path.join(os.path.dirname(__file__), "ui/qml/Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
