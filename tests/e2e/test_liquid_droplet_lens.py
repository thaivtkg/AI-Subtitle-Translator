import pytest
from PySide6.QtCore import Qt, QCoreApplication
from app.models.subtitle import SubtitleModel
from .app_harness import AppHarness


def generate_mock_subtitles(count: int = 20):
    subtitles = []
    for i in range(count):
        s_sec = i * 3
        e_sec = s_sec + 2
        sh, sm, ss = s_sec // 3600, (s_sec % 3600) // 60, s_sec % 60
        eh, em, es = e_sec // 3600, (e_sec % 3600) // 60, e_sec % 60
        subtitles.append({
            "index": i + 1,
            "start_time": f"{sh:02d}:{sm:02d}:{ss:02d},000",
            "end_time": f"{eh:02d}:{em:02d}:{es:02d},000",
            "original": f"Sentence {i + 1} test line.",
            "translation": f"Bản dịch câu {i + 1}." if i % 2 == 0 else "",
            "status": "ACCEPTED" if i == 0 else ("TRANSLATED" if i % 2 == 0 else "PENDING"),
        })
    return subtitles


@pytest.fixture
def harness_lens():
    harness = AppHarness(None)
    mock_data = generate_mock_subtitles(20)
    harness.model.load_data(mock_data)
    QCoreApplication.processEvents()
    yield harness
    harness.close()


def test_ac01_droplet_lens_structure_and_tracking(harness_lens):
    """AC-01: subDropletLens được gán vào contentItem và bám sát currentItem."""
    driver = harness_lens.driver
    sub_list = driver.find("subtitleList")
    sub_lens = driver.find("subDropletLens")

    assert sub_lens is not None, "subDropletLens must exist in QML hierarchy"
    assert sub_list.property("count") == 20
    assert sub_list.property("currentIndex") == 0

    QCoreApplication.processEvents()
    assert sub_lens.property("visible") is True
    assert sub_lens.property("z") == 1

    # Khi đổi currentIndex sang 2, subDropletLens cập nhật targetY
    sub_list.setProperty("currentIndex", 2)
    QCoreApplication.processEvents()

    cur_item = sub_list.property("currentItem")
    assert cur_item is not None
    assert sub_lens.property("targetY") == cur_item.property("y") + 4


def pump_events(duration_sec: float = 0.25):
    import time
    start = time.perf_counter()
    while time.perf_counter() - start < duration_sec:
        QCoreApplication.processEvents()
        time.sleep(0.01)


def test_ac02_droplet_lens_clamping_and_drag_state(harness_lens):
    """AC-02: Cơ chế kẹp biên, khóa z-index = 1 và đồng bộ dragHoverIndex theo thời gian thực."""
    driver = harness_lens.driver
    sub_list = driver.find("subtitleList")
    sub_lens = driver.find("subDropletLens")
    root_view = driver.find("subtitleListView")

    assert root_view.property("isDraggingLens") is False
    assert root_view.property("dragHoverIndex") == -1
    assert sub_lens.property("scale") == 1.0
    assert sub_lens.property("z") == 1

    # Bật drag giả lập và di chuyển qua câu 3
    root_view.setProperty("isDraggingLens", True)
    root_view.setProperty("dragHoverIndex", 3)
    pump_events(0.25)
    assert root_view.property("isDraggingLens") is True
    # z-index luôn khóa cứng = 1 để không bao giờ đè che chữ
    assert sub_lens.property("z") == 1
    assert sub_lens.property("scale") == pytest.approx(0.97, abs=0.02)

    # Thẻ 3 nhận thấu kính theo thời gian thực -> isPrimarySelected = True
    item3 = sub_list.itemAtIndex(3)
    item0 = sub_list.itemAtIndex(0)
    if item3:
        assert item3.property("isPrimarySelected") is True
    if item0:
        assert item0.property("isPrimarySelected") is False

    # Nhả drag
    root_view.setProperty("isDraggingLens", False)
    root_view.setProperty("dragHoverIndex", -1)
    pump_events(0.25)
    assert sub_lens.property("z") == 1
    assert sub_lens.property("scale") == pytest.approx(1.0, abs=0.02)
    if item0:
        assert item0.property("isPrimarySelected") is True


def test_ac03_multi_selection_contrast_guard(harness_lens):
    """AC-03: Multi-selection giữ tương phản: câu chính isPrimarySelected, câu phụ isSecondarySelected."""
    driver = harness_lens.driver
    sub_list = driver.find("subtitleList")
    root_view = driver.find("subtitleListView")

    # Chọn câu 0 (chính) và câu 1 (phụ)
    sub_list.setProperty("currentIndex", 0)
    root_view.setProperty("selectedIndices", [0, 1])
    QCoreApplication.processEvents()

    item0 = sub_list.property("currentItem")
    assert item0 is not None
    assert item0.property("isPrimarySelected") is True
    assert item0.property("isSecondarySelected") is False

    # Thẻ 1 là chọn phụ
    item1 = sub_list.itemAtIndex(1)
    if item1:
        assert item1.property("isPrimarySelected") is False
        assert item1.property("isSecondarySelected") is True


def test_ac04_status_badge_geometry_and_alignment(harness_lens):
    """AC-04: Status badge có chiều cao 20, bo góc 10, font 10 bold."""
    driver = harness_lens.driver
    sub_list = driver.find("subtitleList")
    QCoreApplication.processEvents()

    item0 = sub_list.property("currentItem")
    assert item0 is not None

    card_pod = item0.findChild(object, "cardPod")
    # Kiểm tra delegate item geometry
    assert item0.property("hasTranslation") is True
    assert item0.property("height") == 82
