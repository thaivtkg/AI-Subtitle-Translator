from PySide6.QtCore import QObject, Slot, Signal, Property
from app.llm.worker import TranslationWorker
from app.core.context_engine import ContextEngine
from app.core.prompt_builder import PromptBuilder

class TranslationController(QObject):
    statusChanged = Signal(str)
    translationUpdated = Signal(str)

    def __init__(self, subtitle_model):
        super().__init__()
        self._status = "PENDING"
        self._current_translation = ""
        self._subtitle_model = subtitle_model
        self.worker = None

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(str, notify=translationUpdated)
    def currentTranslation(self):
        return self._current_translation

    @Slot(int, str, str, str)
    def requestTranslation(self, index, source_lang, target_lang, story_summary):
        if self.worker and self.worker.isRunning():
            self.worker.terminate()
            self.worker.wait()

        self._status = "TRANSLATING"
        self.statusChanged.emit(self._status)
        self._current_translation = ""
        self.translationUpdated.emit("")

        subtitles = self._subtitle_model.get_all_data()
        prev_ctx, current, next_ctx = ContextEngine.get_context(subtitles, index)
        # Bổ sung tham số story_summary vào đây
        prompt = PromptBuilder.build(story_summary, source_lang, target_lang, prev_ctx, current, next_ctx)

        self.worker = TranslationWorker(prompt)
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
        self._status = "READY"
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
        """Lưu bản dịch cuối cùng vào Data Model và đổi trạng thái"""
        self._subtitle_model.update_translation(index, final_text, "accepted")
        self._status = "ACCEPTED"
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(final_text)

    @Slot(int)
    def loadSubtitle(self, index):
        """Tải dữ liệu của subtitle khi người dùng click vào thẻ bên trái"""
        if index < 0:
            return
        
        subtitles = self._subtitle_model.get_all_data()
        if index >= len(subtitles):
            return
        
        sub = subtitles[index]
        
        # Nếu đã accept thì hiện bản dịch, nếu chưa thì hiện text gốc
        if sub["status"] == "accepted":
            self._current_translation = sub["translation"]
            self._status = "ACCEPTED"
        else:
            self._current_translation = sub["original"]
            self._status = "PENDING"
            
        self.statusChanged.emit(self._status)
        self.translationUpdated.emit(self._current_translation)
