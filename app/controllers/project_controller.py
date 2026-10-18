import os
import json
import time
from uuid import uuid4
from PySide6.QtCore import QObject, Slot, Signal, Property, QUrl
from app.core.srt_exporter import SRTExporter
from app.core.srt_parser import SRTParser
from app.core.srt_validator import SRTValidator
from app.core.glossary import Glossary
from app.core.entity_dictionary import EntityDictionary
from app.core.translation_memory import TranslationMemory

def _normalize_file_path(url_or_path: str) -> str:
    if not url_or_path:
        return ""
    if url_or_path.startswith("file:"):
        local = QUrl(url_or_path).toLocalFile()
        return local if local else url_or_path
    return url_or_path

class ProjectController(QObject):
    notify = Signal(str, str)
    projectStateChanged = Signal()
    # Tín hiệu để gửi Story Summary từ file JSON ngược lên giao diện QML
    projectLoaded = Signal(str) 
    # TÍN HIỆU MỚI: Bắn ngôn ngữ nguồn lên UI
    languageLoaded = Signal(str)
    # Tín hiệu xác nhận xuất file khi tồn tại lỗi QA nghiêm trọng
    qaExportWarningRequired = Signal(str, int)

    def __init__(self, subtitle_model):
        super().__init__()
        self._subtitle_model = subtitle_model
        self._original_source_file = "unknown.srt"
        self._has_project = False
        self._is_dirty = False
        self._loading_project = False
        self.glossary = Glossary()
        self.entity_dictionary = EntityDictionary()
        self.translation_memory = TranslationMemory()
        self._subtitle_model.dataChanged.connect(self._on_model_changed)
        self._subtitle_model.modelReset.connect(self.projectStateChanged.emit)
        self._subtitle_model.rowsInserted.connect(self.projectStateChanged.emit)
        self._subtitle_model.rowsRemoved.connect(self.projectStateChanged.emit)

    @Property(bool, notify=projectStateChanged)
    def hasProject(self):
        return self._has_project or (self._subtitle_model is not None and self._subtitle_model.rowCount() > 0)

    @Property(bool, notify=projectStateChanged)
    def isDirty(self):
        return self._is_dirty

    def _set_project_state(self, has_project, is_dirty):
        if self._has_project == has_project and self._is_dirty == is_dirty:
            return
        self._has_project = has_project
        self._is_dirty = is_dirty
        self.projectStateChanged.emit()

    def _on_model_changed(self, *args):
        self.markDirty()

    @Slot()
    def markDirty(self):
        if self._loading_project or not self._has_project:
            return
        self._set_project_state(True, True)

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
    @Slot(str, bool)
    def exportSrt(self, file_path, force=False):
        """DEFENSE-IN-DEPTH: Bắt buộc validate bên trong backend trước khi ghi file"""
        file_path = _normalize_file_path(file_path)

        subtitles = self._subtitle_model.get_all_data()
        
        # KIỂM TRA TÍNH TOÀN VỆN NGAY TẠI LÕI
        is_valid, val_msg = SRTValidator.validate_for_export(subtitles)
        if not is_valid:
            self.notify.emit("ERROR", f"Lỗi xuất file: {val_msg}")
            return
            
        # ADVISORY QA CHECK: Nếu có lỗi đỏ và người dùng chưa bấm Force, yêu cầu xác nhận
        if not force:
            error_count = sum(1 for sub in subtitles if sub.get("_qa_severity") == "ERROR")
            if error_count > 0:
                self.qaExportWarningRequired.emit(file_path, error_count)
                return

        success, msg = SRTExporter.export(subtitles, file_path)
        if success:
            self.notify.emit("SUCCESS", msg)
        else:
            self.notify.emit("ERROR", msg)

    @Slot(str)
    def importSrt(self, file_url):
        file_path = _normalize_file_path(file_url)
        if not os.path.exists(file_path):
            self.notify.emit("ERROR", "Không tìm thấy file SRT!")
            return
            
        # FIX: Ghi nhận chính xác tên file gốc lúc import
        self._original_source_file = os.path.basename(file_path)
        
        parsed_data = SRTParser.parse(file_path)
        if not parsed_data:
            self.notify.emit("ERROR", "Không thể đọc nội dung file SRT hoặc file rỗng!")
            return
            
        # 1. Nạp dữ liệu mới vào Model
        self._subtitle_model.load_data(parsed_data)
        self._set_project_state(True, True)
        
        # 2. Reset trạng thái giao diện để tránh kẹt dữ liệu cũ
        self.projectLoaded.emit("")          # Xóa Story Summary cũ
        self.languageLoaded.emit("English") # Đưa dropdown về mặc định
        self.notify.emit("SUCCESS", f"Đã tải {len(parsed_data)} câu từ SRT: {self._original_source_file}")

    # ---- BỔ SUNG 2 HÀM LƯU VÀ MỞ PROJECT ----
    @Slot(str, str, str, str)
    def saveProject(self, file_url, story_summary, source_lang="English", target_lang="Vietnamese"):
        file_path = _normalize_file_path(file_url)

        if not file_path.endswith('.aisrt'):
            file_path += '.aisrt'
            
        clean_subtitles = [
            {k: v for k, v in sub.items() if not k.startswith("_")}
            for sub in self._subtitle_model.get_all_data()
        ]

        data = {
            "metadata": {
                # FIX: Dùng biến state đã lưu, không tự đoán từ file_path
                "source_file": getattr(self, "_original_source_file", "unknown.srt"),
                "source_language": source_lang,
                "target_language": target_lang,
                "version": "1.0"
            },
            "story_summary": story_summary,
            "subtitles": clean_subtitles,
            "intelligence": {
                "glossary": self.glossary.to_payload(),
                "entities": self.entity_dictionary.to_payload(),
                "translation_memory": self.translation_memory.to_payload(),
            },
        }
        # Log tổng hợp 1 dòng duy nhất thay vì vòng lặp 2.000 dòng gây đơ UI
        print(f"[PROJECT_SAVE] Saving {len(clean_subtitles)} subtitles to {os.path.basename(file_path)}")

        temp_path = f"{file_path}.{uuid4().hex[:8]}.tmp"
        try:
            # Bước 1: Ghi vào file tạm, ép flush + fsync xuống đĩa cứng
            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.flush()
                os.fsync(f.fileno())

            # Bước 2: Đã đóng file descriptor, thực hiện atomic replace có retry chống Windows Defender lock
            last_err = None
            for attempt in range(3):
                try:
                    os.replace(temp_path, file_path)
                    last_err = None
                    break
                except PermissionError as perm_err:
                    last_err = perm_err
                    time.sleep(0.05)
            if last_err is not None:
                raise last_err

            self._set_project_state(True, False)
            self.notify.emit("SUCCESS", f"Đã lưu dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi lưu dự án: {str(e)}")
        finally:
            # Bước 3: Dọn dẹp file .tmp rác nếu quá trình lưu gặp sự cố
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

    @Slot(str)
    def loadProject(self, file_url):
        file_path = _normalize_file_path(file_url)
        if not os.path.exists(file_path):
            self.notify.emit("ERROR", "Không tìm thấy file dự án!")
            return
            
        self._loading_project = True
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            loaded_glossary = self._load_glossary(data)
            loaded_entities = self._load_entities(data)
            loaded_tm = self._load_translation_memory(data)

            subtitles = data.get("subtitles", [])
            self._subtitle_model.load_data(subtitles)
            self.glossary = loaded_glossary
            self.entity_dictionary = loaded_entities
            self.translation_memory = loaded_tm
            print(f"[PROJECT_LOAD] Loaded {len(subtitles)} subtitles from {os.path.basename(file_path)}")
            self.projectLoaded.emit(data.get("story_summary", ""))
            
            # --- ĐOẠN ĐÃ SỬA: DỌN DẸP DUPLICATE EMIT ---
            metadata = data.get("metadata", {})
            self._original_source_file = metadata.get("source_file", "unknown.srt")
            source_lang = metadata.get("source_language", "English")
            
            self.languageLoaded.emit(source_lang) # Chỉ emit 1 lần duy nhất
            # -------------------------------------------

            self._set_project_state(True, False)
            self.notify.emit("SUCCESS", f"Đã mở dự án: {os.path.basename(file_path)}")
        except Exception as e:
            self.notify.emit("ERROR", f"Lỗi mở dự án: {str(e)}")
        finally:
            self._loading_project = False

    @staticmethod
    def _load_glossary(data):
        if "intelligence" not in data:
            return Glossary()
        intelligence = data["intelligence"]
        if not isinstance(intelligence, dict):
            raise ValueError("Invalid intelligence data")
        if "glossary" not in intelligence:
            return Glossary()
        return Glossary.from_payload(intelligence["glossary"])

    @staticmethod
    def _load_entities(data):
        if "intelligence" not in data:
            return EntityDictionary()
        intelligence = data["intelligence"]
        if not isinstance(intelligence, dict):
            raise ValueError("Invalid intelligence data")
        if "entities" not in intelligence:
            return EntityDictionary()
        return EntityDictionary.from_payload(intelligence["entities"])

    @staticmethod
    def _load_translation_memory(data):
        if "intelligence" not in data:
            return TranslationMemory()
        intelligence = data["intelligence"]
        if not isinstance(intelligence, dict):
            raise ValueError("Invalid intelligence data")
        if "translation_memory" not in intelligence:
            return TranslationMemory()
        return TranslationMemory.from_payload(intelligence["translation_memory"])
