import os
import pytest
from PySide6.QtCore import QCoreApplication
from app.controllers.project_controller import ProjectController
from app.models.subtitle import SubtitleModel
from app.core.srt_exporter import SRTExporter


@pytest.fixture(autouse=True)
def qapp():
    return QCoreApplication.instance() or QCoreApplication([])


def test_batch_detection_on_import(tmp_path):
    model = SubtitleModel()
    ctrl = ProjectController(model)

    # 1. Normal file (non-batch)
    normal_file = tmp_path / "movie.srt"
    normal_file.write_text("1\n00:00:01,000 --> 00:00:03,000\nHello\n\n", encoding="utf-8")
    ctrl.importSrt(str(normal_file))

    assert ctrl.isBatchMode is False
    assert ctrl.batchStartNum == 0
    assert ctrl.batchEndNum == 0
    assert ctrl.batchLabel == ""
    assert ctrl.originalSourcePath == str(normal_file)

    # 2. Batch file matching pattern project_batch_1_to_5.srt
    batch_file = tmp_path / "project_batch_1_to_5.srt"
    batch_file.write_text(
        "1\n00:00:01,123 --> 00:00:03,456\nFirst line\n\n"
        "2\n00:00:04,000 --> 00:00:06,789\nSecond line\n\n",
        encoding="utf-8"
    )
    ctrl.importSrt(str(batch_file))

    assert ctrl.isBatchMode is True
    assert ctrl.batchStartNum == 1
    assert ctrl.batchEndNum == 5
    assert ctrl.batchLabel == "Đợt #1 ➔ #5"
    assert ctrl.originalSourcePath == str(batch_file)


def test_quick_sync_to_original(tmp_path):
    model = SubtitleModel()
    ctrl = ProjectController(model)

    batch_file = tmp_path / "scene_batch_1_to_2.srt"
    batch_file.write_text(
        "1\n00:00:01,100 --> 00:00:03,200\nMagic circle\n\n"
        "2\n00:00:04,500 --> 00:00:07,800\nShadow monarch\n\n",
        encoding="utf-8"
    )
    ctrl.importSrt(str(batch_file))
    assert ctrl.isBatchMode is True

    # Translate lines
    model.update_translation(0, "Vòng ma pháp", "ACCEPTED")
    model.update_translation(1, "Quân vương bóng tối", "ACCEPTED")

    # Quick sync
    ok = ctrl.quickSyncToOriginal()
    assert ok is True

    # Verify content written to original file
    content = batch_file.read_text(encoding="utf-8")
    assert "00:00:01,100 --> 00:00:03,200" in content
    assert "Vòng ma pháp" in content
    assert "00:00:04,500 --> 00:00:07,800" in content
    assert "Quân vương bóng tối" in content


def test_append_next_batch_and_preserve_intelligence(tmp_path):
    model = SubtitleModel()
    ctrl = ProjectController(model)

    # 1. Import Batch 1
    batch1_file = tmp_path / "ep1_batch_1_to_2.srt"
    batch1_file.write_text(
        "1\n00:00:01,000 --> 00:00:03,000\nSenpai arrives\n\n"
        "2\n00:00:04,000 --> 00:00:06,000\nHe greets teacher\n\n",
        encoding="utf-8"
    )
    ctrl.importSrt(str(batch1_file))
    assert model.rowCount() == 2
    assert ctrl.batchStartNum == 1
    assert ctrl.batchEndNum == 2

    # Add glossary in batch 1
    ctrl.addManualGlossaryTerm("Senpai", "Tiền bối")
    assert len(ctrl.glossaryTerms) == 1

    # 2. Append Batch 2 (lines 3 to 4)
    batch2_file = tmp_path / "ep1_batch_3_to_4.srt"
    batch2_file.write_text(
        "1\n00:00:07,000 --> 00:00:09,000\nSenpai smiles\n\n"
        "2\n00:00:10,000 --> 00:00:12,000\nTeacher waves\n\n",
        encoding="utf-8"
    )
    ok = ctrl.appendNextBatch(str(batch2_file))
    assert ok is True

    # Model now has 4 rows
    assert model.rowCount() == 4
    all_data = model.get_all_data()
    # Check that indices are sequential 1, 2, 3, 4
    assert [d["index"] for d in all_data] == [1, 2, 3, 4]
    assert all_data[2]["original"] == "Senpai smiles"
    assert all_data[3]["original"] == "Teacher waves"

    # Batch end num extended to 4
    assert ctrl.batchEndNum == 4
    assert ctrl.batchLabel == "Đợt #1 ➔ #4"

    # Glossary remains intact
    assert len(ctrl.glossaryTerms) == 1
    assert ctrl.glossaryTerms[0]["source_term"] == "Senpai"


def test_srt_exporter_millisecond_preservation(tmp_path):
    subs = [
        {"index": 1, "start_time": "00:01:23,456", "end_time": "00:01:25,789", "original": "Hi", "translation": "Chào", "status": "ACCEPTED"},
        {"index": 2, "start_time": 90000, "end_time": 92500, "original": "Bye", "translation": "Tạm biệt", "status": "ACCEPTED"},
    ]
    out_file = tmp_path / "test_ms.srt"
    success, _ = SRTExporter.export(subs, str(out_file))
    assert success is True

    content = out_file.read_text(encoding="utf-8")
    assert "00:01:23,456 --> 00:01:25,789" in content
    assert "00:01:30,000 --> 00:01:32,500" in content
