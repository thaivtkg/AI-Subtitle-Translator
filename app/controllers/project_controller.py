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
    # TÍN HIỆU MỚI: Bắn ngôn ngữ nguồn lên UI
    languageLoaded = Signal(str)

    def __init__(self, subtitle_model):
        super().__init__()
        self._subtitle_model = subtitle_model
        self._original_source_file = "unknown.srt"

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
            self.notify.emit("ERROR", "Không tìm thấy file SRT!")
            return
            
        self._original_source_file = os.path.basename(file_path)
        
        parsed_data = SRTParser.parse(file_path)
        if not parsed_data:
            self.notify.emit("ERROR", "Không thể đọc nội dung file SRT hoặc file rỗng!")
            return
            
        # 1. Nạp dữ liệu mới vào Model
        self._subtitle_model.load_data(parsed_data)
        
        # 2. Reset trạng thái giao diện để tránh kẹt dữ liệu cũ
        self.projectLoaded.emit("")          # Xóa Story Summary cũ
        self.languageLoaded.emit("English") # Đưa dropdown về mặc định
        self.notify.emit("SUCCESS", f"Đã tải {len(parsed_data)} câu từ SRT: {self._original_source_file}")

    # ---- BỔ SUNG 2 HÀM LƯU VÀ MỞ PROJECT ----
    @Slot(str, str, str, str)
    def saveProject(self, file_url, story_summary, source_lang="English", target_lang="Vietnamese"):
        file_path = QUrl(file_url).toLocalFile()
        if not file_path.endswith('.aisrt'):
            file_path += '.aisrt'
            
        data = {
            "metadata": {
                # SỬA LẠI: Dùng biến đã lưu thay vì tự chế tên file
                "source_file": self._original_source_file, 
                "source_language": source_lang,
                "target_language": target_lang,
                "version": "1.0"
            },
            "story_summary": story_summary,
            "subtitles": self._subtitle_model.get_all_data()
        }
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                import json
                json.dump(data, f, ensure_ascii=False, indent=2)
            self.notify.emit("SUCCESS", f"Đã lưu dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi lưu dự án: {str(e)}")

    @Slot(str)
    def loadProject(self, file_url):
        file_path = QUrl(file_url).toLocalFile()
        if not os.path.exists(file_path):
            self.notify.emit("ERROR", "Không tìm thấy file dự án!")
            return
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            self._subtitle_model.load_data(data.get("subtitles", []))
            
            # Khôi phục Story Summary
            self.projectLoaded.emit(data.get("story_summary", ""))
            
            # --- PHASE 1.6: KHÔI PHỤC NGÔN NGỮ NGUỒN ---
            metadata = data.get("metadata", {})
            source_lang = metadata.get("source_language", "English")
            self.languageLoaded.emit(source_lang)
            # ------------------------------------------

            self.notify.emit("SUCCESS", f"Đã mở dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi mở dự án: {str(e)}")