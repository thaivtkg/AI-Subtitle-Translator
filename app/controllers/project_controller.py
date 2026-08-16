import os
import json
from PySide6.QtCore import QObject, Slot, Signal, QUrl
from app.core.srt_exporter import SRTExporter
from app.core.srt_parser import SRTParser
from app.core.srt_validator import SRTValidator

class ProjectController(QObject):
    notify = Signal(str, str)
    # Tín hiệu để gửi Story Summary từ file JSON ngược lên giao diện QML
    projectLoaded = Signal(str) 

    def __init__(self, subtitle_model):
        super().__init__()
        self._subtitle_model = subtitle_model

    @Slot(result=bool)
    def validateBeforeExport(self):
        """Hàm này sẽ được QML gọi ĐẦU TIÊN khi bấm nút Xuất SRT"""
        subtitles = self._subtitle_model.get_all_data()
        is_valid, val_msg = SRTValidator.validate_for_export(subtitles)
        if not is_valid:
            self.notify.emit("ERROR", f"Lỗi Validator: {val_msg}")
            return False
        return True
    
    @Slot(str)
    def exportSrt(self, file_path):
        """DEFENSE-IN-DEPTH: Bắt buộc validate bên trong backend trước khi ghi file"""
        subtitles = self._subtitle_model.get_all_data()
        
        # KIỂM TRA TÍNH TOÀN VỆN NGAY TẠI LÕI
        is_valid, val_msg = SRTValidator.validate_for_export(subtitles)
        if not is_valid:
            self.notify.emit("ERROR", f"Lỗi xuất file: {val_msg}")
            return
            
        if file_path.startswith("file:///"):
            file_path = QUrl(file_path).toLocalFile()
            
        success, msg = SRTExporter.export(subtitles, file_path)
        if success:
            self.notify.emit("SUCCESS", msg)
        else:
            self.notify.emit("ERROR", msg)

    @Slot(str)
    def importSrt(self, file_url):
        file_path = QUrl(file_url).toLocalFile()
        if not os.path.exists(file_path):
            self.notify.emit("ERROR", "Không tìm thấy file!")
            return
            
        parsed_data = SRTParser.parse(file_path)
        if not parsed_data:
            self.notify.emit("ERROR", "File SRT bị lỗi hoặc trống!")
            return
            
        self._subtitle_model.load_data(parsed_data)
        self.notify.emit("SUCCESS", f"Đã tải {len(parsed_data)} câu từ SRT: {os.path.basename(file_path)}")

    # ---- BỔ SUNG 2 HÀM LƯU VÀ MỞ PROJECT ----
    @Slot(str, str)
    def saveProject(self, file_url, story_summary):
        """Lưu toàn bộ Model và Context vào file .aisrt (JSON)"""
        file_path = QUrl(file_url).toLocalFile()
        if not file_path.endswith('.aisrt'):
            file_path += '.aisrt'
            
        data = {
            "story_summary": story_summary,
            "subtitles": self._subtitle_model.get_all_data()
        }
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            self.notify.emit("SUCCESS", f"Đã lưu dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi lưu dự án: {str(e)}")

    @Slot(str)
    def loadProject(self, file_url):
        """Đọc file .aisrt và khôi phục trạng thái làm việc"""
        file_path = QUrl(file_url).toLocalFile()
        if not os.path.exists(file_path):
            self.notify.emit("ERROR", "Không tìm thấy file dự án!")
            return
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Khôi phục dữ liệu
            self._subtitle_model.load_data(data.get("subtitles", []))
            
            # Phát tín hiệu lên QML để khôi phục chữ trong ô Story Summary
            self.projectLoaded.emit(data.get("story_summary", ""))
            self.notify.emit("SUCCESS", f"Đã mở dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi mở dự án: {str(e)}")