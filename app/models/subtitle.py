from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, QByteArray

class SubtitleStatus:
    PENDING = "pending"
    TRANSLATING = "translating"
    EDITED = "edited"
    ACCEPTED = "accepted"
    ERROR = "error"

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
        if role == self.IndexRole:
            return sub["index"]
        elif role == self.StartTimeRole:
            return sub["start_time"]
        elif role == self.EndTimeRole:
            return sub["end_time"]
        elif role == self.OriginalRole:
            return sub["original"]
        elif role == self.TranslationRole:
            return sub["translation"]
        elif role == self.StatusRole:
            return sub["status"]
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

    def update_translation(self, row, text, status):
        """Cập nhật bản dịch và trạng thái, báo cho UI biết để render lại"""
        if 0 <= row < len(self._subtitles):
            self._subtitles[row]["translation"] = text
            self._subtitles[row]["status"] = status
            
            idx = self.index(row, 0)
            self.dataChanged.emit(idx, idx, [self.TranslationRole, self.StatusRole])