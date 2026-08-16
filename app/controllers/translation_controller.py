from PySide6.QtCore import QObject, Slot, Signal, Property
from app.llm.worker import TranslationWorker
from app.core.context_engine import ContextEngine
from app.core.prompt_builder import PromptBuilder
from app.core.hardware_detector import HardwareDetector # IMPORT MỚI

class TranslationController(QObject):
    statusChanged = Signal(str)
    translationUpdated = Signal(str)

    def __init__(self, subtitle_model):
        super().__init__()
        self._status = "PENDING"
        self._current_translation = ""
        self._subtitle_model = subtitle_model
        self.worker = None
        # NẠP PROFILE TỪ LÚC BOOT
        self.hardware_profile = HardwareDetector.get_recommended_profile()

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(str, notify=translationUpdated)
    def currentTranslation(self):
        return self._current_translation

    @Slot(int)
    def loadSubtitle(self, index):
        if index < 0: return
        subtitles = self._subtitle_model.get_all_data()
        if index >= len(subtitles): return
        sub = subtitles[index]
        
        if sub["status"] == "ACCEPTED":
            self._current_translation = sub["translation"]
            self._status = "ACCEPTED"
        else:
            self._current_translation = sub["original"]
            self._status = "PENDING"
            
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(self._current_translation)

    # --- HÀM MỚI: TRIGGER STATE 'EDITED' KHI USER TỰ GÕ ---
    @Slot()
    def markAsEdited(self):
        if self._status in ["PENDING", "TRANSLATED", "ACCEPTED"]:
            self._status = "EDITED"
            self.statusChanged.emit(self._status)

    @Slot(int, str, str, str)
    def requestTranslation(self, index, source_lang, target_lang, story_summary):
        if self.worker and self.worker.isRunning():
            self.worker.cancel()
            self.worker.wait()

        self._status = "TRANSLATING"
        self.statusChanged.emit(self._status)
        self._current_translation = ""
        self.translationUpdated.emit("")

        subtitles = self._subtitle_model.get_all_data()
        prev_ctx, current, next_ctx = ContextEngine.get_context(subtitles, index)
        prompt = PromptBuilder.build(story_summary, source_lang, target_lang, prev_ctx, current, next_ctx)

        # TRUYỀN PROFILE XUỐNG WORKER
        self.worker = TranslationWorker(prompt, self.hardware_profile)
        self.worker.progress.connect(self.on_progress)
        self.worker.finished.connect(self.on_finished)
        self.worker.error.connect(self.on_error)
        self.worker.start()

    @Slot(str)
    def on_progress(self, text):
        self._current_translation = text
        self.translationUpdated.emit(text)

    @Slot(str)
    def on_finished(self, text):
        self._current_translation = text
        self._status = "TRANSLATED"
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(text)

    @Slot(str)
    def on_error(self, err_msg):
        self._status = "ERROR"
        self._current_translation = f"Lỗi: {err_msg}"
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(self._current_translation)

    @Slot(int, str)
    def acceptTranslation(self, index, final_text):
        """Kiểm tra chặt chẽ ở backend trước khi chấp nhận bản dịch"""
        subtitles = self._subtitle_model.get_all_data()
        if 0 <= index < len(subtitles):
            original = subtitles[index].get("original", "").strip()
            clean_text = final_text.strip()
            
            if not clean_text:
                self.statusChanged.emit("ERROR")
                self.translationUpdated.emit("Lỗi: Không thể chấp nhận bản dịch trống!")
                return
                
            if clean_text == original:
                self.statusChanged.emit("ERROR")
                self.translationUpdated.emit("Lỗi: Bản dịch không được trùng với văn bản gốc!")
                return

        # Nếu vượt qua kiểm tra, tiến hành lưu vào Model
        self._subtitle_model.update_translation(index, final_text, "ACCEPTED")
        self._status = "ACCEPTED"
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(final_text)