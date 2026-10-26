"""
E2E integration tests for ContextInspector, AppHeader, and ProjectController:
- 2000ms summary debounce timer triggering analyzeSummary
- Archetype selection, active pronoun update, and manual locking/unlocking
- Auto-glossary extraction and term dismissal
- AppHeader archetype capsule display and navigation
"""
from pathlib import Path
import pytest
from PySide6.QtCore import Qt
from PySide6.QtTest import QTest

from app.core.context_analyzer import (
    ARCHETYPE_ANCIENT_FANTASY,
    ARCHETYPE_ANIME_SCHOOL,
    ARCHETYPE_MODERN_ACTION,
)
from .app_harness import AppHarness


FIXTURE = Path(__file__).parent / "fixtures" / "regression.srt"


@pytest.fixture
def harness():
    app_harness = AppHarness(FIXTURE)
    yield app_harness
    app_harness.close()


def test_story_summary_debounce_timer_and_analysis(harness):
    """Kiểm tra storySummaryInput có debounce timer 2000ms và kích hoạt analyzeSummary."""
    driver = harness.driver
    tabs = driver.find("contextTabs")
    assert tabs is not None
    tabs.setCurrentIndex(2)  # Tab 3: SUMMARY
    QTest.qWait(50)

    summary_input = driver.find("storySummaryInput")
    assert summary_input is not None

    debounce_timer = driver.find("summaryDebounceTimer")
    assert debounce_timer is not None
    assert debounce_timer.property("interval") == 2000
    assert debounce_timer.property("repeat") is False

    # Nhập tóm tắt chứa thực thể và thể loại kiếm hiệp
    summary_text = 'Phim cổ trang kiếm hiệp, nhân vật "Lăng Ba": Khinh công'
    summary_input.setProperty("text", summary_text)
    QTest.qWait(50)

    # Đảm bảo timer đã khởi động
    assert debounce_timer.property("running") is True

    # Kích hoạt timer hoàn tất (hoặc chờ trigger)
    driver.wait_until(
        lambda: harness.project_controller.activeArchetype == ARCHETYPE_ANCIENT_FANTASY,
        timeout_ms=3000,
    )
    assert harness.project_controller.activePronounPair == "Ta - Ngươi"

    # Kiểm tra capsule thông tin dưới thẻ summary
    capsule = driver.find("summaryArchetypeCapsule")
    assert capsule is not None
    assert capsule.property("visible") is True
    assert driver.text("summaryCapsulePronouns") == "Ta - Ngươi"


def test_project_controller_select_archetype_and_locking(harness):
    """Kiểm tra gọi selectArchetype cập nhật activeArchetype, activePronounPair, isArchetypeLocked."""
    driver = harness.driver
    tabs = driver.find("contextTabs")
    tabs.setCurrentIndex(1)  # Tab 2: INTELLIGENCE
    QTest.qWait(50)

    # Khóa thủ công thể loại Anime
    harness.project_controller.selectArchetype(ARCHETYPE_ANIME_SCHOOL, manual_lock=True)
    driver.wait_until(
        lambda: harness.project_controller.activeArchetype == ARCHETYPE_ANIME_SCHOOL
    )
    assert harness.project_controller.activePronounPair == "Em - Tiền bối"
    assert harness.project_controller.isArchetypeLocked is True

    # Kiểm tra UI Tab 2 phản ánh chính xác
    assert driver.text("activePronounDisplay") == "Em - Tiền bối"
    assert "Đã khóa" in driver.text("statusBadgeText")
    btn_unlock = driver.find("btnUnlockArchetype")
    assert btn_unlock.property("visible") is True

    # Mở khóa thủ công qua nút bấm trên UI
    driver.click("btnUnlockArchetype")
    driver.wait_until(lambda: not harness.project_controller.isArchetypeLocked)
    assert harness.project_controller.isArchetypeLocked is False
    assert btn_unlock.property("visible") is False
    assert "Tự động" in driver.text("statusBadgeText")


def test_project_controller_dismiss_auto_term(harness):
    """Kiểm tra gọi dismissAutoTerm xóa chip khỏi glossaryTerms."""
    driver = harness.driver

    # Kích hoạt trích xuất thuật ngữ tự động
    harness.project_controller.analyzeSummary('Phim thần thoại, nhân vật "Hạo Thiên": Thần kiếm')
    assert any(
        term["source_term"] == "Hạo Thiên" and term["is_auto"] for term in harness.project_controller.glossaryTerms
    )

    # Chuyển sang Tab 2: INTELLIGENCE
    tabs = driver.find("contextTabs")
    tabs.setCurrentIndex(1)
    QTest.qWait(50)

    # Xóa thuật ngữ tự động qua nút bấm X trên chip UI
    driver.click("btnDismissTerm_Hạo Thiên")
    driver.wait_until(
        lambda: not any(term["source_term"] == "Hạo Thiên" for term in harness.project_controller.glossaryTerms)
    )

    # Không còn thuật ngữ "Hạo Thiên" trong glossary
    assert harness.project_controller.glossary.get("Hạo Thiên") is None
    assert "Hạo Thiên" in harness.project_controller.dismissed_auto_terms

    # Thẻ empty state xuất hiện lại
    assert driver.is_visible("glossaryEmptyState")


def test_app_header_archetype_capsule_navigation(harness):
    """Kiểm tra capsule thể loại trên AppHeader hiển thị và click chuyển sang Tab INTELLIGENCE."""
    driver = harness.driver
    tabs = driver.find("contextTabs")
    tabs.setCurrentIndex(0)  # TIMELINE
    assert tabs.property("currentIndex") == 0

    header_capsule = driver.find("archetypeHeaderCapsule")
    assert header_capsule is not None

    # Giả lập click vào capsule thể loại trên header
    driver.click("archetypeHeaderCapsule")
    driver.wait_until(lambda: tabs.property("currentIndex") == 1)
    assert tabs.property("currentIndex") == 1

def test_context_inspector_geometry_and_padding(harness):
    """Kiểm tra khoảng thở an toàn của Nút Thêm, Khung Empty State và Capsule nguồn gốc."""
    driver = harness.driver
    tabs = driver.find("contextTabs")
    assert tabs is not None

    # 1. Đo đạc Tab 1: GLOSSARY
    tabs.setCurrentIndex(1)
    QTest.qWait(50)
    card = driver.find("glossaryCard")
    empty = driver.find("glossaryEmptyState")
    btn = driver.find("btnToggleAddTerm")
    card_w = card.property("width")
    empty_w = empty.property("width")
    btn_x = btn.property("x")
    btn_w = btn.property("width")

    assert (card_w - (btn_x + btn_w)) >= 18.0, f"Nút Thêm quá sát mép phải: {card_w - (btn_x + btn_w)}"
    assert (card_w - empty_w) >= 32.0, f"Khung trắng quá sát viền card: {card_w - empty_w}"

    # 2. Đo đạc Tab 2: SUMMARY (Origin Capsule)
    tabs.setCurrentIndex(2)
    QTest.qWait(50)
    capsule = driver.find("btnOriginCapsule")
    assert capsule is not None
    assert capsule.property("width") > 0
    init_is_ja = harness.project_controller.isJaOrigin
    driver.click("btnOriginCapsule")
    QTest.qWait(50)
    assert harness.project_controller.isJaOrigin != init_is_ja
    driver.click("btnOriginCapsule")
    QTest.qWait(50)
    assert harness.project_controller.isJaOrigin == init_is_ja
