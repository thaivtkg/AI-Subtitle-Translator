from PySide6.QtCore import QObject, Property, Signal, Slot

from app.batch.batch_item import BatchItem
from app.batch.batch_job import BatchJob
from app.batch.batch_state import BatchItemState, BatchJobState
from app.batch.fingerprint import compute_source_hash


class BatchController(QObject):
    stateChanged = Signal()
    projectionChanged = Signal()

    def __init__(self, subtitle_model, service, project_id, parent=None):
        super().__init__(parent)
        self._subtitle_model = subtitle_model
        self._service = service
        self._project_id = project_id
        self._job = None
        self._cancel_pending = False
        self._config = None

        job_changed = getattr(service, "jobChanged", None)
        if job_changed is not None:
            job_changed.connect(self._refresh)
        subtitle_model.modelReset.connect(self._refresh)
        subtitle_model.dataChanged.connect(self._refresh)

    @Property(str, notify=stateChanged)
    def state(self):
        return self._job.state.name if self._job is not None else BatchJobState.IDLE.name

    @Property(int, notify=projectionChanged)
    def activeIndex(self):
        if self._job is None:
            return -1
        for item in self._job.items.values():
            if item.state is BatchItemState.RUNNING:
                return item.target_index
        return -1

    @Property(int, notify=projectionChanged)
    def totalCount(self):
        return len(self._job.items) if self._job is not None else 0

    def _count(self, state):
        if self._job is None:
            return 0
        return sum(item.state is state for item in self._job.items.values())

    @Property(int, notify=projectionChanged)
    def completedCount(self):
        return self._count(BatchItemState.COMPLETED)

    @Property(int, notify=projectionChanged)
    def failedCount(self):
        return self._count(BatchItemState.FAILED)

    @Property(int, notify=projectionChanged)
    def pendingCount(self):
        return self._count(BatchItemState.PENDING)

    @Property(int, notify=projectionChanged)
    def cancelledCount(self):
        return self._count(BatchItemState.CANCELLED)

    @Property(int, notify=projectionChanged)
    def progressPercent(self):
        total = self.totalCount
        if total == 0:
            return 0
        terminal = sum(
            item.state in {
                BatchItemState.COMPLETED,
                BatchItemState.FAILED,
                BatchItemState.SKIPPED,
                BatchItemState.CANCELLED,
            }
            for item in self._job.items.values()
        )
        return round(terminal * 100 / total)

    @Property(bool, notify=projectionChanged)
    def cancelPending(self):
        return self._cancel_pending

    @Property(bool, notify=projectionChanged)
    def executionLocked(self):
        return self._cancel_pending or self.state in {
            BatchJobState.RUNNING.name,
            BatchJobState.PAUSING.name,
            BatchJobState.PAUSED.name,
        }

    def _has_pending_source(self):
        return any(
            str(item.get("status", "PENDING")).upper() == "PENDING"
            for item in self._subtitle_model.get_all_data()
        )

    @Property(bool, notify=projectionChanged)
    def canStart(self):
        return not self.executionLocked and self._has_pending_source()

    @Property(bool, notify=projectionChanged)
    def canPause(self):
        return self.state == BatchJobState.RUNNING.name and not self._cancel_pending

    @Property(bool, notify=projectionChanged)
    def canResume(self):
        return self.state == BatchJobState.PAUSED.name and self.activeIndex == -1

    @Property(bool, notify=projectionChanged)
    def canCancel(self):
        return self.state == BatchJobState.RUNNING.name and not self._cancel_pending

    @Property(bool, notify=projectionChanged)
    def canRetryFailed(self):
        return (
            self.state == BatchJobState.COMPLETED.name
            and self.failedCount > 0
        )

    @Slot(str, str, str)
    def startBatch(self, source_lang, target_lang, story_summary):
        if not self.canStart:
            raise RuntimeError("Cannot start batch")

        items = {
            index: BatchItem(
                target_index=index,
                source_hash=compute_source_hash(str(subtitle.get("original", ""))),
            )
            for index, subtitle in enumerate(self._subtitle_model.get_all_data())
            if str(subtitle.get("status", "PENDING")).upper() == "PENDING"
        }
        self._config = (source_lang, target_lang, story_summary)
        self._job = BatchJob.create(self._project_id, items)
        self._cancel_pending = False
        configure = getattr(self._service, "configure", None)
        if configure is not None:
            configure(source_lang, target_lang, story_summary)
        self._service.start(self._job)
        self._refresh()

    @Slot()
    def pauseBatch(self):
        if self._job is None:
            raise RuntimeError("No active batch job")
        self._service.request_pause(self._job)
        self._refresh()

    @Slot()
    def resumeBatch(self):
        if self._job is None:
            raise RuntimeError("No active batch job")
        self._service.resume(self._job)
        self._refresh()

    @Slot()
    def cancelBatch(self):
        if self._job is None:
            raise RuntimeError("No active batch job")
        self._service.request_cancel(self._job)
        self._cancel_pending = True
        self._refresh()

    @Slot()
    def retryFailed(self):
        if self._job is None:
            raise RuntimeError("No active batch job")
        self._service.retry_failed(self._job)
        self._cancel_pending = False
        self._refresh()

    def _refresh(self):
        if self._job is not None and self._job.state in {
            BatchJobState.COMPLETED,
            BatchJobState.FAILED,
            BatchJobState.CANCELLED,
        }:
            self._cancel_pending = False
        self.stateChanged.emit()
        self.projectionChanged.emit()
