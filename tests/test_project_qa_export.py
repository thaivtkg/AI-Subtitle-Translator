import pytest
from PySide6.QtCore import QCoreApplication
from app.controllers.project_controller import ProjectController
from app.models.subtitle import SubtitleModel


@pytest.fixture
def qtbot():
    return QCoreApplication.instance() or QCoreApplication([])


def test_export_intercept_when_qa_errors_exist(qtbot, tmp_path):
    model = SubtitleModel()
    controller = ProjectController(subtitle_model=model)
    export_path = str(tmp_path / "output.srt")

    # Load 1 valid item and 1 item with QA ERROR (CPL > 42)
    model.load_data([
        {
            "index": 1,
            "start_time": "00:00:01,000",
            "end_time": "00:00:05,000",
            "original": "Source 1",
            "translation": "Bản dịch 1",
            "status": "ACCEPTED"
        },
        {
            "index": 2,
            "start_time": "00:00:06,000",
            "end_time": "00:00:10,000",
            "original": "Source 2",
            "translation": "Dòng này cố tình vượt quá bốn mươi hai ký tự để kích hoạt lỗi QA Error tràn màn hình",
            "status": "ACCEPTED"
        }
    ])

    warning_emitted = []
    controller.qaExportWarningRequired.connect(lambda path, count: warning_emitted.append((path, count)))

    # 1-argument call without force -> must intercept
    controller.exportSrt(export_path)

    assert len(warning_emitted) == 1
    assert warning_emitted[0][0] == export_path
    assert warning_emitted[0][1] == 1  # 1 error item

    # 2-argument call with force=True -> must export without extra warning
    controller.exportSrt(export_path, True)
    assert len(warning_emitted) == 1  # No extra warning emitted
