import json

import pytest
from PySide6.QtCore import QUrl

from app.batch.batch_item import BatchItem
from app.batch.batch_job import BatchJob
from app.batch.batch_state import BatchItemState, BatchJobState
from app.batch.checkpoint import CheckpointStore
from app.batch.fingerprint import compute_source_hash
from app.controllers.project_controller import ProjectController
from app.models.subtitle import SubtitleModel


def file_url(path):
    return QUrl.fromLocalFile(str(path)).toString()


def make_controller():
    model = SubtitleModel()
    controller = ProjectController(model)
    controller._set_project_state(True, True)
    return controller, model


def save(controller, path):
    controller.saveProject(file_url(path), "story", "English", "Vietnamese")


def test_tc_p3b1_14_aisrt_roundtrip_preserves_glossary(tmp_path):
    path = tmp_path / "project.aisrt"
    controller, model = make_controller()
    model.load_data([{"index": 1, "original": "King", "translation": "Vua", "status": "ACCEPTED"}])
    controller.glossary.add("  King  ", "  Vua  ", ["A", "B", "A"])

    save(controller, path)

    loaded, loaded_model = make_controller()
    loaded.loadProject(file_url(path))

    assert loaded.glossary.to_payload() == {
        "  King  ": {
            "preferred_translation": "  Vua  ",
            "forbidden_alternatives": ["A", "B"],
        }
    }
    assert loaded_model.get_all_data() == model.get_all_data()


def test_tc_p3b1_15_empty_save_writes_canonical_namespace(tmp_path):
    path = tmp_path / "empty.aisrt"
    controller, _ = make_controller()

    save(controller, path)

    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["intelligence"] == {"glossary": {}}


@pytest.mark.parametrize(
    "intelligence",
    [None, {}],
)
def test_tc_p3b1_16_legacy_missing_glossary_loads_empty_without_rewrite(
    tmp_path, intelligence
):
    path = tmp_path / "legacy.aisrt"
    payload = {
        "metadata": {"source_file": "source.srt"},
        "story_summary": "legacy",
        "subtitles": [{"index": 1, "original": "old", "translation": "", "status": "PENDING"}],
    }
    if intelligence is not None:
        payload["intelligence"] = intelligence
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    before = path.read_bytes()
    controller, _ = make_controller()
    controller.glossary.add("Old", "Cũ", [])

    controller.loadProject(file_url(path))

    assert controller.glossary.to_payload() == {}
    assert path.read_bytes() == before


def test_tc_p3b1_17_invalid_glossary_load_is_atomic(tmp_path):
    path = tmp_path / "invalid.aisrt"
    payload = {
        "metadata": {"source_file": "new.srt"},
        "story_summary": "new",
        "subtitles": [{"index": 2, "original": "new", "translation": "", "status": "PENDING"}],
        "intelligence": {
            "glossary": {
                "Good": {
                    "preferred_translation": "Tốt",
                    "forbidden_alternatives": [],
                },
                "Bad": {
                    "preferred_translation": " ",
                    "forbidden_alternatives": [],
                },
            }
        },
    }
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    controller, model = make_controller()
    model.load_data([{"index": 1, "original": "old", "translation": "Cũ", "status": "ACCEPTED"}])
    controller.glossary.add("Old", "Cũ", [])
    before_model = model.get_all_data().copy()
    before_glossary = controller.glossary.to_payload()

    controller.loadProject(file_url(path))

    assert model.get_all_data() == before_model
    assert controller.glossary.to_payload() == before_glossary


def test_tc_p3b1_18_checkpoint_has_no_glossary_data(tmp_path):
    job = BatchJob(
        job_id="job",
        project_id="project",
        state=BatchJobState.RUNNING,
        items={
            0: BatchItem(
                target_index=0,
                source_hash=compute_source_hash("King"),
                state=BatchItemState.PENDING,
            )
        },
    )
    path = tmp_path / "checkpoint.json"

    CheckpointStore.save(path, job)

    payload = json.loads(path.read_text(encoding="utf-8"))
    assert "intelligence" not in payload
    assert "glossary" not in json.dumps(payload, ensure_ascii=False)
