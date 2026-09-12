from pathlib import Path

from PySide6.QtCore import Qt

from .app_harness import AppHarness
from .deterministic_worker import DeterministicWorkerFactory


FIXTURE = Path(__file__).parent / "fixtures" / "regression.srt"


def wait_for(harness, predicate, timeout_ms=3000):
    harness.driver.wait_until(predicate, timeout_ms)


def test_tc_p3a7_q01_production_composition_and_start():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        assert harness.driver.find("batchControlBar") is not None
        assert harness.driver.is_enabled("btnBatchStart")
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert harness.batch_controller.activeIndex == 0
    finally:
        harness.close()


def test_tc_p3a7_q02_selection_independence():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.find("subtitleList").setProperty("currentIndex", -1)
        assert harness.driver.is_enabled("btnBatchStart")
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert harness.batch_controller.activeIndex == 0
    finally:
        harness.close()


def test_tc_p3a7_q03_manual_actions_locked():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert not harness.driver.is_enabled("btnTranslate")
        assert not harness.driver.is_enabled("btnRetry")
        assert not harness.driver.is_enabled("btnAccept")
        assert harness.driver.find("translationInput").property("readOnly") is True
    finally:
        harness.close()


def test_tc_p3a7_q04_keyboard_acceptance_is_locked():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("subtitleRow_0")
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        harness.driver.focus("translationInput")
        harness.driver.key(Qt.Key_Return, Qt.ControlModifier)
        assert harness.model.get_all_data()[0]["status"].upper() != "ACCEPTED"
    finally:
        harness.close()


def test_tc_p3a7_q05_project_mutation_locked():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert not harness.driver.is_enabled("btnOpenSrt")
        assert not harness.driver.is_enabled("btnOpenProject")
        assert not harness.driver.find("shortcutOpenSrt").property("enabled")
        assert not harness.driver.find("shortcutOpenProject").property("enabled")
    finally:
        harness.close()


def test_tc_p3a7_q06_pause_resume():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        harness.driver.click("btnBatchPause")
        wait_for(harness, lambda: harness.batch_controller.state == "PAUSED")
        assert harness.driver.is_enabled("btnBatchResume")
        assert harness.batch_controller.activeIndex == -1
        harness.driver.click("btnBatchResume")
        assert harness.batch_controller.state == "RUNNING"
    finally:
        harness.close()


def test_tc_p3a7_q07_graceful_cancel_presentation():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        harness.driver.click("btnBatchCancel")
        assert harness.batch_controller.cancelPending is True
        assert "Cancelling" in harness.driver.text("batchStatusText")
        wait_for(harness, lambda: harness.batch_controller.state == "CANCELLED")
        assert harness.batch_controller.executionLocked is False
    finally:
        harness.close()


def test_tc_p3a7_q08_retry_failed():
    factory = DeterministicWorkerFactory("error")
    harness = AppHarness(FIXTURE, worker_factory=factory)
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "COMPLETED")
        assert harness.driver.is_enabled("btnBatchRetryFailed")
        factory.set_mode("success")
        job = harness.batch_controller._job
        harness.driver.click("btnBatchRetryFailed")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert harness.batch_controller._job is job
    finally:
        harness.close()


def test_tc_p3a7_q09_batch_progress_projection():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("slow"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "RUNNING")
        assert harness.batch_controller.totalCount == 3
        assert harness.driver.text("batchProgressText")
    finally:
        harness.close()


def test_tc_p3a7_q10_terminal_unlock():
    harness = AppHarness(FIXTURE, worker_factory=DeterministicWorkerFactory("success"))
    try:
        harness.driver.click("btnBatchStart")
        wait_for(harness, lambda: harness.batch_controller.state == "COMPLETED")
        assert harness.batch_controller.executionLocked is False
        assert harness.driver.is_enabled("btnOpenSrt")
        assert harness.driver.is_enabled("btnOpenProject")
        assert not harness.driver.is_enabled("btnBatchPause")
        assert not harness.driver.is_enabled("btnBatchCancel")
    finally:
        harness.close()
