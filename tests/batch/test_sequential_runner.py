from app.batch.batch_item import BatchItem
from app.batch.batch_job import BatchJob
from app.batch.batch_state import BatchItemState, BatchJobState
from app.services.batch_translation_service import BatchTranslationService


class ControlledTranslationPort:
    def __init__(self):
        self.calls = []
        self.current = None
        self.active_count = 0
        self.max_concurrent = 0

    def translate(self, target_index, on_success, on_error):
        if self.current is not None:
            raise AssertionError("Second inference dispatched before first completed")

        self.calls.append(target_index)
        self.current = (target_index, on_success, on_error)
        self.active_count += 1
        self.max_concurrent = max(self.max_concurrent, self.active_count)

    def complete_current(self):
        target_index, on_success, _ = self.current
        self.current = None
        self.active_count -= 1
        on_success(target_index)


def test_tc_p3a2_03_executes_items_sequentially():
    port = ControlledTranslationPort()
    items = {
        2: BatchItem(target_index=2, source_hash="hash-2"),
        0: BatchItem(target_index=0, source_hash="hash-0"),
        1: BatchItem(target_index=1, source_hash="hash-1"),
    }
    job = BatchJob(job_id="job-1", project_id="project-1", items=items)
    service = BatchTranslationService(port)

    service.start(job)

    assert job.state is BatchJobState.RUNNING
    assert job.items[0].state is BatchItemState.RUNNING
    assert job.items[1].state is BatchItemState.PENDING
    assert job.items[2].state is BatchItemState.PENDING
    assert port.calls == [0]
    assert port.max_concurrent == 1

    port.complete_current()

    assert port.calls == [0, 1]
    assert job.items[0].state is BatchItemState.COMPLETED
    assert job.items[1].state is BatchItemState.RUNNING
    assert job.items[2].state is BatchItemState.PENDING
    assert port.max_concurrent == 1

    port.complete_current()

    assert port.calls == [0, 1, 2]
    assert job.items[1].state is BatchItemState.COMPLETED
    assert job.items[2].state is BatchItemState.RUNNING
    assert port.max_concurrent == 1

    port.complete_current()

    assert job.state is BatchJobState.COMPLETED
    assert all(item.state is BatchItemState.COMPLETED for item in job.items.values())
    assert port.calls == [0, 1, 2]
    assert port.max_concurrent == 1
