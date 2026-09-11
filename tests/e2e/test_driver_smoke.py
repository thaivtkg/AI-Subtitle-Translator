from pathlib import Path

import pytest
from PySide6.QtCore import Qt

from .app_harness import AppHarness


FIXTURE = Path(__file__).parent / "fixtures" / "regression.srt"


@pytest.fixture
def harness():
    app_harness = AppHarness(FIXTURE)
    yield app_harness
    app_harness.close()


def test_find_child_smoke(harness):
    for object_name in ("btnOpenSrt", "searchInput", "btnTranslate"):
        assert harness.driver.find(object_name) is not None


def test_qtest_click_reaches_button_signal(harness):
    clicked = []
    button = harness.driver.find("btnOpenSrt")
    button.clicked.connect(lambda: clicked.append(True))

    harness.driver.click("btnOpenSrt")

    assert clicked == [True]
    harness.driver.key(Qt.Key_Escape)


def test_keyboard_typing_reaches_search(harness):
    harness.driver.type_text("searchInput", "magic")

    assert harness.driver.text("searchInput") == "magic"


def test_subtitle_rows_change_selection(harness):
    subtitle_list = harness.driver.find("subtitleList")

    harness.driver.click("subtitleRow_0")
    harness.driver.wait_until(lambda: subtitle_list.property("currentIndex") == 0)
    harness.driver.click("subtitleRow_1")
    harness.driver.wait_until(lambda: subtitle_list.property("currentIndex") == 1)


def test_snapshot_artifact(harness, tmp_path):
    harness.driver.artifact_dir = tmp_path

    screenshot_path = harness.driver.snapshot("driver_smoke")

    assert screenshot_path.exists()
    assert screenshot_path.stat().st_size > 0
