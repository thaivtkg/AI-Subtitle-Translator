from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal, Property, QByteArray
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

    @Slot(result="QVariantList")
    def get_all_data(self):
        """Trả về toàn bộ danh sách subtitle để Context Engine và QML xử lý"""
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


class FilteredSubtitleModel(QAbstractListModel):
    RawIndexRole = Qt.UserRole + 9

    filteredCountChanged = Signal()
    totalCountChanged = Signal()
    currentPageChanged = Signal()
    totalPagesChanged = Signal()
    pageSizeChanged = Signal()

    def __init__(self, source_model: SubtitleModel, parent=None):
        super().__init__(parent)
        self._source = source_model
        self._matching_indices = []
        self._page_indices = []
        self._search_query = ""
        self._status_filter = "ALL"
        self._time_filter_active = False
        self._filter_start_min = 0
        self._filter_end_min = 9999
        self._page_size = 0  # 0 = Tất cả câu
        self._current_page = 1
        self._total_pages = 1

        self._source.modelReset.connect(self._recompute_and_reset)
        self._source.dataChanged.connect(self._on_source_data_changed)
        self._recompute_and_reset()

    def _recompute_and_reset(self):
        all_data = self._source.get_all_data()
        matching = []

        sq = self._search_query.strip().lower()
        cf = self._status_filter.strip().upper()
        tf = self._time_filter_active
        s_min = self._filter_start_min
        e_min = self._filter_end_min

        for i, sub in enumerate(all_data):
            # 1. Search text filter
            if sq:
                orig = str(sub.get("original", "")).lower()
                trans = str(sub.get("translation", "")).lower()
                if sq not in orig and sq not in trans:
                    continue

            # 2. Status filter
            if cf != "ALL":
                st = str(sub.get("status", "PENDING")).upper()
                if cf == "PENDING" and st not in ("PENDING", ""):
                    continue
                elif cf != "PENDING" and st != cf:
                    continue

            # 3. Time filter (parse HH:MM from start_time)
            if tf:
                t_str = str(sub.get("start_time", ""))
                if len(t_str) >= 5:
                    try:
                        sub_m = int(t_str[:2]) * 60 + int(t_str[3:5])
                    except ValueError:
                        sub_m = 0
                else:
                    sub_m = 0
                if sub_m < s_min or sub_m > e_min:
                    continue

            matching.append(i)

        self._matching_indices = matching
        total_matching = len(matching)

        if self._page_size > 0:
            self._total_pages = max(1, (total_matching + self._page_size - 1) // self._page_size)
        else:
            self._total_pages = 1

        if self._current_page > self._total_pages:
            self._current_page = self._total_pages
        if self._current_page < 1:
            self._current_page = 1

        if self._page_size > 0 and total_matching > 0:
            start = (self._current_page - 1) * self._page_size
            end = start + self._page_size
            self._page_indices = matching[start:end]
        else:
            self._page_indices = matching

        self.beginResetModel()
        self.endResetModel()

        self.filteredCountChanged.emit()
        self.totalCountChanged.emit()
        self.currentPageChanged.emit()
        self.totalPagesChanged.emit()
        self.pageSizeChanged.emit()

    def _on_source_data_changed(self, top_left, bottom_right, roles):
        start_row = top_left.row()
        end_row = bottom_right.row()
        for raw_idx in range(start_row, end_row + 1):
            if raw_idx in self._page_indices:
                view_row = self._page_indices.index(raw_idx)
                q_idx = self.createIndex(view_row, 0)
                self.dataChanged.emit(q_idx, q_idx, roles)

    def rowCount(self, parent=QModelIndex()):
        return len(self._page_indices)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._page_indices)):
            return None
        raw_idx = self._page_indices[index.row()]
        if role == self.RawIndexRole:
            return raw_idx
        return self._source.data(self._source.index(raw_idx, 0), role)

    def roleNames(self):
        roles = dict(self._source.roleNames())
        roles[self.RawIndexRole] = b"rawIndex"
        return roles

    @Property(int, notify=filteredCountChanged)
    def filteredCount(self):
        return len(self._matching_indices)

    @Property(int, notify=totalCountChanged)
    def totalCount(self):
        return self._source.rowCount()

    @Property(int, notify=currentPageChanged)
    def currentPage(self):
        return self._current_page

    @Property(int, notify=totalPagesChanged)
    def totalPages(self):
        return self._total_pages

    @Property(int, notify=pageSizeChanged)
    def pageSize(self):
        return self._page_size

    @Property(bool, notify=currentPageChanged)
    def hasPrevPage(self):
        return self._current_page > 1

    @Property(bool, notify=currentPageChanged)
    def hasNextPage(self):
        return self._current_page < self._total_pages

    @Slot(str)
    def setSearchQuery(self, query: str):
        if self._search_query != query:
            self._search_query = query
            self._current_page = 1
            self._recompute_and_reset()

    @Slot(str)
    def setStatusFilter(self, status: str):
        if self._status_filter != status:
            self._status_filter = status
            self._current_page = 1
            self._recompute_and_reset()

    @Slot(bool, int, int)
    def setTimeFilter(self, active: bool, start_min: int, end_min: int):
        if (self._time_filter_active != active or
                self._filter_start_min != start_min or
                self._filter_end_min != end_min):
            self._time_filter_active = active
            self._filter_start_min = start_min
            self._filter_end_min = end_min
            self._current_page = 1
            self._recompute_and_reset()

    @Slot(int)
    def setPageSize(self, size: int):
        if self._page_size != size:
            self._page_size = size
            self._current_page = 1
            self._recompute_and_reset()

    @Slot(int)
    def setCurrentPage(self, page: int):
        if 1 <= page <= self._total_pages and self._current_page != page:
            self._current_page = page
            self._recompute_and_reset()

    @Slot()
    def nextPage(self):
        if self._current_page < self._total_pages:
            self.setCurrentPage(self._current_page + 1)

    @Slot()
    def prevPage(self):
        if self._current_page > 1:
            self.setCurrentPage(self._current_page - 1)

    @Slot(int, result=int)
    def getRawIndex(self, view_row: int) -> int:
        if 0 <= view_row < len(self._page_indices):
            return self._page_indices[view_row]
        return -1

    @Slot(int, result=int)
    def getViewIndex(self, raw_index: int) -> int:
        if raw_index in self._page_indices:
            return self._page_indices.index(raw_index)
        return -1

