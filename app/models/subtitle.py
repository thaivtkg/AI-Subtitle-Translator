from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, QByteArray
from app.core.qa_engine import analyze_subtitle


class SubtitleStatus:
    PENDING = "PENDING"
    TRANSLATING = "TRANSLATING"
    TRANSLATED = "TRANSLATED"  # Sửa READY thành TRANSLATED
    EDITED = "EDITED"
    ACCEPTED = "ACCEPTED"
    ERROR = "ERROR"


class SubtitleModel(QAbstractListModel):
    IndexRole = Qt.UserRole + 1
    StartTimeRole = Qt.UserRole + 2
    EndTimeRole = Qt.UserRole + 3
    OriginalRole = Qt.UserRole + 4
    TranslationRole = Qt.UserRole + 5
    StatusRole = Qt.UserRole + 6
    QaSeverityRole = Qt.UserRole + 7
    QaTooltipRole = Qt.UserRole + 8

    def __init__(self, parent=None):
        super().__init__(parent)
        self._subtitles = []

    def rowCount(self, parent=QModelIndex()):
        return len(self._subtitles)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < self.rowCount()):
            return None

        sub = self._subtitles[index.row()]
        # Dùng .get() O(1) để tránh lỗi vỡ Binding và đảm bảo hiệu năng 60fps khi scroll
        if role == self.IndexRole:
            return sub.get("index")
        elif role == self.StartTimeRole:
            return sub.get("start_time")
        elif role == self.EndTimeRole:
            return sub.get("end_time")
        elif role == self.OriginalRole:
            return sub.get("original", "")
        elif role == self.TranslationRole:
            return sub.get("translation", "")
        elif role == self.StatusRole:
            return sub.get("status", "PENDING")
        elif role == self.QaSeverityRole:
            return sub.get("_qa_severity", "")
        elif role == self.QaTooltipRole:
            return sub.get("_qa_tooltip", "")
        return None

    def roleNames(self):
        return {
            self.IndexRole: b"subIndex",
            self.StartTimeRole: b"startTime",
            self.EndTimeRole: b"endTime",
            self.OriginalRole: b"originalText",
            self.TranslationRole: b"translationText",
            self.StatusRole: b"status",
            self.QaSeverityRole: b"qaSeverity",
            self.QaTooltipRole: b"qaTooltip",
        }

    def load_data(self, data_list):
        for sub in data_list:
            self._normalize_translation_state(sub)
            self._update_item_qa(sub)
        self.beginResetModel()
        self._subtitles = data_list
        self.endResetModel()

    def get_all_data(self):
        """Trả về toàn bộ danh sách subtitle để Context Engine xử lý"""
        for sub in self._subtitles:
            self._normalize_translation_state(sub)
        return self._subtitles

    def get_qa_summary(self) -> dict:
        """Thống kê tổng số lỗi và cảnh báo QA trên toàn bộ project."""
        total_errors = sum(1 for sub in self._subtitles if sub.get("_qa_severity") == "ERROR")
        total_warnings = sum(1 for sub in self._subtitles if sub.get("_qa_severity") == "WARNING")
        return {"total_errors": total_errors, "total_warnings": total_warnings}

    @staticmethod
    def _update_item_qa(sub):
        """Tính toán trước kết quả QA và lưu vào dict item O(1)."""
        issues = analyze_subtitle(
            sub.get("start_time", 0),
            sub.get("end_time", 0),
            sub.get("original", ""),
            sub.get("translation", ""),
        )
        if not issues:
            sub["_qa_severity"] = ""
            sub["_qa_tooltip"] = ""
        else:
            has_error = any(i.severity == "ERROR" for i in issues)
            sub["_qa_severity"] = "ERROR" if has_error else "WARNING"
            sub["_qa_tooltip"] = "\n".join(f"• {i.message}" for i in issues)

    @staticmethod
    def _normalize_translation_state(sub):
        status = str(sub.get("status", "PENDING")).upper()
        translation = str(sub.get("translation", "") or "")
        if status in {"TRANSLATED", "EDITED", "ACCEPTED"} and not translation.strip():
            sub["translation"] = "Lỗi: Bản dịch rỗng."
            sub["status"] = "ERROR"

    def update_translation(self, row_index, translation_text, status):
        """Cập nhật bản dịch và trạng thái, sau đó báo cho QML vẽ lại"""
        if 0 <= row_index < len(self._subtitles):
            before = self._subtitles[row_index]
            print(
                f"[MODEL_COMMIT] target={row_index} "
                f"translation_before_len={len(str(before.get('translation', '') or ''))} "
                f"status_before={before.get('status', 'PENDING')} "
                f"translation_len={len(str(translation_text or ''))} "
                f"requested_status={status}",
                flush=True,
            )
            # 1. Cập nhật dữ liệu trong bộ nhớ Python
            self._subtitles[row_index]["translation"] = translation_text
            self._subtitles[row_index]["status"] = status
            self._normalize_translation_state(self._subtitles[row_index])
            self._update_item_qa(self._subtitles[row_index])
            after = self._subtitles[row_index]
            print(
                f"[MODEL_AFTER] target={row_index} "
                f"translation_len={len(str(after.get('translation', '') or ''))} "
                f"status={after.get('status', 'PENDING')} "
                f"translation={after.get('translation', '')!a} "
                f"qa_severity={after.get('_qa_severity', '')}",
                flush=True,
            )
            
            # 2. Tạo index và ÉP QML CẬP NHẬT CHÍNH XÁC CÁC BIẾN NÀY
            q_index = self.createIndex(row_index, 0)
            self.dataChanged.emit(
                q_index,
                q_index,
                [
                    self.TranslationRole,
                    self.StatusRole,
                    self.QaSeverityRole,
                    self.QaTooltipRole,
                ],
            )
