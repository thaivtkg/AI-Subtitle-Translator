import pytest
from app.core.context_engine import ContextEngine
from app.core.prompt_builder import PromptBuilder


def make_sub(i, orig, translation="", status="pending"):
    return {
        "index": i,
        "start_time": f"00:00:0{i},000",
        "end_time": f"00:00:0{i+1},000",
        "original": orig,
        "translation": translation,
        "status": status,
    }


def test_get_context_basic():
    # Build a list of 7 subtitles
    subs = [
        make_sub(1, "Alpha", "Alpha_TR", "accepted"),
        make_sub(2, "Bravo", "", "pending"),
        make_sub(3, "Charlie", "Charlie_TR", "accepted"),
        make_sub(4, "Delta", "", "pending"),
        make_sub(5, "Echo", "Echo_TR", "accepted"),
        make_sub(6, "Foxtrot", "", "pending"),
        make_sub(7, "Golf", "", "pending"),
    ]

    # current_index = 3 (0-based -> the 4th item 'Delta')
    prev_ctx, current, next_ctx = ContextEngine.get_context(subs, 3, prev_count=3, next_count=2)

    # Prev context should prefer translations when status == accepted
    # items at indices 0..2 -> Alpha (accepted->Alpha_TR), Bravo (pending->Bravo), Charlie (accepted->Charlie_TR)
    assert prev_ctx == ["Alpha_TR", "Bravo", "Charlie_TR"]

    # Current should be the original of index 3
    assert current == "Delta"

    # Next context should always be originals for indices 4 and 5
    assert next_ctx == ["Echo", "Foxtrot"]


def test_get_context_out_of_range():
    assert ContextEngine.get_context([], 0) == ([], "", [])
    subs = [make_sub(1, "A")]
    assert ContextEngine.get_context(subs, -1) == ([], "", [])
    assert ContextEngine.get_context(subs, 1) == ([], "", [])


def test_prompt_builder_includes_tags_and_task():
    story = "A short story summary."
    prev = ["prev1", "prev2"]
    current = "This is the current sentence."
    next_ctx = ["next1"]

    prompt = PromptBuilder.build(story, "English", "Vietnamese", prev, current, next_ctx)

    # Basic checks for tags
    assert "<story_summary>" in prompt
    assert "<context_previous>" in prompt
    assert "<current_subtitle_to_translate>" in prompt
    assert "<context_next>" in prompt

    # Ensure current sentence is present inside the current tag
    assert current in prompt

    # Ensure TASK instructions appended
    assert "TASK: Translate ONLY the text inside <current_subtitle_to_translate>." in prompt


def test_prompt_builder_omits_empty_story_and_contexts():
    prompt = PromptBuilder.build("", "EN", "VI", [], "Hello", [])
    assert "<story_summary>" not in prompt
    assert "<context_previous>" not in prompt
    assert "<context_next>" not in prompt
    assert "<current_subtitle_to_translate>\nHello\n</current_subtitle_to_translate>" in prompt
