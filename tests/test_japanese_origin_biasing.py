"""
Unit tests for Japanese Origin Detection & Pronoun Biasing.
"""
import pytest
from app.core.context_analyzer import (
    ContextAnalyzer,
    detect_ja_translated_en,
    ARCHETYPE_ANIME_SCHOOL,
)
from app.core.prompt_builder import PromptBuilder


def test_detect_ja_translated_en_romaji_honorifics():
    text = "Please listen to me, senpai! Tanaka-sensei is waiting."
    res = detect_ja_translated_en(text)
    assert res["is_ja_origin"] is True
    assert any("senpai" in c for c in res["matched_clues"])
    assert any("sensei" in c for c in res["matched_clues"])


def test_detect_ja_translated_en_hyphenated_suffixes():
    text = "Hello Taro-kun, have you seen Hanako-chan today?"
    res = detect_ja_translated_en(text)
    assert res["is_ja_origin"] is True
    assert any("Taro-kun" in c or "Hanako-chan" in c for c in res["matched_clues"])


def test_detect_ja_translated_en_senior_address():
    # Câu đặc trưng trích từ file ghpm98.srt thực tế
    text = "What's wrong, senior, are you giving up? Because my favorite senior touched me."
    res = detect_ja_translated_en(text)
    assert res["is_ja_origin"] is True
    assert "anime_senior_address" in res["matched_clues"]


def test_native_english_not_detected_as_ja():
    text = "The senior software engineer submitted a pull request for the quarterly report."
    res = detect_ja_translated_en(text)
    assert res["is_ja_origin"] is False
    assert res["confidence"] == 0.0


def test_prompt_builder_injects_japanese_artifacts_rule():
    prompt = PromptBuilder.build(
        story_summary="Anime romance school",
        source_lang="English",
        target_lang="Vietnamese",
        current_sub="What's wrong, senior, are you giving up?",
        active_pronoun_pair="Em - Tiền bối",
        is_ja_origin=True,
    )
    assert "JAPANESE TRANSLATION ARTIFACTS" in prompt
    assert "'senior' or 'seniors' used as a title, address" in prompt
    assert "tiền bối" in prompt
    assert "ABSOLUTELY DO NOT translate 'senior' as 'người lớn tuổi'" in prompt


def test_senior_only_translated_as_tien_boi_when_marked_ja_origin():
    current_sub = "What's wrong, senior, are you giving up?"
    unmarked_prompt = PromptBuilder.build(
        current_sub=current_sub,
        source_lang="English",
        target_lang="Vietnamese",
        is_ja_origin=False,
    )
    assert "JAPANESE TRANSLATION ARTIFACTS" not in unmarked_prompt
    assert "ABSOLUTELY DO NOT translate 'senior' as 'người lớn tuổi'" not in unmarked_prompt

    marked_prompt = PromptBuilder.build(
        current_sub=current_sub,
        source_lang="English",
        target_lang="Vietnamese",
        is_ja_origin=True,
    )
    assert "JAPANESE TRANSLATION ARTIFACTS" in marked_prompt
    assert "tiền bối" in marked_prompt
    assert "ABSOLUTELY DO NOT translate 'senior' as 'người lớn tuổi'" in marked_prompt

