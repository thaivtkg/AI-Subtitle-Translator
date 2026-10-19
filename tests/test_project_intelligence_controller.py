"""
Test ProjectController state management, auto-glossary extraction, anti-resurrection,
manual archetype locking, and .aisrt persistence.
"""
import os
import tempfile
import pytest
from unittest.mock import MagicMock
from app.controllers.project_controller import ProjectController
from app.controllers.translation_controller import TranslationController
from app.core.context_analyzer import (
    ARCHETYPE_ANCIENT_FANTASY,
    ARCHETYPE_ANIME_SCHOOL,
    ARCHETYPE_MODERN_ACTION,
    ARCHETYPE_CUSTOM,
)


def test_project_controller_summary_analysis_and_dismissal():
    ctrl = ProjectController(subtitle_model=MagicMock())
    # 1. Phân tích tóm tắt tự động
    ctrl.analyzeSummary('Phim cổ trang kiếm hiệp, nhân vật "Lăng Ba": Khinh công')
    assert ctrl.activeArchetype == ARCHETYPE_ANCIENT_FANTASY
    assert ctrl.activePronounPair == "Ta - Ngươi"

    # 2. Kiểm tra thuật ngữ tự động được thêm vào glossary
    glossary = ctrl.glossary
    assert glossary is not None
    assert glossary.get("Lăng Ba") is not None
    assert glossary.get("Lăng Ba").is_auto is True
    assert any(term["source_term"] == "Lăng Ba" and term["is_auto"] is True for term in ctrl.glossaryTerms)

    # 3. Người dùng bấm xóa chip (✕)
    ctrl.dismissAutoTerm("Lăng Ba")
    assert glossary.get("Lăng Ba") is None
    assert "Lăng Ba" in ctrl.dismissed_auto_terms

    # 4. Debounce kích hoạt lại với cùng tóm tắt -> BẮT BUỘC KHÔNG HỒI SINH TỪ ĐÃ XÓA
    ctrl.analyzeSummary('Phim cổ trang kiếm hiệp, nhân vật "Lăng Ba": Khinh công')
    assert glossary.get("Lăng Ba") is None

    # 5. Khóa thủ công thể loại từ Header Capsule
    ctrl.selectArchetype(ARCHETYPE_ANIME_SCHOOL, manual_lock=True)
    assert ctrl.isArchetypeLocked is True
    assert ctrl.activeArchetype == ARCHETYPE_ANIME_SCHOOL
    assert ctrl.activePronounPair == "Em - Tiền bối"

    # Tóm tắt mới không được ghi đè thể loại đã khóa
    ctrl.analyzeSummary("Phim cổ trang kiếm hiệp khác")
    assert ctrl.activeArchetype == ARCHETYPE_ANIME_SCHOOL
    assert ctrl.activePronounPair == "Em - Tiền bối"


def test_project_controller_save_and_load_persistence():
    mock_model = MagicMock()
    mock_model.get_all_data.return_value = [
        {"id": 1, "start_time": "00:00:01,000", "end_time": "00:00:02,000", "original": "Test", "translation": "Thử", "status": "TRANSLATED"}
    ]
    mock_model.rowCount.return_value = 1
    ctrl = ProjectController(subtitle_model=mock_model)
    ctrl.analyzeSummary('Phim về lập trình viên đối đầu "Bug Master": Trùm Bug')
    ctrl.dismissAutoTerm("Bug Master")
    ctrl.selectArchetype(ARCHETYPE_MODERN_ACTION, manual_lock=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        save_path = os.path.join(tmpdir, "test_proj.aisrt")
        ctrl.saveProject(save_path, "Summary test", "English", "Vietnamese")

        # Nạp lại vào một Controller mới tinh
        new_mock_model = MagicMock()
        load_ctrl = ProjectController(subtitle_model=new_mock_model)
        load_ctrl.loadProject(save_path)

        assert load_ctrl.activeArchetype == ARCHETYPE_MODERN_ACTION
        assert load_ctrl.activePronounPair == "Tôi - Bạn"
        assert load_ctrl.isArchetypeLocked is True
        assert "Bug Master" in load_ctrl.dismissed_auto_terms


def test_manual_terms_preserved_against_auto_dismissal():
    ctrl = ProjectController(subtitle_model=MagicMock())
    # Thêm thuật ngữ thủ công (is_auto=False)
    ctrl.glossary.add("Tiên Đan", "Elixir", (), is_auto=False)
    assert ctrl.glossary.get("Tiên Đan").is_auto is False

    # Phân tích tóm tắt có nhắc đến Tiên Đan
    ctrl.analyzeSummary('Truyện tu tiên luyện "Tiên Đan" thành thần')
    # Thuật ngữ thủ công giữ nguyên is_auto=False, không bị đè
    assert ctrl.glossary.get("Tiên Đan").is_auto is False


def test_translation_controller_binds_project_controller_and_cleans_hallucinated_prefix():
    mock_model = MagicMock()
    mock_model.get_all_data.return_value = []
    tc = TranslationController(subtitle_model=mock_model)
    pc = ProjectController(subtitle_model=mock_model)
    pc.selectArchetype(ARCHETYPE_ANCIENT_FANTASY, manual_lock=True)

    tc.bind_intelligence(
        glossary=pc.glossary,
        entities=pc.entity_dictionary,
        translation_memory=pc.translation_memory,
        project_controller=pc,
    )
    assert tc._project_controller == pc

    # Kiểm tra gọt sạch tiền tố dòng do mô hình ảo giác
    mock_worker = MagicMock()
    tc.worker = mock_worker
    tc._active_translation_index = 0
    tc._current_index = 0
    tc.on_finished(0, "[Line 1]: Ngươi muốn gì ở ta?")
    assert tc.currentTranslation == "Ngươi muốn gì ở ta?"


def test_project_controller_set_is_ja_origin():
    mock_model = MagicMock()
    pc = ProjectController(subtitle_model=mock_model)
    pc._has_project = True
    assert pc.isJaOrigin is False

    signals_received = []
    pc.archetypeChanged.connect(lambda: signals_received.append("archetypeChanged"))
    pc.projectStateChanged.connect(lambda: signals_received.append("projectStateChanged"))

    pc.setIsJaOrigin(True)
    assert pc.isJaOrigin is True
    assert pc.isDirty is True
    assert "archetypeChanged" in signals_received

    # Setting same value does not re-emit
    signals_received.clear()
    pc.setIsJaOrigin(True)
    assert len(signals_received) == 0

    # Setting False updates state and emits
    pc.setIsJaOrigin(False)
    assert pc.isJaOrigin is False
    assert "archetypeChanged" in signals_received

