from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, QByteArray

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

    def __init__(self, parent=None):
        super().__init__(parent)
        self._subtitles = []

    def rowCount(self, parent=QModelIndex()):
        return len(self._subtitles)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < self.rowCount()):
            return None

        sub = self._subtitles[index.row()]
        # Dùng .get() để tránh lỗi vỡ Binding nếu key chưa tồn tại
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
        return None

    def roleNames(self):
        return {
            self.IndexRole: b"subIndex",
            self.StartTimeRole: b"startTime",
            self.EndTimeRole: b"endTime",
            self.OriginalRole: b"originalText",
            self.TranslationRole: b"translationText",
            self.StatusRole: b"status"
        }

    def load_data(self, data_list):
        self.beginResetModel()
        self._subtitles = data_list
        self.endResetModel()

    # ---- BỔ SUNG TỪ ĐÂY ----
    def get_all_data(self):
        """Trả về toàn bộ danh sách subtitle để Context Engine xử lý"""
        return self._subtitles

    def update_translation(self, row_index, translation_text, status):
        """Cập nhật bản dịch và trạng thái, sau đó báo cho QML vẽ lại"""
        if 0 <= row_index < len(self._subtitles):
            # 1. Cập nhật dữ liệu trong bộ nhớ Python
            self._subtitles[row_index]["translation"] = translation_text
            self._subtitles[row_index]["status"] = status
            
            # 2. Tạo index và ÉP QML CẬP NHẬT CHÍNH XÁC 2 BIẾN NÀY
            q_index = self.createIndex(row_index, 0)
            self.dataChanged.emit(q_index, q_index, [self.TranslationRole, self.StatusRole])