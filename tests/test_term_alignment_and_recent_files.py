import os
import pytest
from PySide6.QtCore import QCoreApplication, QObject
from app.models.subtitle import SubtitleModel
from app.controllers.project_controller import ProjectController
from app.controllers.translation_controller import TranslationController
from app.core.app_settings import AppSettings


@pytest.fixture(autouse=True)
def qapp():
    return QCoreApplication.instance() or QCoreApplication([])


def test_term_alignment_from_glossary_and_entities():
    model = SubtitleModel()
    model.load_data([
        {"index": 1, "start_time": "00:00:01,000", "end_time": "00:00:03,000", "original": "Sailor Angel và 妖魔王 đang đối đầu.", "translation": "", "status": "PENDING"},
        {"index": 2, "start_time": "00:00:04,000", "end_time": "00:00:06,000", "original": "Xin chào thế giới.", "translation": "", "status": "PENDING"}
    ])

    proj_ctrl = ProjectController(model)
    proj_ctrl.addManualGlossaryTerm("Sailor Angel", "Chiến Binh Thiên Sứ")
    proj_ctrl.addManualGlossaryTerm("妖魔王", "Ma Vương")

    tc = TranslationController(model)
    tc.bind_intelligence(
        glossary=proj_ctrl.glossary,
        entities=proj_ctrl.entity_dictionary,
        translation_memory=proj_ctrl.translation_memory,
        project_controller=proj_ctrl,
    )

    # 1. Load row 0: Should detect both Sailor Angel and 妖魔王
    tc.loadSubtitle(0)
    terms = tc.currentAppliedTerms
    assert len(terms) == 2
    sources = [t["source"] for t in terms]
    targets = [t["target"] for t in terms]
    assert "Sailor Angel" in sources
    assert "妖魔王" in sources
    assert "Chiến Binh Thiên Sứ" in targets
    assert "Ma Vương" in targets

    # 2. Load row 1: No matching terms
    tc.loadSubtitle(1)
    assert tc.currentAppliedTerms == []

    # 3. Add new term to glossary dynamically
    tc.loadSubtitle(1)
    proj_ctrl.addManualGlossaryTerm("thế giới", "World")
    terms_row1 = tc.currentAppliedTerms
    assert len(terms_row1) == 1
    assert terms_row1[0]["source"] == "thế giới"
    assert terms_row1[0]["target"] == "World"


def test_recent_files_settings_and_controller(tmp_path):
    settings_file = tmp_path / "test_settings.json"
    settings = AppSettings(file_path=str(settings_file))
    assert settings.recent_files == []

    f1 = tmp_path / "batch_1.srt"
    f1.write_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n\n", encoding="utf-8")
    f2 = tmp_path / "project.aisrt"
    f2.write_text("{}", encoding="utf-8")

    settings.add_recent_file(str(f1))
    assert len(settings.recent_files) == 1
    assert os.path.normpath(settings.recent_files[0]) == os.path.normpath(str(f1))

    # Add second file: should be at index 0
    settings.add_recent_file(str(f2))
    assert len(settings.recent_files) == 2
    assert os.path.normpath(settings.recent_files[0]) == os.path.normpath(str(f2))

    # Re-adding f1 should move it to the top without duplicates
    settings.add_recent_file(str(f1))
    assert len(settings.recent_files) == 2
    assert os.path.normpath(settings.recent_files[0]) == os.path.normpath(str(f1))

    # Max 5 limit
    for i in range(10):
        dummy = tmp_path / f"dummy_{i}.srt"
        dummy.write_text("", encoding="utf-8")
        settings.add_recent_file(str(dummy), max_items=5)
    assert len(settings.recent_files) == 5

    # Test ProjectController integration
    model = SubtitleModel()
    ctrl = ProjectController(model)
    ctrl._settings = settings

    recent = ctrl.recentFiles
    assert len(recent) <= 5
    for item in recent:
        assert "path" in item
        assert "name" in item
        assert "is_project" in item

    # Test openRecentFile
    ctrl.openRecentFile(str(f1))
    assert ctrl.originalSourcePath == str(f1)
from app.llm.worker import TranslationWorker


