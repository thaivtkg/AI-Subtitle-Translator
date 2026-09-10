from PySide6.QtCore import QObject, Slot, Signal, Property
from app.llm.worker import TranslationWorker
from app.core.context_engine import ContextEngine
from app.core.prompt_builder import PromptBuilder
from app.core.hardware_detector import HardwareDetector

class TranslationController(QObject):
    statusChanged = Signal(str)
    translationUpdated = Signal(str)
    notify = Signal(str, str)
    contextUpdated = Signal() # TÍN HIỆU MỚI CHO CONTEXT
    progressChanged = Signal()
    engineStatusChanged = Signal(str)

    def __init__(self, subtitle_model):
        super().__init__()
        self._status = "PENDING"
        self._engine_status = "Not loaded"
        self._active_translation_index = -1
        self._current_translation = ""
        self._current_original = ""
        self._context_prev = "" # LƯU CONTEXT TRƯỚC
        self._context_next = "" # LƯU CONTEXT SAU
        
        self._subtitle_model = subtitle_model
        self.worker = None
        self.hardware_profile = HardwareDetector.get_recommended_profile()
        self._subtitle_model.modelReset.connect(self._emit_progress)
        self._subtitle_model.dataChanged.connect(self._emit_progress)

    @Property(int, notify=progressChanged)
    def totalSubtitleCount(self):
        return len(self._subtitle_model.get_all_data())

    @Property(int, notify=progressChanged)
    def acceptedCount(self):
        return sum(1 for sub in self._subtitle_model.get_all_data() if str(sub.get("status", "")).upper() == "ACCEPTED")

    def _emit_progress(self, *args):
        self.progressChanged.emit()

    @Property(str, notify=engineStatusChanged)
    def engineStatus(self):
        return self._engine_status

    def _set_engine_status(self, status):
        if self._engine_status != status:
            self._engine_status = status
            self.engineStatusChanged.emit(status)

    @Property(str, notify=statusChanged)
    def status(self): return self._status

    @Property(str, notify=translationUpdated)
    def currentTranslation(self): return self._current_translation

    @Property(str, notify=translationUpdated)
    def currentOriginal(self): return self._current_original

    # EXPOSE CONTEXT RA QML
    @Property(str, notify=contextUpdated)
    def contextPrev(self): return self._context_prev

    @Property(str, notify=contextUpdated)
    def contextNext(self): return self._context_next

    @Slot(int)
    def loadSubtitle(self, index):
        if index < 0: 
            self._current_original = ""
            self._current_translation = ""
            self._context_prev = ""
            self._context_next = ""
            self._status = "PENDING"
            self.statusChanged.emit(self._status)
            self.translationUpdated.emit(self._current_translation)
            self.contextUpdated.emit()
            return
            
        subtitles = self._subtitle_model.get_all_data()
        if index >= len(subtitles): return
        sub = subtitles[index]
        
        self._current_original = sub.get("original", "")
        status = str(sub.get("status", "PENDING")).upper()
        
        if status in ["ACCEPTED", "EDITED", "TRANSLATED", "TRANSLATING", "ERROR"]:
            self._current_translation = sub.get("translation", "")
        else:
            self._current_translation = ""
            
        self._status = "TRANSLATING" if index == self._active_translation_index else status
        
        # TRÍCH XUẤT CONTEXT ĐỂ HIỂN THỊ LÊN UI
        prev_ctx, _, next_ctx = ContextEngine.get_context(subtitles, index)
        self._context_prev = "\n\n".join(prev_ctx) if prev_ctx else "Không có dữ liệu trước."
        self._context_next = "\n\n".join(next_ctx) if next_ctx else "Không có dữ liệu sau."
        
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(self._current_translation)
        self.contextUpdated.emit()

    @Slot()
    def markAsEdited(self):
        if self._status in ["PENDING", "TRANSLATED", "ACCEPTED"]:
            self._status = "EDITED"
            self.statusChanged.emit(self._status)

    @Slot(int, str, str, str)
    def requestTranslation(self, index, source_lang, target_lang, story_summary):
        if index < 0 or index >= len(self._subtitle_model.get_all_data()):
            return
        if self.worker and self.worker.isRunning():
            return

        self._active_translation_index = index
        self._status = "TRANSLATING"
        self._set_engine_status("Translating")
        self.statusChanged.emit(self._status)
        self._current_translation = ""
        self.translationUpdated.emit("")
        self._subtitle_model.update_translation(index, "", "TRANSLATING")

        subtitles = self._subtitle_model.get_all_data()
        prev_ctx, current, next_ctx = ContextEngine.get_context(subtitles, index)
        prompt = PromptBuilder.build(story_summary, source_lang, target_lang, prev_ctx, current, next_ctx)

        self.worker = TranslationWorker(index, prompt, self.hardware_profile)
        self.worker.progress.connect(self.on_progress)
        self.worker.finished.connect(self.on_finished)
        self.worker.error.connect(self.on_error)
        self.worker.start()

    @Slot(int, str)
    def on_progress(self, index, text):
        sender = self.sender()
        if sender is not None and sender is not self.worker:
            return
        self._subtitle_model.update_translation(index, text, "TRANSLATING")
        if index == self._active_translation_index:
            self._current_translation = text
            self._status = "TRANSLATING"
            self.translationUpdated.emit(text)

    @Slot(int, str)
    def on_finished(self, index, text):
        sender = self.sender()
        if sender is not None and sender is not self.worker:
            return
        clean_text = (text or "").strip()
        print(
            f"[TRANSLATION_CALLBACK] target={index} "
            f"clean_len={len(clean_text)} clean_text={clean_text!r} "
            f"active_target={self._active_translation_index} "
            f"controller_status_before={self._status} "
            f"current_translation_before={self._current_translation!r}",
            flush=True,
        )
        if not clean_text:
            message = "Lỗi: Model trả về bản dịch rỗng."
            self._subtitle_model.update_translation(index, message, "ERROR")
            if index == self._active_translation_index:
                self._status = "ERROR"
                self._current_translation = message
                self.statusChanged.emit(self._status)
                self.translationUpdated.emit(message)
                self._active_translation_index = -1
            self._set_engine_status("Error")
            return

        self._subtitle_model.update_translation(index, clean_text, "TRANSLATED")
        if index == self._active_translation_index:
            self._current_translation = clean_text
            self._status = "TRANSLATED"
            self.statusChanged.emit(self._status)
            self.translationUpdated.emit(clean_text)
            self._active_translation_index = -1
        print(
            f"[TRANSLATION_CALLBACK_AFTER] target={index} "
            f"controller_status={self._status} "
            f"current_translation_len={len(self._current_translation)} "
            f"current_translation={self._current_translation!r} "
            f"active_target={self._active_translation_index}",
            flush=True,
        )
        self._set_engine_status("Ready")

    @Slot(int, str)
    def on_error(self, index, err_msg):
        sender = self.sender()
        if sender is not None and sender is not self.worker:
            return
        message = f"Lỗi: {err_msg}"
        self._subtitle_model.update_translation(index, message, "ERROR")
        if index == self._active_translation_index:
            self._status = "ERROR"
            self._current_translation = message
            self.statusChanged.emit(self._status)
            self.translationUpdated.emit(self._current_translation)
            self._active_translation_index = -1
        self._set_engine_status("Error")

    @Slot(int, str, result=bool)
    def acceptTranslation(self, index, final_text):
        subtitles = self._subtitle_model.get_all_data()
        if 0 <= index < len(subtitles):
            original = subtitles[index].get("original", "").strip()
            clean_text = final_text.strip()
            
            if not clean_text:
                self.notify.emit("ERROR", "Lỗi: Không thể duyệt bản dịch trống!")
                return False
            if clean_text == original:
                self.notify.emit("ERROR", "Lỗi: Bản dịch không được trùng khớp y hệt văn bản gốc!")
                return False

        self._subtitle_model.update_translation(index, final_text, "ACCEPTED")
        self._status = "ACCEPTED"
        self.statusChanged.emit(self._status)
        self.notify.emit("SUCCESS", f"Đã lưu thành công câu #{index + 1}")
        return True
