from app.batch.batch_item import BatchItem
from app.batch.batch_job import BatchJob
from app.batch.batch_state import BatchItemState, BatchJobState
from app.batch.transition_guard import ensure_item_transition, ensure_job_transition

from .translation_execution_port import TranslationExecutionPort


class BatchTranslationService:
    def __init__(self, execution_port: TranslationExecutionPort):
        self._execution_port = execution_port
        self._job: BatchJob | None = None
        self._active_index: int | None = None

    def start(self, job: BatchJob) -> None:
        if self._job is not None:
            raise RuntimeError("A batch job is already active")

        ensure_job_transition(job.state, BatchJobState.RUNNING)
        job.state = BatchJobState.RUNNING
        self._job = job
        self._dispatch_next()

    def _next_pending_item(self) -> BatchItem | None:
        assert self._job is not None

        for target_index in sorted(self._job.items):
            item = self._job.items[target_index]
            if item.state is BatchItemState.PENDING:
                return item

        return None

    def _dispatch_next(self) -> None:
        if self._active_index is not None:
            return

        item = self._next_pending_item()
        if item is None:
            self._finish_job()
            return

        ensure_item_transition(item.state, BatchItemState.RUNNING)
        item.state = BatchItemState.RUNNING
        self._active_index = item.target_index

        try:
            self._execution_port.translate(
                target_index=item.target_index,
                on_success=self._handle_success,
                on_error=self._handle_error,
            )
        except Exception as error:
            item.state = BatchItemState.FAILED
            item.error_msg = str(error)
            self._active_index = None
            ensure_job_transition(self._job.state, BatchJobState.FAILED)
            self._job.state = BatchJobState.FAILED
            self._job = None
            raise

    def _handle_success(self, target_index: int) -> None:
        if self._job is None:
            raise RuntimeError("No active batch job")
        if self._active_index != target_index:
            raise RuntimeError(
                f"Callback target mismatch: active={self._active_index}, "
                f"callback={target_index}"
            )

        item = self._job.items[target_index]
        ensure_item_transition(item.state, BatchItemState.COMPLETED)
        item.state = BatchItemState.COMPLETED
        self._active_index = None
        self._dispatch_next()

    def _handle_error(self, target_index: int, message: str) -> None:
        if self._job is None:
            raise RuntimeError("No active batch job")
        if self._active_index != target_index:
            raise RuntimeError(
                f"Callback target mismatch: active={self._active_index}, "
                f"callback={target_index}"
            )

        item = self._job.items[target_index]
        ensure_item_transition(item.state, BatchItemState.FAILED)
        item.state = BatchItemState.FAILED
        item.error_msg = message
        self._active_index = None
        self._dispatch_next()

    def _finish_job(self) -> None:
        assert self._job is not None
        ensure_job_transition(self._job.state, BatchJobState.COMPLETED)
        self._job.state = BatchJobState.COMPLETED
        self._job = None
        self._active_index = None