def test_worker_auto_terms_extraction_and_visible_shield():
    raw_output = (
        "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!\n\n"
        "[TỪ GỐC]\n"
        "- 妖魔王 -> Ma Vương\n"
        "* やっと ➔ cuối cùng\n"
        "- 'セーラーエンジェル' -> \"Chiến Binh Thiên Sứ\"\n"
    )

    # 1. Bóc tách từ vựng
    terms = TranslationWorker.extract_auto_terms(raw_output)
    assert len(terms) == 3
    assert terms[0] == {"source": "妖魔王", "target": "Ma Vương"}
    assert terms[1] == {"source": "やっと", "target": "cuối cùng"}
    assert terms[2] == {"source": "セーラーエンジェル", "target": "Chiến Binh Thiên Sứ"}

    # 2. Lá chắn hiển thị: Cắt sạch [TỪ GỐC] khỏi ô nhập liệu
    clean_display = TranslationWorker._visible_translation(raw_output)
    assert clean_display == "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!"

    # 3. Lá chắn token dở dang khi đang stream
    streaming_chunk_1 = "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!\n[TỪ"
    assert TranslationWorker._visible_translation(streaming_chunk_1) == "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!"

    streaming_chunk_2 = "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!\n[từ gốc"
    assert TranslationWorker._visible_translation(streaming_chunk_2) == "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương!"


def test_auto_terms_priority_and_pin_to_glossary():
    model = SubtitleModel()
    model.load_data([
        {
            "index": 1,
            "start_time": "00:00:01,000",
            "end_time": "00:00:03,000",
            "original": "妖魔王やっと見つけたわ",
            "translation": "Cuối cùng ta cũng tìm thấy ngươi rồi Ma Vương",
            "status": "TRANSLATED",
            "auto_terms": [
                {"source": "妖魔王", "target": "ác quỷ"},
                {"source": "やっと", "target": "cuối cùng"}
            ]
        }
    ])

    proj_ctrl = ProjectController(model)
    tc = TranslationController(model)
    tc.bind_intelligence(
        glossary=proj_ctrl.glossary,
        entities=proj_ctrl.entity_dictionary,
        translation_memory=proj_ctrl.translation_memory,
        project_controller=proj_ctrl,
    )

    tc.loadSubtitle(0)
    terms = tc.currentAppliedTerms
    assert len(terms) == 2
    # Ban đầu là auto_terms: is_glossary = False
    assert terms[0]["source"] == "妖魔王"
    assert terms[0]["target"] == "ác quỷ"
    assert terms[0]["is_glossary"] is False

    # Người dùng nhấn 📌 để ghim vào Glossary vĩnh viễn
    pinned = tc.pinTermToGlossary("妖魔王", "ác quỷ")
    assert pinned is True
    assert proj_ctrl.glossary.get("妖魔王") is not None
    assert proj_ctrl.glossary.get("妖魔王").preferred_translation == "ác quỷ"

    # Sau khi ghim, term chuyển sang is_glossary = True và không bị trùng lặp
    terms_after = tc.currentAppliedTerms
    assert len(terms_after) == 2
    hit_pinned = next(t for t in terms_after if t["source"] == "妖魔王")
    assert hit_pinned["is_glossary"] is True


def test_extract_terms_for_subtitle_on_demand():
    model = SubtitleModel()
    model.load_data([
        {
            "index": 1,
            "start_time": "00:00:01,000",
            "end_time": "00:00:03,000",
            "original": "妖魔王",
            "translation": "Ma Vương\n[TỪ GỐC]\n- 妖魔王 -> Ma Vương",
            "status": "ACCEPTED",
        }
    ])

    proj_ctrl = ProjectController(model)
    tc = TranslationController(model)
    tc.bind_intelligence(
        glossary=proj_ctrl.glossary,
        entities=proj_ctrl.entity_dictionary,
        translation_memory=proj_ctrl.translation_memory,
        project_controller=proj_ctrl,
    )

    # Chạy trích xuất cho câu đã có sẵn
    tc.extractTermsForSubtitle(0)
    tc.loadSubtitle(0)
    terms = tc.currentAppliedTerms
    assert len(terms) == 1
    assert terms[0]["source"] == "妖魔王"
    assert terms[0]["target"] == "Ma Vương"
